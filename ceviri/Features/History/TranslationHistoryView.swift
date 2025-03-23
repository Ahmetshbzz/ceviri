import SwiftUI

struct TranslationHistoryView: View {
    @StateObject private var historyService = TranslationHistoryService()
    @State private var showFavoritesOnly = false
    @State private var selectedItem: TranslationHistory?
    @State private var showDeleteAlert = false
    @State private var showClearAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama çubuğu
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Geçmişte ara", text: $historyService.searchText)
                        .autocorrectionDisabled()
                    
                    if !historyService.searchText.isEmpty {
                        Button(action: {
                            historyService.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Ayarlar
                HStack {
                    Toggle(isOn: $showFavoritesOnly) {
                        Label("Sadece Favoriler", systemImage: "star.fill")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: showFavoritesOnly) { newValue in
                        historyService.showOnlyFavorites(newValue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showClearAlert = true
                    }) {
                        Label("Temizle", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(historyService.filteredItems.isEmpty)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 5)
                
                // Geçmiş listesi
                if historyService.filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Geçmiş Yok")
                            .font(.headline)
                        
                        Text("Çeviriler burada görünecek")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(historyService.filteredItems) { item in
                            HistoryItemView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        selectedItem = item
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        historyService.toggleFavorite(for: item)
                                    } label: {
                                        Label(
                                            item.isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                                            systemImage: item.isFavorite ? "star.slash" : "star.fill"
                                        )
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Çeviri Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                HistoryDetailView(item: item, historyService: historyService, dismiss: dismiss)
            }
            .alert("Geçmiş Kaydını Sil", isPresented: $showDeleteAlert, presenting: selectedItem) { item in
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    historyService.removeFromHistory(item: item)
                }
            } message: { item in
                Text("Bu çeviri geçmişten silinecek. Bu işlem geri alınamaz.")
            }
            .alert("Tüm Geçmişi Temizle", isPresented: $showClearAlert) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    historyService.clearHistory()
                }
            } message: {
                Text("Tüm çeviri geçmişiniz silinecek. Bu işlem geri alınamaz.")
            }
        }
    }
}

// Geçmiş öğesi görünümü
struct HistoryItemView: View {
    let item: TranslationHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Dil çifti
                Text("\(item.sourceLanguage) → \(item.targetLanguage)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                // Tarih
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Favori ikonu
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            // Kaynak metin
            Text(item.sourceText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // Çevrilmiş metin
            Text(item.translatedText)
                .font(.headline)
                .lineLimit(2)
        }
        .padding(.vertical, 6)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.timestamp)
    }
}

// Geçmiş detay görünümü
struct HistoryDetailView: View {
    let item: TranslationHistory
    let historyService: TranslationHistoryService
    let dismiss: DismissAction
    @Environment(\.dismiss) private var dismissSheet
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Kaynak ve hedef dil bilgisi
                HStack {
                    Text("\(item.sourceLanguage) → \(item.targetLanguage)")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Tarih
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Kaynak metin
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.sourceLanguage)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(item.sourceText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Çevrilmiş metin
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.targetLanguage)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(item.translatedText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // İşlem butonları
                HStack(spacing: 20) {
                    // Favorilere ekle/çıkar
                    Button {
                        historyService.toggleFavorite(for: item)
                    } label: {
                        Label(
                            item.isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                            systemImage: item.isFavorite ? "star.slash" : "star.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(item.isFavorite ? .gray : .yellow)
                    }
                    
                    // Kopyala
                    Button {
                        UIPasteboard.general.string = item.translatedText
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } label: {
                        Label("Kopyala", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Çeviride kullan butonu
                Button {
                    // Geçmiş öğesini çeviride kullanmak için delegate'i bilgilendir
                    historyService.selectHistoryItem(item)
                    
                    // Önce mevcut sheet'i kapat, ardından geçmiş ekranını kapat
                    dismissSheet()
                    dismiss()
                } label: {
                    Label("Çeviride Kullan", systemImage: "arrow.right.doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Çeviri Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismissSheet()
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.timestamp)
    }
} 