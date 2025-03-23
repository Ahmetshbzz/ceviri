import Foundation

// Çeviri geçmişi için model
struct TranslationHistory: Identifiable, Codable {
    var id: UUID
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var timestamp: Date
    var isFavorite: Bool
    
    init(sourceText: String, translatedText: String, sourceLanguage: String, targetLanguage: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = Date()
        self.isFavorite = isFavorite
    }
}

// Çeviri geçmişi servisi için istek türleri
enum HistoryRequest {
    case all
    case favorites
    case search(String)
    case timeRange(Date, Date)
} 