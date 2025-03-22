import SwiftUI

struct ActionButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void
    
    init(
        title: String,
        systemImage: String,
        backgroundColor: Color = .blue.opacity(0.1),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: systemImage)
                    .font(.subheadline)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(.primary)
            .cornerRadius(10)
        }
    }
}

struct ActionIconButton: View {
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void
    
    init(
        systemImage: String,
        backgroundColor: Color = .blue.opacity(0.1),
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ActionButton(
            title: "Kopyala",
            systemImage: "doc.on.doc",
            backgroundColor: Color.green.opacity(0.15)
        ) {
            print("Kopyala tıklandı")
        }
        
        ActionButton(
            title: "Paylaş",
            systemImage: "square.and.arrow.up",
            backgroundColor: Color.blue.opacity(0.15)
        ) {
            print("Paylaş tıklandı")
        }
        
        HStack(spacing: 12) {
            ActionIconButton(
                systemImage: "arrow.left.arrow.right",
                backgroundColor: Color.orange.opacity(0.15)
            ) {
                print("İkon butonu tıklandı")
            }
            
            ActionIconButton(
                systemImage: "arrow.up.arrow.down",
                backgroundColor: Color.purple.opacity(0.15)
            ) {
                print("İkon butonu tıklandı")
            }
        }
    }
    .padding()
} 