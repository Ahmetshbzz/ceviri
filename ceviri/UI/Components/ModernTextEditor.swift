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
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6).opacity(0.5)
    }
    
    private var borderColor: Color {
        isFocused ? Color.blue.opacity(0.4) : Color.clear
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: maxHeight)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEditable ? backgroundColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
                        )
                        .shadow(color: isFocused ? Color.blue.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 1)
                )
                .onTapGesture {
                    if isEditable {
                        isFocused = true
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isFocused)
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
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
            
            if isEditable && isFocused && !text.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 16, height: 16)
                            )
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 12)
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
    
    private var areaBackgroundColor: Color {
        if isEditable {
            return colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6).opacity(0.5)
        } else {
            // Çeviri sonucu için biraz daha açık bir arka plan
            return colorScheme == .dark ? 
                Color(UIColor.systemGray5).opacity(0.7) : 
                Color(UIColor.systemGray6).opacity(0.3)
        }
    }
    
    var body: some View {
        ModernTextEditor(
            text: $text,
            placeholder: placeholder,
            isEditable: isEditable,
            maxHeight: maxHeight,
            onCommit: onCommit
        )
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(areaBackgroundColor)
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .frame(height: maxHeight + 16) // Padding için 16 ekliyoruz
    }
}

#Preview {
    VStack(spacing: 30) {
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
            text: .constant("Bu çevrilmiş metin örneğidir. Şimdi arka plan ve kutu eklenmiş görünüm daha iyi."),
            placeholder: "Çeviri burada görünecek",
            isEditable: false,
            maxHeight: 150
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
} 