import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedLanguage: Language
    let languages: [Language]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Picker("Dil Seçin", selection: $selectedLanguage) {
                ForEach(languages) { language in
                    Text(language.name).tag(language)
                }
            }
            .pickerStyle(.menu)
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}

#Preview {
    LanguagePickerView(
        selectedLanguage: .constant(Language(code: "en", name: "İngilizce")),
        languages: [
            Language(code: "en", name: "İngilizce"),
            Language(code: "tr", name: "Türkçe"),
            Language(code: "es", name: "İspanyolca")
        ],
        title: "Hedef Dil"
    )
} 