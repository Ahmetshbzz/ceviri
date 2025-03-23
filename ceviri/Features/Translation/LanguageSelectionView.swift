import SwiftUI

// Dil seçim görünümü
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: Language
    let languages: [Language]
    var includeAutoDetect: Bool = false
    var title: String = "Dil Seçin"
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if includeAutoDetect {
                    Button {
                        selectedLanguage = Language(code: "auto", name: "Otomatik")
                        dismiss()
                    } label: {
                        HStack {
                            Text("Otomatik")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage.code == "auto" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                ForEach(filteredLanguages) { language in
                    Button {
                        selectedLanguage = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if language.code == selectedLanguage.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .searchable(text: $searchText, prompt: "Dil Ara")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LanguageSelectionView(
        selectedLanguage: .constant(Language(code: "tr", name: "Türkçe")),
        languages: AppConfig.languages
    )
} 