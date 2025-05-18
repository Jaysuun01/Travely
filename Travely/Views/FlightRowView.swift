import SwiftUI

struct FlightRowView: View {
    let flight: Flight
    var onEdit: (Flight) -> Void
    var onDelete: (Flight) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Flight number and airline
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text("\(flight.airline) \(flight.flightNumber)")
                    .font(.headline)
                Spacer()
                Menu {
                    Button(action: { onEdit(flight) }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { onDelete(flight) }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            
            // Route
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(flight.departureAirport)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(dateFormatter.string(from: flight.departureTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text(flight.arrivalAirport)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(dateFormatter.string(from: flight.arrivalTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Additional info
            if let terminal = flight.terminal, let gate = flight.gate {
                HStack {
                    Label("Terminal \(terminal)", systemImage: "terminal")
                    Text("•")
                    Label("Gate \(gate)", systemImage: "door.left.hand.open")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            if let notes = flight.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 