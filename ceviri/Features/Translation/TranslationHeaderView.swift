import SwiftUI

struct TranslationHeaderView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @Binding var showSourceLanguageOptions: Bool
    @Binding var showTargetLanguageOptions: Bool
    var onFocusChange: (Bool) -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : Color(UIColor.systemGroupedBackground)
    }

    var body: some View {
        ZStack {
            // Düz arka plan
            backgroundColor
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    // Kaynak dil göstergesi
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

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
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    Spacer()

                    // Dil değiştirme butonu
                    Button {
                        // Klavyeyi kapat
                        onFocusChange(false)

                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

                        Task {
                            await viewModel.swapLanguages()
                        }
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    // Sadece "auto" seçili ve bir dil algılanmamışsa buton pasif olacak
                    .disabled(viewModel.selectedSourceLanguage.code == "auto" && viewModel.detectedLanguage.isEmpty)
                    .opacity(viewModel.selectedSourceLanguage.code == "auto" && viewModel.detectedLanguage.isEmpty ? 0.5 : 1)

                    Spacer()

                    // Hedef dil seçici
                    Button {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()

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
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
