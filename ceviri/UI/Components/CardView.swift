import SwiftUI

struct CardView<Content: View>: View {
    var title: String?
    let content: Content
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 3
    
    init(title: String? = nil, 
         cornerRadius: CGFloat = 12,
         shadowRadius: CGFloat = 3,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            
            content
                .padding(title == nil ? .all : .horizontal, 16)
                .padding(title == nil ? [] : .bottom, 16)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

struct RoundedBorderModifier: ViewModifier {
    var color: Color = .gray.opacity(0.3)
    var lineWidth: CGFloat = 1
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

extension View {
    func roundedBorder(color: Color = .gray.opacity(0.3), lineWidth: CGFloat = 1, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(RoundedBorderModifier(color: color, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 20) {
        CardView {
            Text("Bu bir başlıksız karttır")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        
        CardView(title: "Kart Başlığı") {
            Text("Bu bir başlıklı karttır")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        
        CardView(title: "Form Elemanı", shadowRadius: 2) {
            VStack {
                TextField("Adınız", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("E-posta", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Gönder") {
                    // Boş
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    .padding()
} 