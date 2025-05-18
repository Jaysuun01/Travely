import Foundation
import FirebaseFirestore

struct Flight: Identifiable, Codable {
    var id: String
    var flightNumber: String
    var airline: String
    var departureAirport: String
    var arrivalAirport: String
    var departureTime: Date
    var arrivalTime: Date
    var terminal: String?
    var gate: String?
    var notes: String?
    var tripId: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case flightNumber
        case airline
        case departureAirport
        case arrivalAirport
        case departureTime
        case arrivalTime
        case terminal
        case gate
        case notes
        case tripId
        case createdAt
    }
} 