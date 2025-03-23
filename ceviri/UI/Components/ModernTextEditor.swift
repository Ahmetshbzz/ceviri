import SwiftUI

struct ModernTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let isEditable: Bool
    let maxHeight: CGFloat
    var onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .disabled(!isEditable)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(size: 16))
                .fontWeight(.regular)
                .tint(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(height: maxHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                )
                .onTapGesture {
                    if isEditable {
                        isFocused = true
                    }
                }
                .onChange(of: text) { oldValue, newValue in
                    // Enter tuşuna basıldığında işlem yap
                    if newValue.contains("\n") && isEditable && onCommit != nil {
                        let lastChar = newValue.last
                        text = String(newValue.dropLast())
                        
                        if lastChar == "\n" {
                            isFocused = false
                            onCommit?()
                        }
                    }
                }
            
            if text.isEmpty {
                // Boş placeholder
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .allowsHitTesting(false)
            }
            
            if isEditable && !text.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// Çeviri ekranı için özel style'lı bir metin düzenleyici varyasyonu
struct TranslateAreaTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let isEditable: Bool
    let maxHeight: CGFloat
    var onCommit: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        if isEditable {
            return colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
        } else {
            return colorScheme == .dark ? 
                Color(UIColor.systemGray6) : 
                Color(UIColor.systemGray6).opacity(0.3)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !text.isEmpty && !isEditable {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
            }
            
            ModernTextEditor(
                text: $text,
                placeholder: placeholder,
                isEditable: isEditable,
                maxHeight: maxHeight,
                onCommit: onCommit
            )
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
        }
        .frame(height: maxHeight + 28) // Padding ve etiket için fazladan alan
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernTextEditor(
            text: .constant(""),
            placeholder: "Bir şeyler yazın...",
            isEditable: true,
            maxHeight: 150
        )
        
        ModernTextEditor(
            text: .constant("Bu bir örnek metin içeriğidir. Minimalist tasarım ve modern görünüm ile kullanıcı deneyimi iyileştirildi."),
            placeholder: "Örnek",
            isEditable: false,
            maxHeight: 150
        )
        
        TranslateAreaTextEditor(
            text: .constant(""),
            placeholder: "Çevrilecek metni girin",
            isEditable: true,
            maxHeight: 150
        )
        
        TranslateAreaTextEditor(
            text: .constant("Bu çevrilmiş metin örneğidir."),
            placeholder: "Çeviri burada görünecek",
            isEditable: false,
            maxHeight: 150
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
} 