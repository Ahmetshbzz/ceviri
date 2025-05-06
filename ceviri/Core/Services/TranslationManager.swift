import Foundation
import os

enum TranslationServiceType: String {
    case gemini = "gemini"
    case openai = "openai"
}

enum ModelStyle: String {
    case formal = "formal"     // Standart/resmi
    case informal = "informal" // Günlük/samimi

    var displayName: String {
        switch self {
        case .formal:
            return "Standart Dil"
        case .informal:
            return "Günlük Dil"
        }
    }
}

// Çeviri yöneticisi, kullanıcı tercihine göre Gemini veya OpenAI servislerini kullanır
class TranslationManager {
    private var geminiService: GeminiService
    private var openAIService: OpenAIService
    private let logger = Logger(subsystem: "com.app.ceviri", category: "TranslationManager")

    // Seçilen model stili
    private var modelStyle: ModelStyle = {
        let savedStyle = UserDefaults.standard.string(forKey: "modelStyle") ?? ModelStyle.formal.rawValue
        return ModelStyle(rawValue: savedStyle) ?? .formal
    }()

    // Singleton pattern ile tek bir örnek oluştur
    static let shared = TranslationManager()

    private init() {
        geminiService = GeminiService(apiKey: AppConfig.geminiAPIKey)
        openAIService = OpenAIService(apiKey: AppConfig.openAIAPIKey)
        logger.info("TranslationManager başlatıldı")
    }

    // Mevcut model stilini al
    func getModelStyle() -> ModelStyle {
        return modelStyle
    }

    // Model stilini ayarla ve kaydet
    func setModelStyle(_ style: ModelStyle) {
        modelStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "modelStyle")
        logger.info("Model stili güncellendi: \(style.rawValue)")
    }

    // Kullanıcı ayarına göre uygun servisi kullanarak çeviri yap
    func translateText(text: String, sourceLanguage: String = "", targetLanguage: String) async throws -> String {
        // Kullanıcının tercih ettiği servisi kontrol et
        let serviceType = AppConfig.translationService

        // Eğer model stili informal (günlük) ise Gemini kullan
        // Eğer model stili formal (standart) ise OpenAI kullan
        // Ancak kullanıcı özel olarak bir servis seçtiyse, onu tercih et
        let effectiveServiceType: String

        if UserDefaults.standard.bool(forKey: "overrideModelStyle") {
            // Kullanıcı ayarlardan manuel olarak servis seçti
            effectiveServiceType = serviceType
        } else {
            // Model stiline göre otomatik servis seçimi
            effectiveServiceType = modelStyle == .informal ? "gemini" : "openai"
        }

        logger.info("Çeviri isteği: \(effectiveServiceType) servisi kullanılıyor")

        // Seçilen servise göre çeviri işlemini gerçekleştir
        switch effectiveServiceType {
        case "openai":
            return try await openAIService.translateText(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        case "gemini", _:
            // Varsayılan olarak Gemini kullan
            return try await geminiService.translateText(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        }
    }

    // Dil tespiti
    func detectLanguage(text: String) async throws -> String {
        // Kullanıcının tercih ettiği servisi kontrol et
        let serviceType = AppConfig.translationService

        // Eğer model stili informal (günlük) ise Gemini kullan
        // Eğer model stili formal (standart) ise OpenAI kullan
        // Ancak kullanıcı özel olarak bir servis seçtiyse, onu tercih et
        let effectiveServiceType: String

        if UserDefaults.standard.bool(forKey: "overrideModelStyle") {
            // Kullanıcı ayarlardan manuel olarak servis seçti
            effectiveServiceType = serviceType
        } else {
            // Model stiline göre otomatik servis seçimi
            effectiveServiceType = modelStyle == .informal ? "gemini" : "openai"
        }

        logger.info("Dil algılama isteği: \(effectiveServiceType) servisi kullanılıyor")

        // Seçilen servise göre dil tespiti işlemini gerçekleştir
        switch effectiveServiceType {
        case "openai":
            return try await openAIService.detectLanguage(text: text)
        case "gemini", _:
            // Varsayılan olarak Gemini kullan
            return try await geminiService.detectLanguage(text: text)
        }
    }

    // API anahtarlarını güncelle (ayarlar değiştiğinde çağrılmalı)
    func refreshAPIKeys() {
        geminiService = GeminiService(apiKey: AppConfig.geminiAPIKey)
        openAIService = OpenAIService(apiKey: AppConfig.openAIAPIKey)
        logger.info("API anahtarları güncellendi")
    }
}
