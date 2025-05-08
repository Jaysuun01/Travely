import SwiftUI

enum TransportationType: String, CaseIterable, Identifiable, Codable {
    case walking
    case biking
    case car
    case bus
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .biking: return "Biking"
        case .car: return "Car"
        case .bus: return "Bus"
        }
    }
    
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .biking: return "bicycle"
        case .car: return "car.fill"
        case .bus: return "bus.fill"
        }
    }
    
    // Store the color name which is Codable
    private var colorName: String {
        switch self {
        case .walking: return "blue"
        case .biking: return "green"
        case .car: return "orange"
        case .bus: return "purple"
        }
    }
    
    // Compute the SwiftUI Color when needed
    var iconColor: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }
} 