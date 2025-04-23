import SwiftUI
import FirebaseFirestore

struct Location: Identifiable, Codable {
    @DocumentID var id: String?
    
    var name: String
    var startDate: Date
    var endDate: Date
    var transportation: String
    var coordinates: GeoPoint
    var notes: String?
    var createdAt: Date?
    var tripId: String
    
    // Computed property for display date range
    var displayDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
