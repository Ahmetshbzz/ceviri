import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showSourceLanguageOptions = false
    @State private var showTargetLanguageOptions = false
    @State private var showHistoryView = false
    @State private var showSettingsView = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : Color(UIColor.systemGroupedBackground)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan rengi
                backgroundColor.ignoresSafeArea()
                
                // Ana içerik
                ScrollView {
                    VStack(spacing: 16) {
                    // Üst bölüm - dil seçimi
                    TranslationHeaderView(
                        viewModel: viewModel,
                        showSourceLanguageOptions: $showSourceLanguageOptions,
                        showTargetLanguageOptions: $showTargetLanguageOptions,
                        onFocusChange: { focused in
                            isInputFocused = focused
                        }
                    )
                    
                        // Giriş kartı
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(viewModel.getSourceLanguageText(), systemImage: "text.bubble")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            TranslateAreaTextEditor(
                                text: $viewModel.inputText,
                                placeholder: "Çevrilecek metni girin",
                                isEditable: true,
                                maxHeight: 120,
                                onCommit: {
                                    if viewModel.canTranslate() {
                                        Task {
                                            await viewModel.translate()
                                        }
                                    }
                                }
                            )
                            .onChange(of: viewModel.inputText) { _, _ in
                                onFocusChange(true)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 140)
                            
                            // Çeviri butonu
                            HStack {
                                Spacer()
                                Button {
                                    if viewModel.inputText.isEmpty && UIPasteboard.general.hasStrings {
                                        // Yapıştır işlemi
                                        if let pasteString = UIPasteboard.general.string {
                                            viewModel.inputText = pasteString
                                            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                            impactGenerator.impactOccurred()
                                        }
                                    } else {
                                        // Çeviri işlemi
                                        onFocusChange(false)
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        Task {
                                            await viewModel.translate()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        if viewModel.inputText.isEmpty && UIPasteboard.general.hasStrings {
                                            Text("Yapıştır")
                                            Image(systemName: "doc.on.clipboard")
                                        } else {
                                            Text("Çevir")
                                            Image(systemName: "arrow.down")
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(
                                        (viewModel.canTranslate() || (viewModel.inputText.isEmpty && UIPasteboard.general.hasStrings)) ? 
                                            Color.blue : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .font(.headline)
                                    .shadow(color: 
                                        (viewModel.canTranslate() || (viewModel.inputText.isEmpty && UIPasteboard.general.hasStrings)) ? 
                                            Color.blue.opacity(0.3) : Color.clear, 
                                        radius: 3, x: 0, y: 1
                                    )
                                }
                                .disabled(!viewModel.canTranslate() && !(viewModel.inputText.isEmpty && UIPasteboard.general.hasStrings))
                                .padding(.bottom, 12)
                                .padding(.trailing, 16)
                            }
                        }
                        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Çıktı kartı
                        if !viewModel.translatedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(viewModel.selectedTargetLanguage.name, systemImage: "text.bubble.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                
                                TranslateAreaTextEditor(
                                    text: $viewModel.translatedText,
                                    placeholder: "Çeviri burada görünecek",
                                    isEditable: false,
                                    maxHeight: 120
                                )
                                .padding(.horizontal, 16)
                                .frame(height: 140)
                                
                                // İşlem butonları
                                HStack(spacing: 20) {
                                    // Sesli dinleme butonu
                                    Button {
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        
                                        if case .speaking = viewModel.state {
                                            viewModel.stopAudio()
                                        } else {
                                            viewModel.convertTextToSpeech()
                                        }
                                    } label: {
                                        Image(systemName: playButtonIcon)
                                            .font(.system(size: 18))
                                            .frame(width: 40, height: 40)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(isAudioButtonDisabled)
                                    .opacity(isAudioButtonDisabled ? 0.5 : 1)
                                    
                                    // Kopyala butonu
                                    Button {
                                        UIPasteboard.general.string = viewModel.translatedText
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        let notificationGenerator = UINotificationFeedbackGenerator()
                                        notificationGenerator.notificationOccurred(.success)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 18))
                                            .frame(width: 40, height: 40)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(.blue)
                                    }
                                    
                                    // Paylaş butonu
                                    Button {
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        
                                        let activityVC = UIActivityViewController(
                                            activityItems: [viewModel.translatedText],
                                            applicationActivities: nil
                                        )
                                        
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootViewController = windowScene.windows.first?.rootViewController {
                                            rootViewController.present(activityVC, animated: true)
                                        }
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 18))
                                            .frame(width: 40, height: 40)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    // Önbellek bilgisi düğmesi
                                    Button {
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                                        impactGenerator.impactOccurred()
                                        
                                        withAnimation {
                                            viewModel.showCacheInfo.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "cylinder.split.1x2")
                                            .font(.system(size: 18))
                                            .frame(width: 40, height: 40)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(viewModel.showCacheInfo ? .blue : .gray)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                
                                // Önbellek bilgisi
                                if viewModel.showCacheInfo {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Ses Önbelleği:")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Button {
                                                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                                impactGenerator.impactOccurred()
                                                viewModel.clearAudioCache()
                                            } label: {
                                                Text("Temizle")
                                                    .font(.footnote)
                                                    .foregroundColor(.blue)
                                            }
                                            .disabled(viewModel.audioCacheStats.count == 0)
                                        }
                                        
                                        HStack {
                                            Text("\(viewModel.audioCacheStats.count) ses, \(viewModel.getCacheSize())")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                            
                            Spacer()
                                            
                                            Text("24 saat sonra otomatik silinir")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            }
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Çeviri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettingsView = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistoryView = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showSourceLanguageOptions) {
                LanguageSelectionView(
                    selectedLanguage: $viewModel.selectedSourceLanguage,
                    languages: viewModel.availableSourceLanguages,
                    includeAutoDetect: true,
                    title: "Kaynak Dil Seçin"
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTargetLanguageOptions) {
                LanguageSelectionView(
                    selectedLanguage: $viewModel.selectedTargetLanguage,
                    languages: viewModel.availableLanguages,
                    includeAutoDetect: false,
                    title: "Hedef Dil Seçin"
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showHistoryView) {
                TranslationHistoryViewWrapper(viewModel: viewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
            .overlay {
                // Durum görünümleri
                TranslationStateView(viewModel: viewModel)
            }
        }
    }
    
    // onFocusChange fonksiyonu
    private func onFocusChange(_ focused: Bool) {
        isInputFocused = focused
    }
    
    // Ses oynatma butonu durumuna göre ikonu değiştir
    private var playButtonIcon: String {
        switch viewModel.state {
        case .speaking:
            return "stop.fill"
        case .converting:
            return "waveform"
        default:
            return "speaker.wave.2.fill"
        }
    }
    
    // Ses oynatma butonu aktiflik durumu
    private var isAudioButtonDisabled: Bool {
        switch viewModel.state {
        case .translating, .detecting, .error:
            return true
        case .converting:
            return true
        default:
            return viewModel.translatedText.isEmpty
        }
    }
}

// Ana ekran ve geçmiş arasında köprü oluşturacak wrapper view
struct TranslationHistoryViewWrapper: View {
    let viewModel: TranslationViewModel
    
    var body: some View {
        // Burada geçmiş ekranına ana view model'i geçiyoruz
        TranslationHistoryView(historyService: viewModel.historyService)
    }
}

#Preview {
    TranslationView()
} 