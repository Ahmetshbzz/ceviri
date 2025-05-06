import Foundation
import SwiftUI
import Combine
import os

enum TranslationState {
    case idle
    case detecting
    case translating
    case converting
    case speaking
    case success
    case error(String)
}

class TranslationViewModel: ObservableObject, ElevenLabsPlayerDelegate, TranslationHistoryDelegate {
    private let geminiService: GeminiService
    private let elevenLabsService: ElevenLabsService
    private let logger = Logger(subsystem: "com.app.ceviri", category: "TranslationViewModel")

    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var detectedLanguage: String = ""
    @Published var selectedSourceLanguage: Language = AppConfig.languages.first(where: { $0.code == "tr" }) ?? Language(code: "auto", name: "Otomatik")
    @Published var selectedTargetLanguage: Language = AppConfig.languages.first(where: { $0.code == "en" }) ?? AppConfig.languages[0]
    @Published var state: TranslationState = .idle
    @Published var availableLanguages = AppConfig.languages
    @Published var availableSourceLanguages = AppConfig.languages
    @Published var debugMessage: String = ""
    @Published var availableVoices: [Voice] = []
    @Published var selectedVoice: Voice?
    @Published var isVoiceLoading: Bool = false
    @Published var audioCacheStats: (count: Int, totalSizeInBytes: Int) = (0, 0)
    @Published var showCacheInfo: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var audioData: Data?

    // Geçmiş servisi, artık public erişime açık
    let historyService: TranslationHistoryService

