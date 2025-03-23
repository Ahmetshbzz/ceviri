import SwiftUI

struct TranslationStateView: View {
    @ObservedObject var viewModel: TranslationViewModel
    
    var body: some View {
        ZStack {
            // Yükleme göstergesi
            if case .translating = viewModel.state {
                loadingOverlay(message: "Çeviriliyor...")
            }
            
            // Ses oluşturma ve oynatma durumlarında overlay gösterme
            // Bu kısımları kaldırdık, çünkü DebugMessageView yeterli
            
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
    
    private func loadingOverlay(message: String, systemImage: String = "arrow.triangle.2.circlepath") -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                if systemImage == "speaker.wave.2.fill" {
                    // Ses dalgası animasyonu
                    HStack(spacing: 5) {
                        ForEach(0..<4) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: 4, height: 15 + CGFloat.random(in: 5...20))
                                .offset(y: 3)
                        }
                    }
                    .frame(height: 35)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
        .transition(.opacity)
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