import Foundation
import Combine

protocol TranslationHistoryDelegate: AnyObject {
    func didSelectHistoryItem(_ item: TranslationHistory)
}

class TranslationHistoryService: ObservableObject {
    // Geçmiş verileri
    @Published private(set) var historyItems: [TranslationHistory] = []
    @Published private(set) var filteredItems: [TranslationHistory] = []
    @Published var searchText: String = ""
    
    // Delegasyon
    weak var delegate: TranslationHistoryDelegate?
    
    // UserDefaults anahtarı
    private let historyKey = "translation_history"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHistory()
        setupSearchSubscription()
    }
    
    // Arama metin değişikliklerini dinle
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterHistory(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    // Bir geçmiş öğesini seç
    func selectHistoryItem(_ item: TranslationHistory) {
        delegate?.didSelectHistoryItem(item)
    }
    
    // Çeviriyi geçmişe ekle
    func addToHistory(sourceText: String, translatedText: String, sourceLanguage: String, targetLanguage: String) {
        // Boş çevirileri ekleme
        guard !sourceText.isEmpty && !translatedText.isEmpty else { return }
        
        // Aynı çeviriyi tekrar ekleme (aynı kaynak ve hedef metinle)
        if historyItems.contains(where: { 
            $0.sourceText == sourceText && 
            $0.translatedText == translatedText && 
            $0.sourceLanguage == sourceLanguage && 
            $0.targetLanguage == targetLanguage 
        }) {
            return
        }
        
        let historyItem = TranslationHistory(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        historyItems.insert(historyItem, at: 0) // En yeni çeviriyi başa ekle
        saveHistory()
        filterHistory(searchText: searchText) // Filtrelenmiş listeyi güncelle
    }
    
    // Geçmiş öğesini favorilere ekle/çıkar
    func toggleFavorite(for item: TranslationHistory) {
        if let index = historyItems.firstIndex(where: { $0.id == item.id }) {
            historyItems[index].isFavorite.toggle()
            saveHistory()
            filterHistory(searchText: searchText)
        }
    }
    
    // Geçmiş öğesini sil
    func removeFromHistory(item: TranslationHistory) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
        filterHistory(searchText: searchText)
    }
    
    // Tüm geçmişi temizle
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
        filterHistory(searchText: searchText)
    }
    
    // Metne göre geçmişi filtrele
    private func filterHistory(searchText: String) {
        if searchText.isEmpty {
            filteredItems = historyItems
        } else {
            filteredItems = historyItems.filter { item in
                item.sourceText.localizedCaseInsensitiveContains(searchText) ||
                item.translatedText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Sadece favorileri göster
    func showOnlyFavorites(_ onlyFavorites: Bool) {
        if onlyFavorites {
            filteredItems = historyItems.filter { $0.isFavorite }
        } else {
            filterHistory(searchText: searchText)
        }
    }
    
    // Geçmişi UserDefaults'a kaydet
    private func saveHistory() {
        // Fazla büyümeyi engellemek için max 100 öğe tut
        if historyItems.count > 100 {
            historyItems = Array(historyItems.prefix(100))
        }
        
        do {
            let data = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Geçmiş kaydedilemedi: \(error.localizedDescription)")
        }
    }
    
    // Geçmişi UserDefaults'tan yükle
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            historyItems = []
            filteredItems = []
            return
        }
        
        do {
            let decodedItems = try JSONDecoder().decode([TranslationHistory].self, from: data)
            historyItems = decodedItems
            filteredItems = decodedItems
        } catch {
            print("Geçmiş yüklenemedi: \(error.localizedDescription)")
            historyItems = []
            filteredItems = []
        }
    }
} 