    init() {
        // Önce tüm servisleri başlat
        if AppConfig.geminiAPIKey.isEmpty || AppConfig.geminiAPIKey == "API_ANAHTARINIZI_BURAYA_YAZIN" {
            self.geminiService = GeminiService(apiKey: "")
            logger.error("⚠️ API anahtarı ayarlanmamış! AppConfig.swift dosyasında geminiAPIKey değerini güncellemelisiniz.")
            debugMessage = "⚠️ API anahtarı ayarlanmamış! AppConfig.swift dosyasında geminiAPIKey değerini güncellemelisiniz."
        } else {
            self.geminiService = GeminiService(apiKey: AppConfig.geminiAPIKey)
            logger.info("TranslationViewModel başlatıldı")
        }

        // ElevenLabs servisini oluştur
        self.elevenLabsService = ElevenLabsService()

        // Geçmiş servisini oluştur
        historyService = TranslationHistoryService()

        // Delegate'leri ayarla
        historyService.delegate = self
        self.elevenLabsService.delegate = self

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

        // Kullanılabilir sesleri yükle
        loadVoices()

        // Önbellek istatistiklerini güncelle
        updateCacheStats()

        // Düzenli olarak önbellek istatistiklerini güncelle (her 5 dakikada bir)
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateCacheStats()
        }
    }

    // Önbellek istatistiklerini güncelle
    private func updateCacheStats() {
        audioCacheStats = elevenLabsService.getCacheStats()
    }

    // ElevenLabsPlayerDelegate metodu
    func audioPlaybackDidFinish() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .success
            self?.debugMessage = "Ses oynatma tamamlandı"

            // 2 saniye sonra debug mesajını temizle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if self?.debugMessage == "Ses oynatma tamamlandı" {
                    self?.debugMessage = ""
                }
            }
        }
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

    // Klavyeyi kapat
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func translate() async {
        guard !inputText.isEmpty else { return }

        // Klavyeyi kapat
        await MainActor.run {
            dismissKeyboard()
        }

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

            // Çeviriyi yap
            let translatedText = try await geminiService.translateText(
                text: inputText,
                sourceLanguage: sourceLanguage,
                targetLanguage: selectedTargetLanguage.name
            )

            await MainActor.run {
                self.translatedText = translatedText

                // Çeviriyi geçmişe kaydet
                historyService.addToHistory(
                    sourceText: inputText,
                    translatedText: translatedText,
                    sourceLanguage: selectedSourceLanguage.name,
                    targetLanguage: selectedTargetLanguage.name
                )

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

    // ElevenLabs ile çevrilmiş metni sese dönüştür
    func convertTextToSpeech() {
        guard !translatedText.isEmpty else { return }

        // Klavyeyi kapat
        dismissKeyboard()

        // Eğer zaten konuşuyorsa, durdur
        if case .speaking = state {
            stopAudio()
            return
        }

        DispatchQueue.main.async {
            self.state = .converting
            self.debugMessage = "Ses oluşturuluyor..."
        }

        elevenLabsService.convertTextToSpeech(text: translatedText, voiceID: selectedVoice?.voice_id) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.audioData = data
                    self.updateCacheStats() // Önbellek istatistiklerini güncelle
                    self.logger.info("Ses başarıyla oluşturuldu")
                    self.playAudio()

                case .failure(let error):
                    self.handleTextToSpeechError(error)
                }
            }
        }
    }

    private func playAudio() {
        guard let audioData = audioData else {
            debugMessage = "‼️ Çalınacak ses verisi yok"
            state = .error("Çalınacak ses verisi yok")
            return
        }

        do {
            state = .speaking
            debugMessage = "Ses oynatılıyor..."
            try elevenLabsService.playAudio(data: audioData)
            logger.info("Ses oynatılıyor")
        } catch {
            handleTextToSpeechError(error)
        }
    }

    func stopAudio() {
        elevenLabsService.stopAudio()
        state = .success
        debugMessage = ""
    }

    func loadVoices() {
        isVoiceLoading = true

        elevenLabsService.listVoices { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isVoiceLoading = false

                switch result {
                case .success(let voices):
                    self.availableVoices = voices
                    // Varsayılan bir ses seç (Rachel)
                    self.selectedVoice = voices.first(where: { $0.voice_id == "21m00Tcm4TlvDq8ikWAM" })

                case .failure(let error):
                    self.logger.error("Ses listesi alınamadı: \(error.localizedDescription)")
                    self.debugMessage = "Ses listesi alınamadı: \(error.localizedDescription)"
                }
            }
        }
    }

    // Önbelleği temizle
    func clearAudioCache() {
        elevenLabsService.clearCache()
        updateCacheStats()
        debugMessage = "Ses önbelleği temizlendi"

        // 2 saniye sonra debug mesajını temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.debugMessage == "Ses önbelleği temizlendi" {
                self?.debugMessage = ""
            }
        }
    }

    // İnsan okunabilir formatında önbellek boyutunu döndür
    func getCacheSize() -> String {
        let bytes = audioCacheStats.totalSizeInBytes

        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.1f KB", kb)
        } else {
            let mb = Double(bytes) / (1024.0 * 1024.0)
            return String(format: "%.1f MB", mb)
        }
    }

    private func handleTextToSpeechError(_ error: Error) {
        logger.error("Ses oluşturma hatası: \(error.localizedDescription)")
        state = .error("Ses oluşturma hatası: \(error.localizedDescription)")
        debugMessage = "‼️ Ses oluşturma hatası: \(error.localizedDescription)"
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

        // Klavyeyi kapat
        await MainActor.run {
            dismissKeyboard()
        }

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

    // Geçmiş öğesi seçildiğinde çağrılır
    func didSelectHistoryItem(_ item: TranslationHistory) {
        // Geçmiş öğesindeki metinleri ve dilleri ayarla
        inputText = item.sourceText
        translatedText = item.translatedText

        // Kaynak ve hedef dilleri bul
        if let sourceLang = availableLanguages.first(where: { $0.name == item.sourceLanguage }) {
            selectedSourceLanguage = sourceLang
        }

        if let targetLang = availableLanguages.first(where: { $0.name == item.targetLanguage }) {
            selectedTargetLanguage = targetLang
        }

        // Durumu güncelle
        state = .success
    }

    func getSourceLanguageText() -> String {
        if detectedLanguage.isEmpty && selectedSourceLanguage.code == "auto" {
            return "Otomatik"
        } else if selectedSourceLanguage.code != "auto" {
            return selectedSourceLanguage.name
        } else {
            return getDetectedLanguageName()
        }
    }
}
