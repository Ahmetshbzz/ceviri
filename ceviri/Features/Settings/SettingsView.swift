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
    @State private var playbackRate: Float = UserDefaults.standard.float(forKey: "playbackRate").isZero ? 0.85 : UserDefaults.standard.float(forKey: "playbackRate")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ÇEVİRİ SERVİSİ SEÇİMİ
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Çeviri Servisi")
                            .font(.title3)
                            .fontWeight(.medium)

                        Picker("Çeviri Servisi", selection: $translationService) {
                            Text("Gemini AI").tag("gemini")
                            Text("OpenAI").tag("openai")
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 8)
                    }

                    Divider()

                    // API ANAHTARLARI
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

                        // Gemini
                        MinimalTextField(
                            title: "Gemini API",
                            text: $geminiKey,
                            placeholder: "API Anahtarı"
                        )

                        // OpenAI
                        MinimalTextField(
                            title: "OpenAI API",
                            text: $openAIKey,
                            placeholder: "API Anahtarı"
                        )

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
                    .padding(.bottom, 8)

                    Divider()

                    // SES AYARLARI
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
                                Text("0.5x")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Slider(value: $playbackRate, in: 0.5...1.5, step: 0.05)

                                Text("1.5x")
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
                    .padding(.vertical, 8)

                    Divider()

                    // KAYDET BUTONU
                    Button {
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
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("İptal")
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

        // TranslationManager servislerini yenile
        TranslationManager.shared.refreshAPIKeys()

        // Bilgi mesajı göster
        alertMessage = "Ayarlar kaydedildi."
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
