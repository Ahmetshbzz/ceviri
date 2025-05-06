import Foundation

struct AppConfig {
    // Sabit API anahtarları (varsayılan değerler)
    private static let defaultGeminiAPIKey = "" // API anahtarlarını güvenlik için kaldırıldı
    private static let defaultElevenLabsAPIKey = "" // API anahtarlarını güvenlik için kaldırıldı
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

    // Çeviri servisi tercihi
    static var translationService: String {
        UserDefaults.standard.string(forKey: "translationService") ?? "gemini"
    }

    // Dil listesi
    static let languages: [Language] = [
        Language(code: "auto", name: "Otomatik"),
        Language(code: "tr", name: "Türkçe"),
        Language(code: "en", name: "İngilizce"),
        Language(code: "pl", name: "Lehçe"),
        Language(code: "fr", name: "Fransızca"),
        Language(code: "es", name: "İspanyolca"),
        Language(code: "it", name: "İtalyanca"),
        Language(code: "pt", name: "Portekizce"),
        Language(code: "ru", name: "Rusça"),
        Language(code: "ar", name: "Arapça"),
        Language(code: "zh", name: "Çince"),
        Language(code: "ja", name: "Japonca"),
        Language(code: "ko", name: "Korece"),
        Language(code: "nl", name: "Felemenkçe"),
        Language(code: "de", name: "Almanca"),
        Language(code: "sv", name: "İsveççe"),
        Language(code: "da", name: "Danca"),
        Language(code: "fi", name: "Fince"),
        Language(code: "no", name: "Norveççe"),
        Language(code: "el", name: "Yunanca"),
        Language(code: "hu", name: "Macarca"),
        Language(code: "cs", name: "Çekçe")
    ]
}
