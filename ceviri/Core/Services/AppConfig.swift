import Foundation

struct AppConfig {
    // Sabit API anahtarları (varsayılan değerler)
    private static let defaultGeminiAPIKey = ""
    private static let defaultElevenLabsAPIKey = ""
    private static let defaultOpenAIAPIKey = ""

    // UserDefaults'tan değerleri al, eğer yoksa varsayılan değerleri kullan
    static var geminiAPIKey: String {
        UserDefaults.standard.string(forKey: "geminiAPIKey") ?? defaultGeminiAPIKey
    }

    static var elevenLabsAPIKey: String {
        UserDefaults.standard.string(forKey: "elevenLabsAPIKey") ?? defaultElevenLabsAPIKey
    }

    static var openAIAPIKey: String {
        UserDefaults.standard.string(forKey: "openAIAPIKey") ?? defaultOpenAIAPIKey
    }

    // Kullanılacak çeviri servisi (gemini veya openai)
    static var translationService: String {
        UserDefaults.standard.string(forKey: "translationService") ?? "gemini"
    }

    static var languages: [Language] = [
        Language(code: "en", name: "İngilizce"),
        Language(code: "tr", name: "Türkçe"),
        Language(code: "pl", name: "Lehçe"),
        Language(code: "fr", name: "Fransızca"),
        Language(code: "de", name: "Almanca"),
        Language(code: "it", name: "İtalyanca"),
        Language(code: "ru", name: "Rusça"),
        Language(code: "zh", name: "Çince"),
        Language(code: "ja", name: "Japonca"),
        Language(code: "ar", name: "Arapça"),
        Language(code: "pt", name: "Portekizce"),
        Language(code: "ko", name: "Korece"),
        Language(code: "es", name: "İspanyolca")
    ]
}
