import SwiftUI

struct TranslationTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let isEditable: Bool
    let maxHeight: CGFloat
    
    @State private var textEditorHeight: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .disabled(!isEditable)
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .frame(minHeight: 100, maxHeight: maxHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 19)
            }
        }
    }
}

#Preview {
    VStack {
        TranslationTextEditor(
            text: .constant(""), 
            placeholder: "Çevrilecek metni girin", 
            isEditable: true, 
            maxHeight: 200
        )
        
        TranslationTextEditor(
            text: .constant("Bu bir örnek çevirdir."), 
            placeholder: "Çevrilecek metni girin", 
            isEditable: false, 
            maxHeight: 200
        )
    }
    .padding()
} 