import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showSourceLanguageOptions = false
    @State private var showTargetLanguageOptions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Ana içerik
                VStack(spacing: 0) {
                    // Üst bölüm - dil seçimi
                    TranslationHeaderView(
                        viewModel: viewModel,
                        showSourceLanguageOptions: $showSourceLanguageOptions,
                        showTargetLanguageOptions: $showTargetLanguageOptions,
                        onFocusChange: { focused in
                            isInputFocused = focused
                        }
                    )
                    
                    // Alt bölüm - çeviri alanı
                    ZStack {
                        Color(UIColor.systemBackground)
                        
                        VStack(spacing: 0) {
                            // Giriş alanı
                            TranslationInputView(
                                viewModel: viewModel,
                                onFocusChange: { focused in
                                    isInputFocused = focused
                                }
                            )
                            
                            // Çıktı alanı
                            TranslationOutputView(viewModel: viewModel)
                            
                            Spacer()
                        }
                    }
                    
                    // Debug mesajı
                    DebugMessageView(viewModel: viewModel)
                }
            }
            .navigationTitle("Ceviri")
            .navigationBarTitleDisplayMode(.inline)
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
            .overlay {
                // Durum görünümleri
                TranslationStateView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    TranslationView()
} 