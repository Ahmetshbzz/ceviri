import Foundation
import os

// Çeviri yöneticisi, kullanıcı tercihine göre Gemini veya OpenAI servislerini kullanır
class TranslationManager {
    private var geminiService: GeminiService
    private var openAIService: OpenAIService
    private let logger = Logger(subsystem: "com.app.ceviri", category: "TranslationManager")

    // Singleton pattern ile tek bir örnek oluştur
    static let shared = TranslationManager()

    private init() {
        geminiService = GeminiService(apiKey: AppConfig.geminiAPIKey)
        openAIService = OpenAIService(apiKey: AppConfig.openAIAPIKey)
        logger.info("TranslationManager başlatıldı")
    }

    // Kullanıcı ayarına göre uygun servisi kullanarak çeviri yap
    func translateText(text: String, sourceLanguage: String = "", targetLanguage: String) async throws -> String {
        // Kullanıcının tercih ettiği servisi kontrol et
        let serviceType = AppConfig.translationService

        logger.info("Çeviri isteği: \(serviceType) servisi kullanılıyor")

        // Seçilen servise göre çeviri işlemini gerçekleştir
        switch serviceType {
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

        logger.info("Dil algılama isteği: \(serviceType) servisi kullanılıyor")

        // Seçilen servise göre dil tespiti işlemini gerçekleştir
        switch serviceType {
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
