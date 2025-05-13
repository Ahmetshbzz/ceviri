import SwiftUI

struct SettingsView: View {
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "elevenLabsAPIKey") ?? AppConfig.elevenLabsAPIKey
    @State private var geminiKey: String = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? AppConfig.geminiAPIKey
    @State private var openAIKey: String = UserDefaults.standard.string(forKey: "openAIAPIKey") ?? AppConfig.openAIAPIKey
    @State private var translationService: String = UserDefaults.standard.string(forKey: "translationService") ?? "gemini"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Aktif sekme seçimi için state
    @State private var selectedTab = 0

    // Klavye durumu için FocusState
    @FocusState private var isTextFieldFocused: Bool

    // ElevenLabs servisi
    private let elevenLabsService = ElevenLabsService()

    // Sesler için state
    @State private var voices: [Voice] = []
    @State private var selectedVoiceID: String = UserDefaults.standard.string(forKey: "selectedVoiceID") ?? "21m00Tcm4TlvDq8ikWAM"
    @State private var isLoadingVoices = false
    @State private var voiceLoadError = false

    // Rachel sesi (manuel olarak eklendi)
    private let rachelVoice = Voice(voice_id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel (Doğal Kadın Sesi)", category: "premade")

    // Ses hızı ayarı için state
    @State private var playbackRate: Float = {
        let savedRate = UserDefaults.standard.float(forKey: "playbackRate")
        // Değer 0'sa (ayarlanmamışsa) veya geçerli aralıkta değilse (0.75...1.15) varsayılan değeri kullan
        if savedRate.isZero || savedRate < 0.75 || savedRate > 1.15 {
            return 0.85
        }
        // 0.05'in en yakın katına yuvarlama
        let multiplier: Float = 20.0 // 1/0.05 = 20
        return round(savedRate * multiplier) / multiplier
    }()

    // Model stili seçimi için state
    @State private var modelStyle: String = UserDefaults.standard.string(forKey: "modelStyle") ?? "formal"
    @State private var overrideModelStyle: Bool = UserDefaults.standard.bool(forKey: "overrideModelStyle")

    // Sekme başlıkları
    private let tabs = ["Genel", "Ses", "API Anahtarları"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sekme çubuğu
                TabSelectionView(tabs: tabs, selectedTab: $selectedTab)
                    .padding(.top, 8)

                Divider()

                // Sekme içerikleri
                TabView(selection: $selectedTab) {
                    // GENEL AYARLAR SEKMESİ
                    ScrollView {
                        genelAyarlarView
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .tag(0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Klavye gösterimini kapat
                        isTextFieldFocused = false
                    }

                    // SES AYARLARI SEKMESİ
                    ScrollView {
                        sesAyarlariView
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .tag(1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Klavye gösterimini kapat
                        isTextFieldFocused = false
                    }

                    // API ANAHTARLARI SEKMESİ
                    ScrollView {
                        apiAnahtarlariView
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .tag(2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Klavye gösterimini kapat
                        isTextFieldFocused = false
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Divider()

                // KAYDET BUTONU
                Button {
                    // Klavyeyi kapat
                    isTextFieldFocused = false

                    saveSettings()
                } label: {
                    Text("Kaydet")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Klavyeyi kapat
                        isTextFieldFocused = false
                        dismiss()
                    } label: {
                        Text("İptal")
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Tamam") {
                            isTextFieldFocused = false
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Bilgi"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .onAppear {
                loadVoices()
            }
        }
    }

    // GENEL AYARLAR SEKMESİ GÖRÜNÜMÜ
    private var genelAyarlarView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Çeviri Servisi")
                .font(.title3)
                .fontWeight(.medium)

            Picker("Çeviri Servisi", selection: $translationService) {
                Text("Gemini AI").tag("gemini")
                Text("OpenAI").tag("openai")
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)

            // Model Stili Seçimi
            HStack {
                Text("Model tercihleri geçersiz kılınsın mı?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("", isOn: $overrideModelStyle)
            }

            Text("Açık olduğunda, her zaman yukarıda seçtiğiniz servis kullanılır. Kapalı olduğunda, çeviri stili kullanılacak modeli otomatik belirler.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            if !overrideModelStyle {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Çeviri Stili")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Çeviri Stili", selection: $modelStyle) {
                        Text("Standart Dil").tag("formal")
                        Text("Günlük Dil").tag("informal")
                    }
                    .pickerStyle(.segmented)

                    if modelStyle == "formal" {
                        Text("Standart dil: Resmi ortamlar ve profesyonel iletişim için uygundur. OpenAI kullanır.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Günlük dil: Arkadaşlar arası konuşma ve informal iletişim için uygundur. Gemini kullanır.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // SES AYARLARI SEKMESİ GÖRÜNÜMÜ
    private var sesAyarlariView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Ses Ayarları")
                .font(.title3)
                .fontWeight(.medium)

            // Ses Seçimi
            VStack(alignment: .leading, spacing: 8) {
                Text("Ses")
                    .font(.callout)
                    .foregroundColor(.secondary)

                if isLoadingVoices {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(height: 40)
                } else if voiceLoadError {
                    Text("Sesler yüklenemedi")
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else {
                    Menu {
                        // Rachel sesini manuel olarak ekliyoruz
                        Button {
                            selectedVoiceID = rachelVoice.voice_id
                        } label: {
                            HStack {
                                Text("\(rachelVoice.name) ⭐")
                                if selectedVoiceID == rachelVoice.voice_id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        // Diğer sesler
                        if !voices.isEmpty {
                            Divider()
                            ForEach(voices.filter { $0.voice_id != rachelVoice.voice_id }) { voice in
                                Button {
                                    selectedVoiceID = voice.voice_id
                                } label: {
                                    HStack {
                                        Text("\(voice.name) \(voice.category == "premade" ? "✓" : "")")
                                        if selectedVoiceID == voice.voice_id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(voices.first(where: { $0.voice_id == selectedVoiceID })?.name ?? rachelVoice.name)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 10)
                    }
                }
            }

            // Ses Hızı
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hız")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(String(format: "%.2f", playbackRate))x")
                        .font(.footnote.monospacedDigit())
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Text("0.75x")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Slider(value: $playbackRate, in: 0.75...1.15, step: 0.05)

                    Text("1.15x")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button {
                    playbackRate = 0.85
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Text("Normal (0.85x)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // API ANAHTARLARI SEKMESİ GÖRÜNÜMÜ
    private var apiAnahtarlariView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("API Anahtarları")
                .font(.title3)
                .fontWeight(.medium)

            // ElevenLabs
            MinimalTextField(
                title: "ElevenLabs API",
                text: $elevenLabsKey,
                placeholder: "API Anahtarı"
            )
            .focused($isTextFieldFocused)

            // Gemini
            MinimalTextField(
                title: "Gemini API",
                text: $geminiKey,
                placeholder: "API Anahtarı"
            )
            .focused($isTextFieldFocused)

            // OpenAI
            MinimalTextField(
                title: "OpenAI API",
                text: $openAIKey,
                placeholder: "API Anahtarı"
            )
            .focused($isTextFieldFocused)

            Button {
                elevenLabsKey = AppConfig.elevenLabsAPIKey
                geminiKey = AppConfig.geminiAPIKey
                openAIKey = AppConfig.openAIAPIKey
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } label: {
                Text("Varsayılan değerlere sıfırla")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func loadVoices() {
        isLoadingVoices = true
        voiceLoadError = false

        elevenLabsService.listVoices { result in
            DispatchQueue.main.async {
                isLoadingVoices = false

                switch result {
                case .success(let retrievedVoices):
                    // Rachel sesini içermeyen sesleri filtreleyerek alıyoruz
                    voices = retrievedVoices.filter { $0.voice_id != rachelVoice.voice_id }
                case .failure(_):
                    voiceLoadError = true
                }
            }
        }
    }

    private func saveSettings() {
        // API anahtarlarını UserDefaults'a kaydet
        UserDefaults.standard.setValue(elevenLabsKey, forKey: "elevenLabsAPIKey")
        UserDefaults.standard.setValue(geminiKey, forKey: "geminiAPIKey")
        UserDefaults.standard.setValue(openAIKey, forKey: "openAIAPIKey")

        // Çeviri servisini kaydet
        UserDefaults.standard.setValue(translationService, forKey: "translationService")

        // Seçilen sesi kaydet
        UserDefaults.standard.setValue(selectedVoiceID, forKey: "selectedVoiceID")

        // Ses hızını kaydet
        UserDefaults.standard.setValue(playbackRate, forKey: "playbackRate")

        // Model stili ayarlarını kaydet
        UserDefaults.standard.set(modelStyle, forKey: "modelStyle")
        UserDefaults.standard.set(overrideModelStyle, forKey: "overrideModelStyle")

        // TranslationManager'ı güncelle
        if let style = ModelStyle(rawValue: modelStyle) {
            TranslationManager.shared.setModelStyle(style)
        }

        // TranslationManager servislerini yenile
        TranslationManager.shared.refreshAPIKeys()

        // Bilgi mesajı göster
        alertMessage = "Ayarlar başarıyla kaydedildi."
        showAlert = true

        // Kullanıcıya bildirim göndermek için haptic geri bildirim
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Kısa bir süre sonra ekranı kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

// Sekme Seçim Görünümü
struct TabSelectionView: View {
    let tabs: [String]
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .primary : .secondary)

                        // Seçili sekmenin altındaki çizgi
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// Özel bileşenler
struct MinimalTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .font(.subheadline)
                .padding(.vertical, 8)
                .background(Color.clear)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .offset(y: 12),
                    alignment: .bottom
                )
        }
    }
}

#Preview {
    SettingsView()
}
