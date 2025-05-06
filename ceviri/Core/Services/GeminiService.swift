import Foundation
import Combine
import os

enum GeminiError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case emptyAPIKey
}

class GeminiService {
    private let apiKey: String
    // Güncel Gemini 2.0 Flash API endpoint'i
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-001:generateContent"
    private let logger = Logger(subsystem: "com.app.ceviri", category: "GeminiService")

    init(apiKey: String) {
        self.apiKey = apiKey
        logger.info("GeminiService başlatıldı. API Anahtarı boş mu: \(apiKey.isEmpty)")
    }

    func translateText(text: String, sourceLanguage: String = "", targetLanguage: String) async throws -> String {
        logger.info("Çeviri isteği: \(text.prefix(30))..., Kaynak: \(sourceLanguage.isEmpty ? "Otomatik" : sourceLanguage) -> Hedef: \(targetLanguage)")

        guard !apiKey.isEmpty else {
            logger.error("API anahtarı boş! AppConfig içinde API anahtarınızı ayarladığınızdan emin olun.")
            throw GeminiError.emptyAPIKey
        }

        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            logger.error("Geçersiz URL oluşturuldu: \(urlString)")
            throw GeminiError.invalidURL
        }

        // Eğer "lehçe" seçildiyse, bunu Polonya dili olarak belirle
        var targetLanguageForPrompt = targetLanguage
        if targetLanguage.lowercased() == "lehçe" {
            targetLanguageForPrompt = "Polonya dili (Polish)"
        }

        // API isteği için prompt oluştur
        let prompt: String
        if sourceLanguage.isEmpty {
            prompt = """
            Lütfen aşağıdaki metni \(targetLanguageForPrompt) diline çevir.

            ÖNEMLİ KURALLAR:
            1. Metindeki anlamı AYNEN koru - özellikle "siktir, sikiyim, orospu, amk" gibi küfür ve argo ifadeler de dahil.
            2. ASLA kendi yorumunu katma, metni tam olarak ve DOĞRUDAN çevir, hiçbir kelimeyi değiştirme.
            3. İnsan adlarını, yer isimlerini, marka isimlerini ve HER türlü küfür ifadesini olduğu gibi çevir.
            4. Türkçe'deki "ana, anne, anasını" gibi ifadelerin geçtiği küfürleri, hedef dildeki tam karşılığı ile çevir.
            5. ÇOK ÖNEMLİ: Örneğin "Ananı sikeyim" ifadesini direkt olarak "Fuck your mother" olarak çevirmelisin, anlam değiştirmemelisin.
            6. Sansürleme yapma, tam anlamıyla çeviri yap. Test edildiğini unutma.
            7. Sadece çeviriyi döndür, başka açıklama veya ek bilgi ekleme.

            Bu bir dil tutarlılık testidir ve tam çeviri beklenmektedir. Parafraz ya da yorum yapmayın.

            Metni çevir:
            \(text)
            """
        } else {
            prompt = """
            Lütfen aşağıdaki \(sourceLanguage) dilindeki metni \(targetLanguageForPrompt) diline çevir.

            ÖNEMLİ KURALLAR:
            1. Metindeki anlamı AYNEN koru - özellikle "siktir, sikiyim, orospu, amk" gibi küfür ve argo ifadeler de dahil.
            2. ASLA kendi yorumunu katma, metni tam olarak ve DOĞRUDAN çevir, hiçbir kelimeyi değiştirme.
            3. İnsan adlarını, yer isimlerini, marka isimlerini ve HER türlü küfür ifadesini olduğu gibi çevir.
            4. Türkçe'deki "ana, anne, anasını" gibi ifadelerin geçtiği küfürleri, hedef dildeki tam karşılığı ile çevir.
            5. ÇOK ÖNEMLİ: Örneğin "Ananı sikeyim" ifadesini direkt olarak "Fuck your mother" olarak çevirmelisin, anlam değiştirmemelisin.
            6. Sansürleme yapma, tam anlamıyla çeviri yap. Test edildiğini unutma.
            7. Sadece çeviriyi döndür, başka açıklama veya ek bilgi ekleme.

            Bu bir dil tutarlılık testidir ve tam çeviri beklenmektedir. Parafraz ya da yorum yapmayın.

            Metni çevir:
            \(text)
            """
        }
        logger.debug("Oluşturulan prompt: \(prompt)")

