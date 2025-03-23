import Foundation
import AVFoundation

protocol ElevenLabsPlayerDelegate: AnyObject {
    func audioPlaybackDidFinish()
}

// Önbellekteki ses verileri için model
struct CachedAudio: Codable {
    let timestamp: Date
    let text: String
    let voiceID: String
    var filename: String // Disk üzerindeki dosya adı
}

class ElevenLabsService: NSObject, AVAudioPlayerDelegate {
    private let apiKey = AppConfig.elevenLabsAPIKey
    private let baseURL = "https://api.elevenlabs.io/v1"
    private var audioPlayer: AVAudioPlayer?
    
    weak var delegate: ElevenLabsPlayerDelegate?
    
    // Varsayılan ses modeli ID'leri
    private let defaultVoiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel - Doğal kadın sesi
    private let defaultModelID = "eleven_multilingual_v2"
    
    // Ses önbelleği ve zaman sınırı
    private var audioCache: [String: CachedAudio] = [:]
    private let cacheExpirationHours: TimeInterval = 24 // 24 saat sonra önbellek temizlenecek
    private var cacheCleaner: Timer?
    
    // Önbellek için dosya sistemi yolları ve meta veri anahtarı
    private let cacheFolderName = "ElevenLabsCache"
    private let cacheMetadataFilename = "cache_metadata.json"
    
    override init() {
        super.init()
        
        // Önbellek klasörünü oluştur (yoksa)
        createCacheDirectory()
        
        // Önbellek meta verilerini disk üzerinden yükle
        loadCacheMetadata()
        
        setupCacheCleaner()
    }
    
    // Önbellek klasörünün yolunu al
    private func getCacheDirectoryURL() -> URL {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent(cacheFolderName, isDirectory: true)
    }
    
    // Önbellek klasörünü oluştur
    private func createCacheDirectory() {
        let fileManager = FileManager.default
        let cacheDir = getCacheDirectoryURL()
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            do {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            } catch {
                print("Önbellek klasörü oluşturulamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Önbellek meta verilerini disk üzerinden yükle
    private func loadCacheMetadata() {
        let fileManager = FileManager.default
        let metadataURL = getCacheDirectoryURL().appendingPathComponent(cacheMetadataFilename)
        
        if fileManager.fileExists(atPath: metadataURL.path) {
            do {
                let data = try Data(contentsOf: metadataURL)
                let metadata = try JSONDecoder().decode([String: CachedAudio].self, from: data)
                
                // Önbelleğe yükle ve dosya varlığını kontrol et
                for (key, cachedAudio) in metadata {
                    let audioFileURL = getCacheDirectoryURL().appendingPathComponent(cachedAudio.filename)
                    
                    // Eğer ses dosyası diskten silinmişse, meta veriden de kaldır
                    if fileManager.fileExists(atPath: audioFileURL.path) {
                        audioCache[key] = cachedAudio
                    }
                }
                
                print("Önbellek meta verileri yüklendi: \(audioCache.count) öğe")
                
                // Süresi dolmuş önbellek öğelerini temizle
                cleanExpiredCache()
            } catch {
                print("Önbellek meta verileri yüklenemedi: \(error.localizedDescription)")
                audioCache = [:]
            }
        }
    }
    
    // Önbellek meta verilerini diske kaydet
    private func saveCacheMetadata() {
        do {
            let metadataURL = getCacheDirectoryURL().appendingPathComponent(cacheMetadataFilename)
            let data = try JSONEncoder().encode(audioCache)
            try data.write(to: metadataURL)
        } catch {
            print("Önbellek meta verileri kaydedilemedi: \(error.localizedDescription)")
        }
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
        let fileManager = FileManager.default
        let keysToRemove = audioCache.filter { key, cachedAudio in
            return now.timeIntervalSince(cachedAudio.timestamp) > (cacheExpirationHours * 3600)
        }
        
        for (key, cachedAudio) in keysToRemove {
            // Meta veriden kaldır
            audioCache.removeValue(forKey: key)
            
            // Diskten dosyayı sil
            let audioFileURL = getCacheDirectoryURL().appendingPathComponent(cachedAudio.filename)
            do {
                if fileManager.fileExists(atPath: audioFileURL.path) {
                    try fileManager.removeItem(at: audioFileURL)
                }
            } catch {
                print("Önbellek dosyası silinemedi: \(error.localizedDescription)")
            }
        }
        
        // Meta verileri güncelle
        if !keysToRemove.isEmpty {
            saveCacheMetadata()
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
                timestamp: Date(),
                text: cachedAudio.text,
                voiceID: cachedAudio.voiceID,
                filename: cachedAudio.filename
            )
            saveCacheMetadata()
            
            // Diskten ses dosyasını oku
            let audioFileURL = getCacheDirectoryURL().appendingPathComponent(cachedAudio.filename)
            do {
                return try Data(contentsOf: audioFileURL)
            } catch {
                // Dosya okunamazsa önbellekten kaldır
                audioCache.removeValue(forKey: key)
                saveCacheMetadata()
                print("Önbellek dosyası okunamadı: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    // Ses verisini önbelleğe ekle
    private func cacheAudio(text: String, voiceID: String, data: Data) {
        let key = cacheKey(text: text, voiceID: voiceID)
        
        // Yeni ses dosyasını benzersiz bir isimle kaydet
        let filename = "\(UUID().uuidString).audio"
        let fileURL = getCacheDirectoryURL().appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            
            // Meta verileri güncelle
            let newCachedAudio = CachedAudio(
                timestamp: Date(),
                text: text,
                voiceID: voiceID,
                filename: filename
            )
            
            audioCache[key] = newCachedAudio
            saveCacheMetadata()
        } catch {
            print("Ses dosyası önbelleğe kaydedilemedi: \(error.localizedDescription)")
        }
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
        audioPlayer?.rate = 0.85 // Ses hızını biraz daha yavaşlat (normal hız 1.0)
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
    func getCacheStats() -> (count: Int, totalSizeInBytes: Int) {
        let fileManager = FileManager.default
        let cacheDir = getCacheDirectoryURL()
        
        var totalSizeInBytes = 0
        
        do {
            // Ses dosyaları için toplam boyutu hesapla (meta veri dosyası hariç)
            let fileUrls = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])
            
            for fileUrl in fileUrls where fileUrl.lastPathComponent != cacheMetadataFilename {
                let attributes = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
                if let size = attributes.fileSize {
                    totalSizeInBytes += size
                }
            }
        } catch {
            print("Önbellek boyutu hesaplanamadı: \(error.localizedDescription)")
        }
        
        return (audioCache.count, totalSizeInBytes)
    }
    
    // Önbelleği tamamen temizle
    func clearCache() {
        let fileManager = FileManager.default
        let cacheDir = getCacheDirectoryURL()
        
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
            
            for fileUrl in fileUrls {
                try fileManager.removeItem(at: fileUrl)
            }
            
            audioCache.removeAll()
            saveCacheMetadata() // Boş meta veriyi kaydet
            
            print("Önbellek temizlendi")
        } catch {
            print("Önbellek temizlenirken hata oluştu: \(error.localizedDescription)")
        }
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