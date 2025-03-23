import SwiftUI

struct TranslationStateView: View {
    @ObservedObject var viewModel: TranslationViewModel
    
    var body: some View {
        ZStack {
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

// Debug mesaj görünümü
struct DebugMessageView: View {
    @ObservedObject var viewModel: TranslationViewModel
    
    var body: some View {
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
} 