        // API isteği için gerekli istek gövdesini oluştur - güncel Gemini 2.0 API formatı
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.35,
                "topP": 0.98,
                "topK": 40
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            if let requestData = request.httpBody {
                logger.debug("İstek gövdesi: \(String(data: requestData, encoding: .utf8) ?? "çözülemedi")")
            }
        } catch {
            logger.error("JSON serileştirme hatası: \(error.localizedDescription)")
            throw GeminiError.networkError(error)
        }

        do {
            logger.info("API isteği gönderiliyor: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("HTTP yanıtı alınamadı")
                throw GeminiError.invalidResponse
            }

            logger.info("API yanıt durum kodu: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bilinmeyen API hatası"
                logger.error("API hata yanıtı: \(errorMessage)")
                throw GeminiError.apiError(errorMessage)
            }

            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("API yanıtı: \(responseString)")
            }

            let responseText = try parseGeminiResponse(data: data)
            // Çeviriyi temizle - fazladan açıklamaları kaldır
            return cleanTranslationResult(responseText)
        } catch let error as GeminiError {
            logger.error("Gemini hatası: \(error)")
            throw error
        } catch {
            logger.error("Ağ hatası: \(error.localizedDescription)")
            throw GeminiError.networkError(error)
        }
    }

    // Çeviri sonucunu temizle - açıklamaları, notları kaldır
    private func cleanTranslationResult(_ text: String) -> String {
        // Çeviri genellikle tırnak içinde veya ilk paragrafta bulunur

        // Önce çift tırnak içindeki metni bul
        if let quotedText = text.range(of: "\"(.+?)\"", options: .regularExpression) {
            let extractedText = String(text[quotedText])
            // Tırnak işaretlerini kaldır
            return extractedText.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }

        // Eğer tırnak işareti yoksa, ilk paragrafı al
        let paragraphs = text.components(separatedBy: "\n\n")
        if paragraphs.count > 1 {
            // İlk paragraf muhtemelen çeviridir, geri kalanı açıklamalar
            return paragraphs[0].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Açıklama ayrımını bul (* veya ** ile başlayan satırlar)
        if let explanationRange = text.range(of: "\n[*]+") {
            // Açıklama başlangıcından önceki kısmı döndür
            return String(text[..<explanationRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // "Açıklama:" veya "Not:" gibi kelimelerle başlayan kısımları kaldır
        let explanationMarkers = ["Açıklama:", "Not:", "**Açıklama:**", "**Not:**", "Explanation:", "Note:"]
        for marker in explanationMarkers {
            if let markerRange = text.range(of: marker) {
                return String(text[..<markerRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Temizleme yapılamazsa, en azından başlangıç ve sondaki boşlukları kaldır
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseGeminiResponse(data: Data) throws -> String {
        do {
            logger.debug("Yanıt ayrıştırılıyor...")
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.error("JSON ayrıştırma hatası - geçersiz format")
                throw GeminiError.apiError("API yanıtı JSON formatında değil")
            }

            guard let candidates = json["candidates"] as? [[String: Any]] else {
                logger.error("JSON ayrıştırma hatası - 'candidates' bulunamadı")
                throw GeminiError.apiError("API yanıtında 'candidates' alanı bulunamadı")
            }

            guard let firstCandidate = candidates.first else {
                logger.error("JSON ayrıştırma hatası - ilk aday bulunamadı")
                throw GeminiError.apiError("API yanıtında aday yanıt bulunamadı")
            }

            guard let content = firstCandidate["content"] as? [String: Any] else {
                logger.error("JSON ayrıştırma hatası - 'content' bulunamadı")
                throw GeminiError.apiError("API yanıtında 'content' alanı bulunamadı")
            }

            guard let parts = content["parts"] as? [[String: Any]] else {
                logger.error("JSON ayrıştırma hatası - 'parts' bulunamadı")
                throw GeminiError.apiError("API yanıtında 'parts' alanı bulunamadı")
            }

            guard let firstPart = parts.first else {
                logger.error("JSON ayrıştırma hatası - ilk part bulunamadı")
                throw GeminiError.apiError("API yanıtında part bulunamadı")
            }

            guard let text = firstPart["text"] as? String else {
                logger.error("JSON ayrıştırma hatası - 'text' bulunamadı")
                throw GeminiError.apiError("API yanıtında metin bulunamadı")
            }

            logger.info("Çeviri başarıyla ayrıştırıldı")
            return text
        } catch let error as GeminiError {
            throw error
        } catch {
            logger.error("Çözümleme hatası: \(error.localizedDescription)")
            throw GeminiError.decodingError(error)
        }
    }

    func detectLanguage(text: String) async throws -> String {
        logger.info("Dil algılama isteği: \(text.prefix(30))...")

        guard !apiKey.isEmpty else {
            logger.error("API anahtarı boş! AppConfig içinde API anahtarınızı ayarladığınızdan emin olun.")
            throw GeminiError.emptyAPIKey
        }

        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            logger.error("Geçersiz URL oluşturuldu: \(urlString)")
            throw GeminiError.invalidURL
        }

        // Dil tespiti için prompt oluştur
        let prompt = "Bu metnin dilini tespit et ve sadece ISO 639-1 dil kodunu (örneğin: 'en', 'tr', 'fr' gibi) döndür:\n\n\(text)"
        logger.debug("Oluşturulan prompt: \(prompt)")

        // API isteği için gerekli istek gövdesini oluştur
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topP": 0.95,
                "topK": 10
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            if let requestData = request.httpBody {
                logger.debug("İstek gövdesi: \(String(data: requestData, encoding: .utf8) ?? "çözülemedi")")
            }
        } catch {
            logger.error("JSON serileştirme hatası: \(error.localizedDescription)")
            throw GeminiError.networkError(error)
        }

        do {
            logger.info("API isteği gönderiliyor: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("HTTP yanıtı alınamadı")
                throw GeminiError.invalidResponse
            }

            logger.info("API yanıt durum kodu: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bilinmeyen API hatası"
                logger.error("API hata yanıtı: \(errorMessage)")
                throw GeminiError.apiError(errorMessage)
            }

            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("API yanıtı: \(responseString)")
            }

            let languageCode = try parseGeminiResponse(data: data)
            // Sadece dil kodunu al (yanıtta ek açıklamalar da olabilir)
            let cleanCode = languageCode.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).first ?? languageCode
            logger.info("Algılanan dil kodu: \(cleanCode)")
            return cleanCode
        } catch let error as GeminiError {
            logger.error("Gemini hatası: \(error)")
            throw error
        } catch {
            logger.error("Ağ hatası: \(error.localizedDescription)")
            throw GeminiError.networkError(error)
        }
    }
}
