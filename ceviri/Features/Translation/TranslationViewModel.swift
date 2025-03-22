import Foundation
import SwiftUI
import Combine
import os

enum TranslationState {
    case idle
    case detecting
    case translating
    case success
    case error(String)
}

class TranslationViewModel: ObservableObject {
    private let geminiService: GeminiService
    private let logger = Logger(subsystem: "com.app.ceviri", category: "TranslationViewModel")
    
    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var detectedLanguage: String = ""
    @Published var selectedSourceLanguage: Language = Language(code: "auto", name: "Otomatik")
    @Published var selectedTargetLanguage: Language = AppConfig.languages.first(where: { $0.code == "en" }) ?? AppConfig.languages[0]
    @Published var state: TranslationState = .idle
    @Published var availableLanguages = AppConfig.languages
    @Published var availableSourceLanguages = AppConfig.languages
    @Published var debugMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // API anahtarını kontrol et
        if AppConfig.geminiAPIKey.isEmpty || AppConfig.geminiAPIKey == "API_ANAHTARINIZI_BURAYA_YAZIN" {
            self.geminiService = GeminiService(apiKey: "")
            logger.error("⚠️ API anahtarı ayarlanmamış! AppConfig.swift dosyasında geminiAPIKey değerini güncellemelisiniz.")
            debugMessage = "⚠️ API anahtarı ayarlanmamış! AppConfig.swift dosyasında geminiAPIKey değerini güncellemelisiniz."
        } else {
            self.geminiService = GeminiService(apiKey: AppConfig.geminiAPIKey)
            logger.info("TranslationViewModel başlatıldı")
        }
        
        // Metin girişi yapıldığında dil tespiti için debounce ekle
        $inputText
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .filter { !$0.isEmpty && $0.count > 3 && self.selectedSourceLanguage.code == "auto" }
            .sink { [weak self] _ in
                Task {
                    await self?.detectLanguage()
                }
            }
            .store(in: &cancellables)
    }
    
    func detectLanguage() async {
        guard !inputText.isEmpty && selectedSourceLanguage.code == "auto" else { return }
        
        logger.info("Dil algılama başlatılıyor...")
        await MainActor.run {
            state = .detecting
        }
        
        do {
            let languageCode = try await geminiService.detectLanguage(text: inputText)
            
            await MainActor.run {
                self.detectedLanguage = languageCode
                self.state = .idle
                logger.info("Dil algılandı: \(languageCode)")
            }
        } catch let error as GeminiError {
            await handleError(error: error, context: "dil tespiti")
        } catch {
            await handleError(error: error, context: "dil tespiti")
        }
    }
    
    func translate() async {
        guard !inputText.isEmpty else { return }
        
        logger.info("Çeviri başlatılıyor...")
        await MainActor.run {
            state = .translating
            translatedText = ""
            debugMessage = "Çeviri yapılıyor..."
        }
        
        do {
            // Kaynak dili belirle
            let sourceLanguage = selectedSourceLanguage.code == "auto" ? 
                (detectedLanguage.isEmpty ? "" : availableLanguages.first(where: { $0.code == detectedLanguage })?.name ?? "") : 
                selectedSourceLanguage.name
            
            // Eğer kaynak dil ve hedef dil aynıysa, direkt olarak giriş metnini döndür
            let sourceCode = selectedSourceLanguage.code == "auto" ? detectedLanguage : selectedSourceLanguage.code
            if !sourceCode.isEmpty && sourceCode == selectedTargetLanguage.code {
                await MainActor.run {
                    self.translatedText = self.inputText
                    self.state = .success
                    self.debugMessage = "Kaynak ve hedef dil aynı olduğu için doğrudan aktarıldı."
                    logger.info("Kaynak ve hedef dil aynı: \(sourceCode)")
                }
                return
            }
            
            let result = try await geminiService.translateText(
                text: inputText,
                sourceLanguage: sourceLanguage,
                targetLanguage: selectedTargetLanguage.name
            )
            
            await MainActor.run {
                self.translatedText = result
                self.state = .success
                self.debugMessage = ""
                logger.info("Çeviri başarılı")
            }
        } catch let error as GeminiError {
            await handleError(error: error, context: "çeviri")
        } catch {
            await handleError(error: error, context: "çeviri")
        }
    }
    
    private func handleError(error: Error, context: String) async {
        await MainActor.run {
            let errorMessage: String
            
            if let geminiError = error as? GeminiError {
                switch geminiError {
                case .emptyAPIKey:
                    errorMessage = "API anahtarı boş! AppConfig.swift dosyasında geminiAPIKey değerini güncellemelisiniz."
                case .apiError(let message):
                    errorMessage = "API hatası: \(message)"
                case .invalidURL:
                    errorMessage = "Geçersiz URL"
                case .invalidResponse:
                    errorMessage = "Geçersiz API yanıtı"
                case .networkError(let err):
                    errorMessage = "Ağ hatası: \(err.localizedDescription)"
                case .decodingError(let err):
                    errorMessage = "Yanıt çözümleme hatası: \(err.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            logger.error("\(context) hatası: \(errorMessage)")
            self.state = .error("\(context.prefix(1).uppercased() + context.dropFirst()) sırasında hata oluştu: \(errorMessage)")
            self.debugMessage = "‼️ Hata: \(errorMessage)"
        }
    }
    
    func canTranslate() -> Bool {
        if case .translating = state {
            return false
        }
        return !inputText.isEmpty
    }
    
    func getDetectedLanguageName() -> String {
        if detectedLanguage.isEmpty {
            return "Algılanıyor..."
        }
        
        return availableLanguages.first(where: { $0.code == detectedLanguage })?.name ?? detectedLanguage
    }
    
    func clearText() {
        inputText = ""
        translatedText = ""
        state = .idle
        detectedLanguage = ""
        debugMessage = ""
    }
    
    func swapLanguages() async {
        // Otomatik dil algılama seçiliyse ya da çeviri boşsa işlem yapılmaz
        guard selectedSourceLanguage.code != "auto" && !translatedText.isEmpty else { return }
        
        let tempText = translatedText
        let tempSourceLang = selectedSourceLanguage
        
        // Kaynağı hedefle, hedefi kaynakla değiştir
        selectedSourceLanguage = selectedTargetLanguage
        selectedTargetLanguage = tempSourceLang
        
        translatedText = ""
        inputText = tempText
        detectedLanguage = "" // Algılanan dili sıfırla
        
        // Yeni çeviriyi başlat
        await translate()
    }
} 