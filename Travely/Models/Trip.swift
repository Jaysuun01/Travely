
import Foundation

//struct Trip: Identifiable {
//    let id = UUID()
//    let destination: String
//    let date: String
//    let imageName: String
//}

import SwiftUI
import FirebaseFirestore

struct Trip: Identifiable, Codable {
    @DocumentID var id: String? // Firestore doc ID

    var tripName: String
    var destination: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var ownerId: String
    var collaborators: [String]
    var tripId: String
    var locations: [Location] = []
    var createdAt: Date?
    var hasPendingWrites: Bool = false

    // Computed property for display
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }

    var systemImageName: String {
        return "airplane.circle.fill"
    }
    
    enum CodingKeys: String, CodingKey {
        case tripId, tripName, destination, notes, startDate, endDate, ownerId, collaborators, locations, createdAt
    }
}
