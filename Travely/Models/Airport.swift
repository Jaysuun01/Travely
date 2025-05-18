import Foundation

struct Airport: Identifiable, Codable {
    let id: String
    let name: String
    let code: String
    let city: String
    let country: String
    
    var displayName: String {
        "\(name) (\(code))"
    }
    
    var fullLocation: String {
        "\(city), \(country)"
    }
}

class AirportSearchManager {
    static let shared = AirportSearchManager()
    private var airports: [Airport] = []
    
    private init() {
        loadAirports()
    }
    
    private func loadAirports() {
        // Load airports from a JSON file or API
        // For now, we'll use a sample list of major airports
        airports = [
            Airport(id: "1", name: "John F. Kennedy International", code: "JFK", city: "New York", country: "USA"),
            Airport(id: "2", name: "Los Angeles International", code: "LAX", city: "Los Angeles", country: "USA"),
            Airport(id: "3", name: "Heathrow", code: "LHR", city: "London", country: "UK"),
            Airport(id: "4", name: "Charles de Gaulle", code: "CDG", city: "Paris", country: "France"),
            Airport(id: "5", name: "Narita International", code: "NRT", city: "Tokyo", country: "Japan"),
            Airport(id: "6", name: "Dubai International", code: "DXB", city: "Dubai", country: "UAE"),
            Airport(id: "7", name: "Singapore Changi", code: "SIN", city: "Singapore", country: "Singapore"),
            Airport(id: "8", name: "Hong Kong International", code: "HKG", city: "Hong Kong", country: "China"),
            Airport(id: "9", name: "Sydney Airport", code: "SYD", city: "Sydney", country: "Australia"),
            Airport(id: "10", name: "San Francisco International", code: "SFO", city: "San Francisco", country: "USA")
        ]
    }
    
    func searchAirports(query: String) -> [Airport] {
        let lowercasedQuery = query.lowercased()
        return airports.filter { airport in
            airport.name.lowercased().contains(lowercasedQuery) ||
            airport.code.lowercased().contains(lowercasedQuery) ||
            airport.city.lowercased().contains(lowercasedQuery) ||
            airport.country.lowercased().contains(lowercasedQuery)
        }
    }
} 