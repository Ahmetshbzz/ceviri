import Foundation

struct AppConfig {
    static let geminiAPIKey = "AIzaSyBiO0aft4Cxtt0tKFFS_GdLDXIQ71tV8MI"
    static let elevenLabsAPIKey = "sk_a7856b10a9a2455aebac7bfe210f139e9bba2c9e01186710"
    
    static var languages: [Language] = [
        Language(code: "en", name: "İngilizce"),
        Language(code: "tr", name: "Türkçe"),
        Language(code: "pl", name: "lehçe"),
        Language(code: "fr", name: "Fransızca"),
        Language(code: "de", name: "Almanca"),
        Language(code: "it", name: "İtalyanca"),
        Language(code: "ru", name: "Rusça"),
        Language(code: "zh", name: "Çince"),
        Language(code: "ja", name: "Japonca"),
        Language(code: "ar", name: "Arapça"),
        Language(code: "pt", name: "Portekizce"),
        Language(code: "ko", name: "Korece"),
        Language(code: "es", name: "ispanyolca")
    ]
} 
