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
    
    // Ses hızı ayarı için state
    @State private var playbackRate: Float = UserDefaults.standard.float(forKey: "playbackRate").isZero ? 0.85 : UserDefaults.standard.float(forKey: "playbackRate")
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API Anahtarları")) {
                    VStack(alignment: .leading) {
                        Text("ElevenLabs API Anahtarı")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        TextField("ElevenLabs API Anahtarı", text: $elevenLabsKey)
                            .padding(12)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Text("Ses dönüşümü için kullanılır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading) {
                        Text("Gemini API Anahtarı")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        TextField("Gemini API Anahtarı", text: $geminiKey)
                            .padding(12)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Text("Çeviri işlemleri için kullanılır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Ses Ayarları")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ses Seçimi")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        if isLoadingVoices {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        } else if voiceLoadError {
                            Text("Sesler yüklenemedi. Lütfen API anahtarınızı kontrol edin.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        } else if voices.isEmpty {
                            Button("Sesleri Yükle") {
                                loadVoices()
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        } else {
                            // Ses seçim açılır menüsü
                            Picker("Varsayılan Ses", selection: $selectedVoiceID) {
                                ForEach(voices) { voice in
                                    HStack {
                                        Text(voice.name)
                                        if voice.category == "premade" {
                                            Text("(Hazır)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("(Özel)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .tag(voice.voice_id)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        if !voices.isEmpty {
                            Text("Çevirilerinizin seslendirilmesi için varsayılan ses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ses Hızı")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("Yavaş")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $playbackRate, in: 0.5...1.5, step: 0.05)
                                .accentColor(.blue)
                            
                            Text("Hızlı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Spacer()
                            Text("Şu anki hız: \(String(format: "%.2f", playbackRate))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        Button("Varsayılan Hıza Sıfırla (0.85x)") {
                            playbackRate = 0.85
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Varsayılan API Anahtarlarına Sıfırla") {
                        elevenLabsKey = AppConfig.elevenLabsAPIKey
                        geminiKey = AppConfig.geminiAPIKey
                    }
                    .foregroundColor(.blue)
                }
                
                Section {
                    Button {
                        saveSettings()
                    } label: {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
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
                    voices = retrievedVoices
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
        alertMessage = "Ayarlar kaydedildi. Değişikliklerin etkin olması için uygulamayı yeniden başlatın."
        showAlert = true
        
        // Kullanıcıya bildirim göndermek için haptic geri bildirim
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    SettingsView()
} 