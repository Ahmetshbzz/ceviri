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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isInputFocused {
                            isInputFocused = false
                        }
                    }

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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isInputFocused {
                            isInputFocused = false
                        }
                    }

                    // Çeviri Stili Seçimi
                    HStack {
                        Spacer()

                        Button {
                            if isInputFocused {
                                isInputFocused = false
                            }
                            viewModel.toggleModelStyle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.isInformalStyle ? "person.2.fill" : "building.2.fill")
                                    .font(.caption)
                                Text(viewModel.getModelStyleText())
                                    .font(.footnote)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule()
                                    .fill(viewModel.isInformalStyle ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                            )
                            .foregroundColor(viewModel.isInformalStyle ? .purple : .blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isInputFocused {
                            isInputFocused = false
                        }
                    }

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isInputFocused {
                                    isInputFocused = false
                                }
                            }

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
                            .focused($isInputFocused)
                            .onChange(of: viewModel.inputText) { oldValue, newValue in
                                onFocusChange(true)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 140)

                            // Çeviri butonu
                            HStack {
                                Spacer()
                                Button {
                                    isInputFocused = false
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isInputFocused {
                                    isInputFocused = false
                                }
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isInputFocused {
                                        isInputFocused = false
                                    }
                                }

                                TranslateAreaTextEditor(
                                    text: $viewModel.translatedText,
                                    placeholder: "Çeviri burada görünecek",
                                    isEditable: false,
                                    maxHeight: 120
                                )
                                .padding(.horizontal, 16)
                                .frame(height: 140)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isInputFocused {
                                        isInputFocused = false
                                    }
                                }

                                // İşlem butonları
                                HStack(spacing: 20) {
                                    // Sesli dinleme butonu
                                    Button {
                                        if isInputFocused {
                                            isInputFocused = false
                                        }
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()

                                        if case .speaking = viewModel.state {
                                            viewModel.stopAudio()
                                        } else {
                                            viewModel.generateSpeech()
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
                                        if isInputFocused {
                                            isInputFocused = false
                                        }
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
                                        if isInputFocused {
                                            isInputFocused = false
                                        }
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
                                        if isInputFocused {
                                            isInputFocused = false
                                        }
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isInputFocused {
                                        isInputFocused = false
                                    }
                                }

                                // Önbellek bilgisi
                                if viewModel.showCacheInfo {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Ses Önbelleği:")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)

                                            Spacer()

                                            Button {
                                                if isInputFocused {
                                                    isInputFocused = false
                                                }
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isInputFocused {
                                            isInputFocused = false
                                        }
                                    }
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
                .contentShape(Rectangle())
                .onTapGesture {
                    if isInputFocused {
                        isInputFocused = false
                    }
                }
            }
            .navigationTitle("Çeviri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isInputFocused {
                            isInputFocused = false
                        }
                        showSettingsView = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isInputFocused {
                            isInputFocused = false
                        }
                        showHistoryView = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Tamam") {
                            isInputFocused = false
                        }
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
