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

            // Önbellek bilgisi
            if viewModel.showCacheInfo {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Ses Önbelleği:")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button {
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
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            // İşlem butonları
            if !viewModel.translatedText.isEmpty {
                HStack(spacing: 16) {
                    // Önbellek bilgisi düğmesi
                    Button {
                        withAnimation {
                            viewModel.showCacheInfo.toggle()
                        }
                    } label: {
                        Image(systemName: "cylinder.split.1x2")
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundColor(viewModel.showCacheInfo ? .blue : .gray)
                    }

                    Spacer()

                    // Sesli dinleme butonu
                    Button {
                        if case .speaking = viewModel.state {
                            viewModel.stopAudio()
                        } else {
                            viewModel.generateSpeech()
                        }
                    } label: {
                        Image(systemName: playButtonIcon)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundColor(.blue)
                    }
                    .disabled(isAudioButtonDisabled)
                    .opacity(isAudioButtonDisabled ? 0.5 : 1)

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
