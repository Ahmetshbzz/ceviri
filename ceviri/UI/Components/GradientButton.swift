import SwiftUI

struct GradientButton: View {
    let title: String
    let systemImage: String
    let gradientColors: [Color]
    let action: () -> Void
    let isDisabled: Bool
    
    init(
        title: String,
        systemImage: String,
        gradientColors: [Color] = [.blue, .purple.opacity(0.7)],
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.gradientColors = gradientColors
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Spacer()
                Label {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                Group {
                    if isDisabled {
                        Color.gray
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: isDisabled ? .clear : gradientColors.first?.opacity(0.3) ?? .clear, radius: 5, y: 2)
        }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(
            title: "Çevir",
            systemImage: "arrow.right"
        ) {
            print("Normal buton tıklandı")
        }
        
        GradientButton(
            title: "Devre Dışı Buton",
            systemImage: "xmark",
            isDisabled: true
        ) {
            print("Bu asla çalışmamalı")
        }
        
        GradientButton(
            title: "Özel Renkli Buton",
            systemImage: "star.fill",
            gradientColors: [.orange, .red]
        ) {
            print("Özel renkli buton tıklandı")
        }
    }
    .padding()
} 