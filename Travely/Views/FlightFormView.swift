import SwiftUI
import FirebaseFirestore

struct FlightFormView: View {
    @Environment(\.presentationMode) var presentationMode
    let tripId: String
    var existingFlight: Flight?
    var onSave: (Flight) -> Void
    
    @State private var flightNumber = ""
    @State private var airline = ""
    @State private var departureAirport = ""
    @State private var arrivalAirport = ""
    @State private var departureTime = Date()
    @State private var arrivalTime = Date()
    @State private var terminal = ""
    @State private var gate = ""
    @State private var notes = ""
    
    @State private var showingDepartureSearch = false
    @State private var showingArrivalSearch = false
    @State private var departureSearchText = ""
    @State private var arrivalSearchText = ""
    @State private var selectedDepartureAirport: Airport?
    @State private var selectedArrivalAirport: Airport?
    
    private let db = Firestore.firestore()
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    init(tripId: String, existingFlight: Flight? = nil, onSave: @escaping (Flight) -> Void) {
        self.tripId = tripId
        self.existingFlight = existingFlight
        self.onSave = onSave
        
        if let flight = existingFlight {
            _flightNumber = State(initialValue: flight.flightNumber)
            _airline = State(initialValue: flight.airline)
            _departureAirport = State(initialValue: flight.departureAirport)
            _arrivalAirport = State(initialValue: flight.arrivalAirport)
            _departureTime = State(initialValue: flight.departureTime)
            _arrivalTime = State(initialValue: flight.arrivalTime)
            _terminal = State(initialValue: flight.terminal ?? "")
            _gate = State(initialValue: flight.gate ?? "")
            _notes = State(initialValue: flight.notes ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Flight Information Card
                        VStack(spacing: 20) {
                            // Flight Number and Airline
                            HStack(spacing: 16) {
                                Image(systemName: "airplane.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    TextField("Flight Number", text: $flightNumber)
                                        .textFieldStyle(CustomTextFieldStyle())
                                    TextField("Airline", text: $airline)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                            
                            // Airports
                            VStack(spacing: 16) {
                                // Departure Airport
                                Button(action: { showingDepartureSearch = true }) {
                                    HStack {
                                        Image(systemName: "airplane.departure")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text("From")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text(selectedDepartureAirport?.displayName ?? "Select Departure Airport")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                                
                                // Arrival Airport
                                Button(action: { showingArrivalSearch = true }) {
                                    HStack {
                                        Image(systemName: "airplane.arrival")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading) {
                                            Text("To")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text(selectedArrivalAirport?.displayName ?? "Select Arrival Airport")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        
                        // Schedule Card
                        VStack(spacing: 20) {
                            Text("Schedule")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Departure Time
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                DatePicker("Departure", selection: $departureTime)
                                    .datePickerStyle(.compact)
                                    .foregroundColor(.white)
                            }
                            
                            // Arrival Time
                            HStack {
                                Image(systemName: "clock.badge.checkmark.fill")
                                    .foregroundColor(.green)
                                DatePicker("Arrival", selection: $arrivalTime)
                                    .datePickerStyle(.compact)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        
                        // Additional Information Card
                        VStack(spacing: 20) {
                            Text("Additional Information")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Terminal and Gate
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Terminal")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("Terminal", text: $terminal)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Gate")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("Gate", text: $gate)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                            
                            // Notes
                            VStack(alignment: .leading) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("Add notes...", text: $notes)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationTitle(existingFlight == nil ? "Add Flight" : "Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFlight()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? accentColor : .gray)
                }
            }
            .sheet(isPresented: $showingDepartureSearch) {
                AirportSearchView(searchText: $departureSearchText, selectedAirport: $selectedDepartureAirport)
            }
            .sheet(isPresented: $showingArrivalSearch) {
                AirportSearchView(searchText: $arrivalSearchText, selectedAirport: $selectedArrivalAirport)
            }
        }
    }
    
    private var isFormValid: Bool {
        !flightNumber.isEmpty &&
        !airline.isEmpty &&
        selectedDepartureAirport != nil &&
        selectedArrivalAirport != nil
    }
    
    private func saveFlight() {
        guard let departure = selectedDepartureAirport,
              let arrival = selectedArrivalAirport else { return }
        
        let flight = Flight(
            id: existingFlight?.id ?? UUID().uuidString,
            flightNumber: flightNumber,
            airline: airline,
            departureAirport: departure.displayName,
            arrivalAirport: arrival.displayName,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            terminal: terminal.isEmpty ? nil : terminal,
            gate: gate.isEmpty ? nil : gate,
            notes: notes.isEmpty ? nil : notes,
            tripId: tripId,
            createdAt: existingFlight?.createdAt ?? Date()
        )
        
        do {
            let flightData = try Firestore.Encoder().encode(flight)
            let flightRef = db.collection("trips").document(tripId).collection("flights").document(flight.id)
            
            flightRef.setData(flightData) { error in
                if let error = error {
                    print("Error saving flight: \(error.localizedDescription)")
                } else {
                    onSave(flight)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            print("Error encoding flight: \(error)")
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

struct AirportSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var searchText: String
    @Binding var selectedAirport: Airport?
    @State private var searchResults: [Airport] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search airports...", text: $searchText)
                            .foregroundColor(.white)
                            .onChange(of: searchText) { newValue in
                                searchResults = AirportSearchManager.shared.searchAirports(query: newValue)
                            }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding()
                    
                    // Results list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { airport in
                                Button(action: {
                                    selectedAirport = airport
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(airport.displayName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(airport.fullLocation)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.05))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Airport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
} 