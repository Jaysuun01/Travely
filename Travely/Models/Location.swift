import SwiftUI
import FirebaseFirestore
import MapKit

struct Location: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    
    var name: String
    var startDate: Date
    var endDate: Date
    var transportation: TransportationType
    var coordinates: GeoPoint
    var notes: String?
    var createdAt: Date?
    var tripId: String
    var reminderOffset: TimeInterval? // seconds before startDate, nil = no reminder
    
    // Computed property for display date range
    var displayDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate
        case endDate
        case transportation
        case coordinates
        case notes
        case createdAt
        case tripId
        case reminderOffset
    }
}

// Add initializer for MKMapItem
extension Location {
    init(mapItem: MKMapItem) {
        self.id = UUID().uuidString
        self.name = mapItem.name ?? "Unknown"
        self.startDate = Date() // Default to now, or customize as needed
        self.endDate = Date()   // Default to now, or customize as needed
        self.transportation = .car // Default to car
        self.coordinates = GeoPoint(latitude: mapItem.placemark.coordinate.latitude, longitude: mapItem.placemark.coordinate.longitude)
        self.notes = nil
        self.createdAt = Date()
        self.tripId = ""
    }
}
