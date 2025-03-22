import SwiftUI

struct ModernTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let isEditable: Bool
    let maxHeight: CGFloat
    var onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .disabled(!isEditable)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .cornerRadius(10)
                .fontWeight(.regular)
                .padding(2)
                .frame(minHeight: 80, maxHeight: maxHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
                Text(placeholder)
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(.horizontal, 5)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
            
            if isEditable && !text.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(8)
                        }
                        .offset(x: 4, y: -4)
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernTextEditor(
            text: .constant(""),
            placeholder: "Düzenlenebilir metin editörü örneği",
            isEditable: true,
            maxHeight: 150
        )
        
        ModernTextEditor(
            text: .constant("Bu sadece okunabilir bir metin editörüdür ve buradaki metni değiştiremezsiniz."),
            placeholder: "Sadece okunabilir metin editörü",
            isEditable: false,
            maxHeight: 150
        )
    }
    .padding()
} 