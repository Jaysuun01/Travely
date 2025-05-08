import Foundation

struct Trip: Identifiable {
    let id = UUID()
    let destination: String
    let date: String
    let imageName: String
}

