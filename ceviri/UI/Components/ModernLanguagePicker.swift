import SwiftUI

struct ModernLanguagePicker: View {
    @Binding var selectedLanguage: Language
    let languages: [Language]
    let title: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(selectedLanguage.name)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(languages) { language in
                            Button {
                                selectedLanguage = language
                                withAnimation {
                                    isExpanded = false
                                }
                            } label: {
                                HStack {
                                    Text(language.name)
                                        .font(.subheadline)
                                        .fontWeight(selectedLanguage.code == language.code ? .semibold : .regular)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedLanguage.code == language.code {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    selectedLanguage.code == language.code ? 
                                        Color.blue.opacity(0.1) : 
                                        Color(UIColor.systemBackground)
                                )
                            }
                            
                            if language.code != languages.last?.code {
                                Divider()
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct LanguagePickerPreview: View {
    @State var selectedLanguage = Language(code: "en", name: "İngilizce")
    
    var body: some View {
        VStack {
            ModernLanguagePicker(
                selectedLanguage: $selectedLanguage,
                languages: [
                    Language(code: "tr", name: "Türkçe"),
                    Language(code: "en", name: "İngilizce"),
                    Language(code: "de", name: "Almanca"),
                    Language(code: "fr", name: "Fransızca"),
                    Language(code: "es", name: "İspanyolca")
                ],
                title: "Hedef Dil"
            )
            .padding()
        }
    }
}

#Preview {
    LanguagePickerPreview()
} 