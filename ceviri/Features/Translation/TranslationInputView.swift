import SwiftUI

struct TranslationInputView: View {
    @ObservedObject var viewModel: TranslationViewModel
    var onFocusChange: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Kaynak metin alanı
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
            .padding(.horizontal)
            .padding(.top, 16)
            .frame(height: 140)

            Divider()
                .padding(.horizontal, 30)
                .padding(.vertical, 8)

            // Orta bölüm - Algılanan dil ve çeviri butonu
            HStack {
                if !viewModel.detectedLanguage.isEmpty && !viewModel.inputText.isEmpty && viewModel.selectedSourceLanguage.code == "auto" {
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
                    onFocusChange(false)
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
        }
    }
}
