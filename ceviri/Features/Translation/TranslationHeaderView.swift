import SwiftUI

struct TranslationHeaderView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @Binding var showSourceLanguageOptions: Bool
    @Binding var showTargetLanguageOptions: Bool
    var onFocusChange: (Bool) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Üst bölüm gradient renkleri
    private var topGradientColors: [Color] {
        colorScheme == .dark ? 
            [Color.blue.opacity(0.7), Color.purple.opacity(0.6)] : 
            [Color.blue.opacity(0.85), Color.purple.opacity(0.75)]
    }
    
    var body: some View {
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
                        showSourceLanguageOptions = true
                        // Klavyeyi kapat
                        onFocusChange(false)
                    } label: {
                        HStack {
                            if viewModel.detectedLanguage.isEmpty && viewModel.selectedSourceLanguage.code == "auto" {
                                Text("Otomatik")
                            } else if viewModel.selectedSourceLanguage.code != "auto" {
                                Text(viewModel.selectedSourceLanguage.name)
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
                        // Klavyeyi kapat
                        onFocusChange(false)
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
                    .disabled(viewModel.translatedText.isEmpty || viewModel.selectedSourceLanguage.code == "auto")
                    .opacity(viewModel.translatedText.isEmpty || viewModel.selectedSourceLanguage.code == "auto" ? 0.5 : 1)
                    
                    Spacer()
                    
                    // Hedef dil seçici
                    Button {
                        showTargetLanguageOptions = true
                        // Klavyeyi kapat
                        onFocusChange(false)
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
    }
} 