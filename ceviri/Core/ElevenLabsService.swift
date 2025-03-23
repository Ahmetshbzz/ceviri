import Foundation
import AVFoundation

protocol ElevenLabsPlayerDelegate: AnyObject {
    func audioPlaybackDidFinish()
}

// Önbellekteki ses verileri için model
struct CachedAudio {
    let data: Data
    let timestamp: Date
    let text: String
    let voiceID: String
}

class ElevenLabsService: NSObject, AVAudioPlayerDelegate {
    private let apiKey = "sk_a7856b10a9a2455aebac7bfe210f139e9bba2c9e01186710"
    private let baseURL = "https://api.elevenlabs.io/v1"
    private var audioPlayer: AVAudioPlayer?
    
    weak var delegate: ElevenLabsPlayerDelegate?
    
    // Varsayılan ses modeli ID'leri
    private let defaultVoiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel - Doğal kadın sesi
    private let defaultModelID = "eleven_multilingual_v2"
    
    // Ses önbelleği ve zaman sınırı
    private var audioCache: [String: CachedAudio] = [:]
    private let cacheExpirationHours: TimeInterval = 6 // 6 saat sonra önbellek temizlenecek
    private let maxCacheSize = 10 // Maksimum 10 ses dosyası önbellekte tutulacak
    private var cacheCleaner: Timer?
    
    override init() {
        super.init()
        setupCacheCleaner()
    }
    
    // Önbellek temizleyici zamanlayıcısını kur
    private func setupCacheCleaner() {
        // Her 30 dakikada bir kontrol et
        cacheCleaner = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.cleanExpiredCache()
        }
    }
    
    // Süresi dolmuş önbellek öğelerini temizle
    private func cleanExpiredCache() {
        let now = Date()
        let keysToRemove = audioCache.filter { key, cachedAudio in
            return now.timeIntervalSince(cachedAudio.timestamp) > (cacheExpirationHours * 3600)
        }.keys
        
        for key in keysToRemove {
            audioCache.removeValue(forKey: key)
        }
    }
    
    // Önbellek için benzersiz anahtar oluştur
    private func cacheKey(text: String, voiceID: String) -> String {
        return "\(text)_\(voiceID)"
    }
    
    // Önbellekteki ses verisini getir
    private func getCachedAudio(text: String, voiceID: String) -> Data? {
        let key = cacheKey(text: text, voiceID: voiceID)
        if let cachedAudio = audioCache[key] {
            // Erişildiğinde zaman damgasını güncelle
            audioCache[key] = CachedAudio(
                data: cachedAudio.data,
                timestamp: Date(),
                text: cachedAudio.text,
                voiceID: cachedAudio.voiceID
            )
            return cachedAudio.data
        }
        return nil
    }
    
    // Ses verisini önbelleğe ekle
    private func cacheAudio(text: String, voiceID: String, data: Data) {
        let key = cacheKey(text: text, voiceID: voiceID)
        
        // Önbellek boyutu limitini kontrol et
        if audioCache.count >= maxCacheSize {
            // En eski önbellek öğesini bul ve kaldır
            let oldestKey = audioCache.sorted { $0.value.timestamp < $1.value.timestamp }.first?.key
            if let oldestKey = oldestKey {
                audioCache.removeValue(forKey: oldestKey)
            }
        }
        
        // Yeni veriyi önbelleğe ekle
        audioCache[key] = CachedAudio(
            data: data,
            timestamp: Date(),
            text: text,
            voiceID: voiceID
        )
    }
    
    func convertTextToSpeech(text: String, voiceID: String? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        let actualVoiceID = voiceID ?? defaultVoiceID
        
        // Önbelleği kontrol et
        if let cachedData = getCachedAudio(text: text, voiceID: actualVoiceID) {
            print("Ses önbellekten alındı")
            completion(.success(cachedData))
            return
        }
        
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
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
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
            
            // Başarılı veriyi önbelleğe ekle
            self.cacheAudio(text: text, voiceID: actualVoiceID, data: data)
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    func playAudio(data: Data) throws {
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
        
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    // AVAudioPlayerDelegate metodu - ses çalma tamamlandığında çağrılır
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.audioPlaybackDidFinish()
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
    
    // Önbellek istatistiklerini getir
    func getCacheStats() -> (count: Int, totalSize: Int) {
        let totalSize = audioCache.values.reduce(0) { $0 + $1.data.count }
        return (audioCache.count, totalSize)
    }
    
    // Önbelleği tamamen temizle
    func clearCache() {
        audioCache.removeAll()
    }
    
    deinit {
        cacheCleaner?.invalidate()
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