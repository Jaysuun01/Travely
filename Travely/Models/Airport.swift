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
    private let apiKey: String
    private let baseURL = "https://api.api-ninjas.com/v1/airports"
    
    private init() {
        // Get API key from configuration
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AIRPORT_API_KEY") as? String {
            self.apiKey = apiKey
        } else {
            fatalError("AIRPORT_API_KEY not found in configuration")
        }
    }
    
    func searchAirports(query: String) async throws -> [Airport] {
        // If query is not exactly 3 characters, return empty array
        guard query.count == 3 else { return [] }
        
        // Convert to uppercase for IATA code
        let iataCode = query.uppercased()
        
        // URL encode the query to handle special characters
        guard let encodedQuery = iataCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(baseURL)?iata=\(encodedQuery)"
        print("Requesting URL: \(urlString)") // Debug print
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Error response: \(errorJson)")
                }
                throw URLError(.badServerResponse)
            }
            
            // Print response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            let airportDataArray = try decoder.decode([AirportData].self, from: data)
            
            // Convert the search results to Airport objects
            return airportDataArray.map { airportData in
                Airport(
                    id: airportData.iata,
                    name: airportData.name,
                    code: airportData.iata,
                    city: airportData.city,
                    country: airportData.country
                )
            }
        } catch {
            print("Error fetching airport data: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            throw error
        }
    }
}

// API Response structure for API Ninjas
struct AirportData: Codable {
    let name: String
    let iata: String
    let icao: String?
    let city: String
    let region: String?
    let country: String
    let elevation_ft: Int?
    let latitude: Double?
    let longitude: Double?
    let timezone: String?
} 
