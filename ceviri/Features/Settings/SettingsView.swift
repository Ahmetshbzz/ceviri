import SwiftUI

struct SettingsView: View {
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "elevenLabsAPIKey") ?? AppConfig.elevenLabsAPIKey
    @State private var geminiKey: String = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? AppConfig.geminiAPIKey
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
            Form {
                // API ANAHTARLARI
                Section(header: Text("API Anahtarları")) {
                    // ElevenLabs
                    LabeledContent("ElevenLabs API") {
                        TextField("API Anahtarı", text: $elevenLabsKey)
                            .font(.footnote)
                            .padding(6)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    // Gemini
                    LabeledContent("Gemini API") {
                        TextField("API Anahtarı", text: $geminiKey)
                            .font(.footnote)
                            .padding(6)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    Button("Varsayılan API Anahtarlarına Sıfırla") {
                        elevenLabsKey = AppConfig.elevenLabsAPIKey
                        geminiKey = AppConfig.geminiAPIKey
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // SES AYARLARI
                Section(header: Text("Ses Ayarları")) {
                    // Ses Seçimi
                    LabeledContent {
                        if isLoadingVoices {
                            ProgressView().scaleEffect(0.8)
                        } else if voiceLoadError {
                            Text("Yüklenemedi")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else {
                            Picker("", selection: $selectedVoiceID) {
                                // Rachel sesini manuel olarak ekliyoruz
                                Text("\(rachelVoice.name) ⭐")
                                    .tag(rachelVoice.voice_id)
                                
                                // Diğer sesler
                                if !voices.isEmpty {
                                    Divider()
                                    ForEach(voices.filter { $0.voice_id != rachelVoice.voice_id }) { voice in
                                        Text("\(voice.name) \(voice.category == "premade" ? "✓" : "")")
                                            .tag(voice.voice_id)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    } label: {
                        Text("Ses Seçimi")
                    }
                    
                    // Ses Hızı
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent {
                            Text("\(String(format: "%.2f", playbackRate))x")
                                .font(.footnote)
                                .monospacedDigit()
                        } label: {
                            Text("Ses Hızı")
                        }
                        
                        HStack(spacing: 8) {
                            Text("0.5x").font(.caption)
                            Slider(value: $playbackRate, in: 0.5...1.5, step: 0.05)
                            Text("1.5x").font(.caption)
                        }
                        
                        Button("Normal: 0.85x") {
                            playbackRate = 0.85
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                // KAYDET BUTONU
                Section {
                    Button {
                        saveSettings()
                    } label: {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
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
        
        // Seçilen sesi kaydet
        UserDefaults.standard.setValue(selectedVoiceID, forKey: "selectedVoiceID")
        
        // Ses hızını kaydet
        UserDefaults.standard.setValue(playbackRate, forKey: "playbackRate")
        
        // Bilgi mesajı göster
        alertMessage = "Ayarlar kaydedildi."
        showAlert = true
        
        // Kullanıcıya bildirim göndermek için haptic geri bildirim
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    SettingsView()
} 