import Foundation
import AVFoundation

class ElevenLabsService {
    private let apiKey = "sk_a7856b10a9a2455aebac7bfe210f139e9bba2c9e01186710"
    private let baseURL = "https://api.elevenlabs.io/v1"
    private var audioPlayer: AVAudioPlayer?
    
    // Varsayılan ses modeli ID'leri
    private let defaultVoiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel - Doğal kadın sesi
    private let defaultModelID = "eleven_multilingual_v2"
    
    func convertTextToSpeech(text: String, voiceID: String? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        let actualVoiceID = voiceID ?? defaultVoiceID
        let endpoint = "\(baseURL)/text-to-speech/\(actualVoiceID)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "ElevenLabsService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let bodyParams: [String: Any] = [
            "text": text,
            "model_id": defaultModelID,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyParams)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "ElevenLabsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yanıt"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseString = data != nil ? String(data: data!, encoding: .utf8) ?? "" : ""
                completion(.failure(NSError(domain: "ElevenLabsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Hatası: \(httpResponse.statusCode) - \(responseString)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "ElevenLabsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri bulunamadı"])))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    func playAudio(data: Data) throws {
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
        
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    // Mevcut sesleri listele
    func listVoices(completion: @escaping (Result<[Voice], Error>) -> Void) {
        let endpoint = "\(baseURL)/voices"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "ElevenLabsService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "ElevenLabsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Veri bulunamadı"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(VoicesResponse.self, from: data)
                completion(.success(response.voices))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// API Yanıt Modelleri
struct Voice: Codable, Identifiable {
    let voice_id: String
    let name: String
    let category: String?
    
    var id: String { voice_id }
}

struct VoicesResponse: Codable {
    let voices: [Voice]
} 