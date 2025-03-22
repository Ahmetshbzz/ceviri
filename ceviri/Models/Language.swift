import Foundation

struct Language: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.code == rhs.code
    }
} 