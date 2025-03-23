import SwiftUI

struct TranslationOutputView: View {
    @ObservedObject var viewModel: TranslationViewModel
    
    var body: some View {
        VStack {
            Divider()
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
            
            // Çeviri sonucu alanı
            TranslateAreaTextEditor(
                text: $viewModel.translatedText,
                placeholder: "Çeviri burada görünecek",
                isEditable: false,
                maxHeight: 120
            )
            .padding(.horizontal)
            .frame(height: 140)
            
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
    }
} 
