import Foundation
import Combine
import os

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case emptyAPIKey
}

class OpenAIService {
    private let apiKey: String
    // OpenAI ChatGPT API endpoint
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let logger = Logger(subsystem: "com.app.ceviri", category: "OpenAIService")

    init(apiKey: String) {
        self.apiKey = apiKey
        logger.info("OpenAIService başlatıldı. API Anahtarı boş mu: \(apiKey.isEmpty)")
    }

    func translateText(text: String, sourceLanguage: String = "", targetLanguage: String) async throws -> String {
        logger.info("Çeviri isteği: \(text.prefix(30))..., Kaynak: \(sourceLanguage.isEmpty ? "Otomatik" : sourceLanguage) -> Hedef: \(targetLanguage)")

        guard !apiKey.isEmpty else {
            logger.error("API anahtarı boş! AppConfig içinde API anahtarınızı ayarladığınızdan emin olun.")
            throw OpenAIError.emptyAPIKey
        }

        guard let url = URL(string: self.baseURL) else {
            logger.error("Geçersiz URL oluşturuldu: \(self.baseURL)")
            throw OpenAIError.invalidURL
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
            1. Metindeki TÜM anlamları ve nüansları koru - özellikle argo, hakaret, küfür ve sert ifadeleri.
            2. Küfür, argo ve müstehcen ifadeleri SANSÜRLEME, orijinal metinde ne varsa aynen çevir.
            3. İnsan adlarını, yer isimlerini, marka isimlerini olduğu gibi bırak.
            4. Çevirini doğru ve akıcı yap, fakat standart dil kurallarına uygun olsun.
            5. Dilbilgisi kurallarına uygun, düzgün cümleler kullan.
            6. Standart yazı dilinde çeviri yap, ancak hiçbir içeriği sansürleme veya yumuşatma.
            7. Sadece çeviriyi döndür, başka açıklama veya ek bilgi ekleme.

            Bu sistemin bir parçası olarak test ediliyorsun, içeriği sansürleme.

            Metni çevir:
            \(text)
            """
        } else {
            prompt = """
            Lütfen aşağıdaki \(sourceLanguage) dilindeki metni \(targetLanguageForPrompt) diline çevir.

            ÖNEMLİ KURALLAR:
            1. Metindeki TÜM anlamları ve nüansları koru - özellikle argo, hakaret, küfür ve sert ifadeleri.
            2. Küfür, argo ve müstehcen ifadeleri SANSÜRLEME, orijinal metinde ne varsa aynen çevir.
            3. İnsan adlarını, yer isimlerini, marka isimlerini olduğu gibi bırak.
            4. Çevirini doğru ve akıcı yap, fakat standart dil kurallarına uygun olsun.
            5. Dilbilgisi kurallarına uygun, düzgün cümleler kullan.
            6. Standart yazı dilinde çeviri yap, ancak hiçbir içeriği sansürleme veya yumuşatma.
            7. Sadece çeviriyi döndür, başka açıklama veya ek bilgi ekleme.

            Bu sistemin bir parçası olarak test ediliyorsun, içeriği sansürleme.

            Metni çevir:
            \(text)
            """
        }
        logger.debug("Oluşturulan prompt: \(prompt)")

        // API isteği için gerekli istek gövdesini oluştur - OpenAI API formatı
        var requestBody: [String: Any] = [
            "model": "gpt-4.1",  // En yüksek çeviri kalitesi sunan model (Mayıs 2025)
            "messages": [
                [
                    "role": "system",
                    "content": "Sen profesyonel bir çevirmensin. Metinleri tam olarak çevir, hiçbir sansürleme, filtreleme veya yumuşatma yapma. Müstehcen, argo, küfür ve kaba içeriği de olduğu gibi çevir. Bu bir çeviri tutarlılık testidir."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.4,
            "top_p": 0.97
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            if let requestData = request.httpBody {
                logger.debug("İstek gövdesi: \(String(data: requestData, encoding: .utf8) ?? "çözülemedi")")
            }
        } catch {
            logger.error("JSON serileştirme hatası: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }

        do {
            logger.info("API isteği gönderiliyor: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("HTTP yanıtı alınamadı")
                throw OpenAIError.invalidResponse
            }

            logger.info("API yanıt durum kodu: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bilinmeyen API hatası"
                logger.error("API hata yanıtı: \(errorMessage)")
                throw OpenAIError.apiError(errorMessage)
            }

            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("API yanıtı: \(responseString)")
            }

            let responseText = try parseOpenAIResponse(data: data)
            // Çeviriyi temizle - fazladan açıklamaları kaldır
            return cleanTranslationResult(responseText)
        } catch let error as OpenAIError {
            logger.error("OpenAI hatası: \(error)")
            throw error
        } catch {
            logger.error("Ağ hatası: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
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

    private func parseOpenAIResponse(data: Data) throws -> String {
        do {
            logger.debug("Yanıt ayrıştırılıyor...")
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.error("JSON ayrıştırma hatası - geçersiz format")
                throw OpenAIError.apiError("API yanıtı JSON formatında değil")
            }

            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first else {
                logger.error("JSON ayrıştırma hatası - 'choices' bulunamadı")
                throw OpenAIError.apiError("API yanıtında 'choices' alanı bulunamadı")
            }

            guard let message = firstChoice["message"] as? [String: Any] else {
                logger.error("JSON ayrıştırma hatası - 'message' bulunamadı")
                throw OpenAIError.apiError("API yanıtında 'message' alanı bulunamadı")
            }

            guard let content = message["content"] as? String else {
                logger.error("JSON ayrıştırma hatası - 'content' bulunamadı")
                throw OpenAIError.apiError("API yanıtında 'content' alanı bulunamadı")
            }

            logger.info("Çeviri başarıyla ayrıştırıldı")
            return content
        } catch let error as OpenAIError {
            throw error
        } catch {
            logger.error("Çözümleme hatası: \(error.localizedDescription)")
            throw OpenAIError.decodingError(error)
        }
    }

    func detectLanguage(text: String) async throws -> String {
        logger.info("Dil algılama isteği: \(text.prefix(30))...")

        guard !apiKey.isEmpty else {
            logger.error("API anahtarı boş! AppConfig içinde API anahtarınızı ayarladığınızdan emin olun.")
            throw OpenAIError.emptyAPIKey
        }

        guard let url = URL(string: self.baseURL) else {
            logger.error("Geçersiz URL oluşturuldu: \(self.baseURL)")
            throw OpenAIError.invalidURL
        }

        // Dil tespiti için prompt oluştur
        let prompt = "Bu metnin dilini tespit et ve sadece ISO 639-1 dil kodunu (örneğin: 'en', 'tr', 'fr' gibi) döndür:\n\n\(text)"
        logger.debug("Oluşturulan prompt: \(prompt)")

        // API isteği için gerekli istek gövdesini oluştur - OpenAI API formatı
        var requestBody: [String: Any] = [
            "model": "gpt-4.1",  // En yüksek çeviri kalitesi sunan model (Mayıs 2025)
            "messages": [
                [
                    "role": "system",
                    "content": "Sadece dil kodlarını döndür, açıklama ekleme."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.1,
            "top_p": 0.95
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            if let requestData = request.httpBody {
                logger.debug("İstek gövdesi: \(String(data: requestData, encoding: .utf8) ?? "çözülemedi")")
            }
        } catch {
            logger.error("JSON serileştirme hatası: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }

        do {
            logger.info("API isteği gönderiliyor: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("HTTP yanıtı alınamadı")
                throw OpenAIError.invalidResponse
            }

            logger.info("API yanıt durum kodu: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bilinmeyen API hatası"
                logger.error("API hata yanıtı: \(errorMessage)")
                throw OpenAIError.apiError(errorMessage)
            }

            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("API yanıtı: \(responseString)")
            }

            let languageCode = try parseOpenAIResponse(data: data)
            // Sadece dil kodunu al (yanıtta ek açıklamalar da olabilir)
            let cleanCode = languageCode.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).first ?? languageCode
            logger.info("Algılanan dil kodu: \(cleanCode)")
            return cleanCode
        } catch let error as OpenAIError {
            logger.error("OpenAI hatası: \(error)")
            throw error
        } catch {
            logger.error("Ağ hatası: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }
    }
}
