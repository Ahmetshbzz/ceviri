import SwiftUI

struct TranslationHistoryView: View {
    @ObservedObject var historyService: TranslationHistoryService
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
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
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
                    .onChange(of: showFavoritesOnly) { _, newValue in
                        historyService.showOnlyFavorites(newValue)
                    }

                    Spacer()

                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
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
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        historyService.removeFromHistory(item: item)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
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
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                HistoryDetailView(
                    item: item,
                    historyService: historyService,
                    dismiss: dismiss
                )
            }
            .alert("Tüm Geçmişi Temizle", isPresented: $showClearAlert) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.impactOccurred()
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

// ElevenLabs servisinin dinleyici sınıfı
class AudioPlayerDelegate: NSObject, ElevenLabsPlayerDelegate {
    var onPlaybackFinish: () -> Void = {}

    func audioPlaybackDidFinish() {
        onPlaybackFinish()
    }
}

// Geçmiş detay görünümü
struct HistoryDetailView: View {
    let item: TranslationHistory
    let historyService: TranslationHistoryService
    let dismiss: DismissAction
    @Environment(\.dismiss) private var dismissSheet

    // Ses servisi ve oynatma durumu
    private let elevenLabsService = ElevenLabsService()
    private let audioDelegate = AudioPlayerDelegate()
    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var isAudioCached = false
    @State private var audioData: Data?
    @State private var errorMessage: String?

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

                // Hata mesajı (varsa)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                // İşlem butonları
                HStack(spacing: 20) {
                    // Ses oynatma butonu
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

                        if isPlaying {
                            stopAudio()
                        } else {
                            playAudio()
                        }
                    } label: {
                        Label(
                            isPlaying ? "Durdur" : (isAudioCached ? "Dinle" : "Dinle"),
                            systemImage: isPlaying ? "stop.fill" : "speaker.wave.2.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.purple)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.5 : 1)

                    // Favorilere ekle/çıkar
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
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
                }
                .padding(.horizontal)

                HStack(spacing: 20) {
                    // Kopyala
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        UIPasteboard.general.string = item.translatedText
                        let notificationGenerator = UINotificationFeedbackGenerator()
                        notificationGenerator.notificationOccurred(.success)
                    } label: {
                        Label("Kopyala", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.blue)
                    }

                    // Paylaş butonu
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

                        let activityVC = UIActivityViewController(
                            activityItems: [item.translatedText],
                            applicationActivities: nil
                        )

                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(activityVC, animated: true)
                        }
                    } label: {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
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
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.impactOccurred()

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
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

                        // Ses çalıyorsa durdur
                        if isPlaying {
                            stopAudio()
                        }
                        dismissSheet()
                    }
                }
            }
            .onAppear {
                // Delegate'e oynatma bittiğinde çağrılacak fonksiyonu belirle
                audioDelegate.onPlaybackFinish = {
                    DispatchQueue.main.async {
                        self.isPlaying = false
                    }
                }

                // ElevenLabs delegatesini ayarla
                elevenLabsService.delegate = audioDelegate

                // Önbellekte bu metin için ses var mı kontrol et
                checkIfAudioCached()
            }
        }
    }

    // Sesi oynat
    private func playAudio() {
        if let data = audioData {
            // Önbellekte ses mevcutsa direkt oynat
            playAudioData(data)
        } else {
            // Önbellekte yoksa API'den al
            isLoading = true
            errorMessage = nil

            elevenLabsService.convertTextToSpeech(text: item.translatedText) { result in
                DispatchQueue.main.async {
                    self.isLoading = false

                    switch result {
                    case .success(let data):
                        self.audioData = data
                        self.isAudioCached = true
                        self.playAudioData(data)

                    case .failure(let error):
                        self.errorMessage = "Ses oluşturulamadı: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // Ses verisini çal
    private func playAudioData(_ data: Data) {
        do {
            try elevenLabsService.playAudio(data: data)
            isPlaying = true
        } catch {
            errorMessage = "Ses oynatılamadı: \(error.localizedDescription)"
        }
    }

    // Sesi durdur
    private func stopAudio() {
        elevenLabsService.stopAudio()
        isPlaying = false
    }

    // Önbellekte ses var mı kontrol et
    private func checkIfAudioCached() {
        isLoading = true
        elevenLabsService.convertTextToSpeech(text: item.translatedText) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let data):
                    self.audioData = data
                    self.isAudioCached = true

                case .failure:
                    self.isAudioCached = false
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
