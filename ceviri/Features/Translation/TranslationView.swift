import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var showLanguageOptions = false
    
    // Üst bölüm gradient renkleri
    private var topGradientColors: [Color] {
        colorScheme == .dark ? 
            [Color.blue.opacity(0.7), Color.purple.opacity(0.6)] : 
            [Color.blue.opacity(0.85), Color.purple.opacity(0.75)]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Üst bölüm - dil seçimi
                ZStack {
                    // Gradient arkaplan
                    LinearGradient(gradient: Gradient(colors: topGradientColors), 
                                  startPoint: .topLeading, 
                                  endPoint: .bottomTrailing)
                        .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 16) {
                        HStack(alignment: .center) {
                            // Kaynak dil göstergesi
                            Button {
                                // Dil seçme modalını aç (şimdilik sadece görsel)
                                showLanguageOptions = true
                            } label: {
                                HStack {
                                    if viewModel.detectedLanguage.isEmpty {
                                        Text("Otomatik")
                                    } else {
                                        Text(viewModel.getDetectedLanguageName())
                                    }
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                            }
                            
                            Spacer()
                            
                            // Dil değiştirme butonu
                            Button {
                                Task {
                                    await viewModel.swapLanguages()
                                }
                            } label: {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .disabled(viewModel.detectedLanguage.isEmpty || viewModel.translatedText.isEmpty)
                            .opacity(viewModel.detectedLanguage.isEmpty || viewModel.translatedText.isEmpty ? 0.5 : 1)
                            
                            Spacer()
                            
                            // Hedef dil seçici
                            Button {
                                showLanguageOptions = true
                            } label: {
                                HStack {
                                    Text(viewModel.selectedTargetLanguage.name)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 20)
                }
                .frame(height: 120)
                
                // Alt bölüm - çeviri alanı
                ZStack {
                    Color(UIColor.systemBackground)
                    
                    VStack(spacing: 0) {
                        // Kaynak metin alanı
                        ZStack(alignment: .topTrailing) {
                            ModernTextEditor(
                                text: $viewModel.inputText,
                                placeholder: "Çevrilecek metni girin",
                                isEditable: true,
                                maxHeight: 180,
                                onCommit: {
                                    if viewModel.canTranslate() {
                                        Task {
                                            await viewModel.translate()
                                        }
                                    }
                                }
                            )
                            .padding(.top, 4)
                            .focused($isInputFocused)
                            
                            if !viewModel.inputText.isEmpty {
                                // Temizleme butonu
                                Button {
                                    viewModel.clearText()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Orta bölüm
                        HStack {
                            if !viewModel.detectedLanguage.isEmpty && !viewModel.inputText.isEmpty {
                                Label("Algılanan: \(viewModel.getDetectedLanguageName())", systemImage: "globe")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button {
                                isInputFocused = false
                                Task {
                                    await viewModel.translate()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Çevir")
                                    Image(systemName: "arrow.right")
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(viewModel.canTranslate() ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .font(.headline)
                            }
                            .disabled(!viewModel.canTranslate())
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Çeviri sonucu alanı
                        VStack {
                            ModernTextEditor(
                                text: $viewModel.translatedText,
                                placeholder: "Çeviri burada görünecek",
                                isEditable: false,
                                maxHeight: 180
                            )
                            .padding(.top, 4)
                            
                            // İşlem butonları
                            if !viewModel.translatedText.isEmpty {
                                HStack(spacing: 16) {
                                    Spacer()
                                    
                                    // Kopyala butonu
                                    Button {
                                        UIPasteboard.general.string = viewModel.translatedText
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .padding(12)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(.blue)
                                    }
                                    
                                    // Paylaş butonu
                                    Button {
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
                                            .padding(12)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Circle())
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
                
                // Debug mesajı (geliştirme aşamasında)
                if !viewModel.debugMessage.isEmpty {
                    Text(viewModel.debugMessage)
                        .font(.footnote)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            viewModel.debugMessage.contains("⚠️") || viewModel.debugMessage.contains("‼️") 
                                ? Color.red.opacity(0.15) 
                                : Color.gray.opacity(0.15)
                        )
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }
            }
            .navigationTitle("Ceviri")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLanguageOptions) {
                LanguageSelectionView(
                    selectedLanguage: $viewModel.selectedTargetLanguage,
                    languages: viewModel.availableLanguages
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .overlay {
                // Yükleme göstergesi
                if case .translating = viewModel.state {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Çeviriliyor...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }
                
                // Hata mesajı
                if case let .error(message) = viewModel.state {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            
                            Text("Hata")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button("Tamam") {
                                withAnimation {
                                    viewModel.state = .idle
                                }
                            }
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding()
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

// Dil seçim görünümü
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: Language
    let languages: [Language]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredLanguages) { language in
                    Button {
                        selectedLanguage = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if language.code == selectedLanguage.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dil Seçin")
            .searchable(text: $searchText, prompt: "Dil Ara")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TranslationView()
} 