import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TripDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var trip: Trip
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    @State private var showPlacePicker = false
    @State private var showEdit = false
    @State private var showNavigation = false
    @State private var showFlightForm = false
    @State private var selectedTab = 0
    @State private var flights: [Flight] = []
    let isShared: Bool
    private let db = Firestore.firestore()

    func addLocationToTrip(_ location: Location) {
        guard !trip.tripId.isEmpty else { return }
        // Check that startDate is not after endDate
        if location.startDate > location.endDate {
            print("❌ Location start time cannot be after end time.")
            return
        }
        let tripRef = db.collection("trips").document(trip.tripId)
        do {
            let locationWithId = Location(
                id: UUID().uuidString,
                name: location.name,
                startDate: location.startDate,
                endDate: location.endDate,
                transportation: location.transportation,
                coordinates: location.coordinates,
                notes: location.notes,
                createdAt: location.createdAt,
                tripId: trip.tripId
            )
            // Update local state immediately
            trip.locations.append(locationWithId)
            let locationData = try Firestore.Encoder().encode(locationWithId)
            tripRef.updateData([
                "locations": FieldValue.arrayUnion([locationData])
            ]) { error in
                if let error = error {
                    print("Error updating locations: \(error.localizedDescription)")
                }
            }
            // Schedule notification only for the newly added location
            NotificationManager.shared.scheduleLocationNotification(for: locationData, tripName: trip.tripName)
        } catch {
            print("Encoding error: \(error)")
        }
    }
    
    func updateLocation(_ updatedLocation: Location) {
        guard !trip.tripId.isEmpty else { return }
        let tripRef = db.collection("trips").document(trip.tripId)
        
        // Remove old location and add updated one
        if let index = trip.locations.firstIndex(where: { $0.id == updatedLocation.id }) {
            var updatedLocations = trip.locations
            updatedLocations[index] = updatedLocation
            
            do {
                let locationsData = try updatedLocations.map { try Firestore.Encoder().encode($0) }
                tripRef.updateData(["locations": locationsData]) { error in
                    if let error = error {
                        print("Error updating location: \(error.localizedDescription)")
                    } else {
                        // Update local state
                        trip.locations = updatedLocations
                    }
                }
            } catch {
                print("Encoding error: \(error)")
            }
        }
    }
    
    func deleteLocation(_ location: Location) {
        guard !trip.tripId.isEmpty else { return }
        let tripRef = db.collection("trips").document(trip.tripId)
        
        // Remove location from the array
        var updatedLocations = trip.locations
        updatedLocations.removeAll { $0.id == location.id }
        
        do {
            let locationsData = try updatedLocations.map { try Firestore.Encoder().encode($0) }
            tripRef.updateData(["locations": locationsData]) { error in
                if let error = error {
                    print("Error deleting location: \(error.localizedDescription)")
                } else {
                    // Update local state
                    trip.locations = updatedLocations
                    // Remove scheduled notification for this location
                    NotificationManager.shared.removeLocationNotification(locationId: location.id)
                }
            }
        } catch {
            print("Encoding error: \(error)")
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Hero section with image as background, card fully in front
                ZStack(alignment: .top) {
                    // Banner image as background
                    Image(systemName: "airplane")  // Default to airplane icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .foregroundColor(.orange)
                        .opacity(0.5)
                        .background(Color.clear)
                    // Card sits fully in front of the image
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.tripName)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text(trip.destination)
                                    .font(.title3)
                                    .foregroundColor(accentColor)
                            }
                            if isShared {
                                HStack {
                                    Spacer()
                                    Label("Shared", systemImage: "person.2.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(8)
                                }
                            }
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        HStack(spacing: 24) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.startDate, style: .date)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.endDate, style: .date)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        if !trip.notes.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "note.text")
                                    .foregroundColor(.yellow)
                                Text(trip.notes)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(.top, 2)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 8)
                    .padding(.horizontal, 18)
                    .padding(.top, 120)
                }
                .frame(height: 280)
                
                // Orange divider
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 1)
                    .padding(.horizontal)
                    .padding(.top, 40)
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Places").tag(0)
                    Text("Flights").tag(1)
                    Text("Collaborators").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // Places tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(accentColor)
                                    .font(.system(size: 24, weight: .bold))
                                Text("Places to Visit")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(accentColor)
                                    .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 2)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                            .padding(.horizontal, 0)
                            .padding(.bottom, 16)
                            if (trip.locations).isEmpty {
                                VStack {
                                    Text("No places added yet.")
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                ForEach((trip.locations)) { location in
                                    LocationRow(
                                        location: location,
                                        tripName: trip.tripName,
                                        onEdit: updateLocation,
                                        onDelete: deleteLocation
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                } else if selectedTab == 1 {
                    // Flights tab
                    ScrollView {
                        VStack(spacing: 16) {
                            if flights.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "airplane.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No flights added yet")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            } else {
                                ForEach(flights) { flight in
                                    FlightRowView(
                                        flight: flight,
                                        onEdit: { flight in
                                            showFlightForm = true
                                        },
                                        onDelete: { flight in
                                            deleteFlight(flight)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                } else if selectedTab == 2 {
                    // Collaborators tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Collaborators")
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                                .padding(.leading, 8)
                            Divider()
                                .background(Color.orange.opacity(0.5))
                                .padding(.bottom, 8)
                            if !trip.collaborators.isEmpty {
                                ForEach(trip.collaborators, id: \ .self) { email in
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 22))
                                        Text(email)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .padding(.bottom, 6)
                                }
                            }
                            if trip.ownerId == Auth.auth().currentUser?.uid && !trip.pendingInvites.isEmpty {
                                Text("Pending Invites")
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                    .padding(.top, 18)
                                    .padding(.leading, 8)
                                ForEach(trip.pendingInvites, id: \ .self) { email in
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.badge")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 22))
                                        Text(email)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("Pending")
                                            .font(.caption.bold())
                                            .foregroundColor(.yellow)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.yellow.opacity(0.18))
                                            .cornerRadius(8)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(12)
                                    .padding(.bottom, 6)
                                }
                            }
                            if trip.collaborators.isEmpty && (trip.pendingInvites.isEmpty || trip.ownerId != Auth.auth().currentUser?.uid) {
                                Text("No collaborators yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 24)
                                    .padding(.leading, 8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 60)
                    }
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if selectedTab == 0 {
                        Menu {
                            Button(action: { showPlacePicker = true }) {
                                Label("Add Location", systemImage: "plus.app.fill")
                            }
                            Button(action: { showNavigation = true }) {
                                Label("Navigation", systemImage: "map.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(accentColor)
                                .shadow(radius: 6)
                        }
                        .accessibilityLabel("Location Options")
                    } else if selectedTab == 1 {
                        Button(action: { showFlightForm = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(accentColor)
                                .shadow(radius: 6)
                        }
                        .accessibilityLabel("Add Flight")
                    }
                }
                .padding(.trailing, 18)
                .padding(.bottom, 100)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditTripView(trip: trip, onSave: { updatedTrip in
                fetchLatestTrip()
            }, onDelete: { _ in
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showPlacePicker) {
            MapPlacePickerView(selectedLocations: Binding(
                get: { [] },
                set: { newLocations in
                    if let newLocation = newLocations.last {
                        addLocationToTrip(newLocation)
                    }
                }
            ), defaultLocationName: trip.destination)
        }
        .sheet(isPresented: $showNavigation) {
            NavigationStack {
                NavigationMapView(locations: trip.locations)
            }
        }
        .sheet(isPresented: $showFlightForm) {
            FlightFormView(tripId: trip.tripId) { flight in
                if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                    flights[index] = flight
                } else {
                    flights.append(flight)
                }
            }
        }
        .onAppear {
            fetchFlights()
        }
    }
    
    private func fetchFlights() {
        let flightsRef = db.collection("trips").document(trip.tripId).collection("flights")
        
        flightsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching flights: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No flights found")
                return
            }
            
            let fetchedFlights = documents.compactMap { document -> Flight? in
                do {
                    var flight = try document.data(as: Flight.self)
                    return flight
                } catch {
                    print("Error decoding flight: \(error)")
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                self.flights = fetchedFlights.sorted(by: { $0.departureTime < $1.departureTime })
            }
        }
    }
    
    private func deleteFlight(_ flight: Flight) {
        let flightRef = db.collection("trips").document(trip.tripId).collection("flights").document(flight.id)
        
        flightRef.delete { error in
            if let error = error {
                print("Error deleting flight: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.flights.removeAll { $0.id == flight.id }
                }
            }
        }
    }
    
    private func fetchLatestTrip() {
        db.collection("trips").document(trip.tripId).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            do {
                let updatedTrip = try Firestore.Decoder().decode(Trip.self, from: data)
                DispatchQueue.main.async {
                    self.trip = updatedTrip
                }
            } catch {
                print("Error decoding updated trip: \(error)")
            }
        }
    }
}

struct LocationDetailsPopupView: View {
    let location: Location
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Hero Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                            }
                            
                            Text(location.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Time Card
                        VStack(spacing: 24) {
                            timeSection(
                                title: "Start Time",
                                date: location.startDate,
                                iconName: "clock.fill",
                                color: .blue
                            )
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                            
                            timeSection(
                                title: "End Time",
                                date: location.endDate,
                                iconName: "clock.badge.checkmark.fill",
                                color: .blue
                            )
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        // Transportation Card
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(location.transportation.iconColor.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: location.transportation.iconName)
                                    .font(.system(size: 30))
                                    .foregroundColor(location.transportation.iconColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Transportation")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Text(location.transportation.displayName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        // Notes Card (if available)
                        if let notes = location.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 30))
                                        .foregroundColor(.yellow)
                                    Text("Notes")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                
                                Text(notes)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func timeSection(title: String, date: Date, iconName: String, color: Color) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct LocationRow: View {
    let location: Location
    let tripName: String
    @State private var showEditSheet = false
    @State private var showDetailsPopup = false
    var onEdit: (Location) -> Void
    var onDelete: (Location) -> Void
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location name and icon
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Text(location.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            // Details section
            VStack(spacing: 8) {
                // Date and Time
                HStack(spacing: 16) {
                    // Date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text(dateFormatter.string(from: location.startDate))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    // Time
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("\(timeFormatter.string(from: location.startDate)) - \(timeFormatter.string(from: location.endDate))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // Transportation if available
                if !location.transportation.rawValue.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: location.transportation.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(location.transportation.iconColor)
                        Text(location.transportation.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.leading, 36) // Align with the text above
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onTapGesture {
            showEditSheet = true
        }
        .onLongPressGesture(minimumDuration: 0.2, perform: {
            let impact = UIImpactFeedbackGenerator(style: .rigid)
            impact.prepare() // Pre-prepare the haptic for more immediate response
            impact.impactOccurred(intensity: 1.0)
            showDetailsPopup = true
        })
        .sheet(isPresented: $showDetailsPopup) {
            LocationDetailsPopupView(location: location)
        }
        .sheet(isPresented: $showEditSheet) {
            EditLocationView(
                location: location,
                tripId: location.tripId,
                tripName: tripName,
                onSave: onEdit,
                onDelete: onDelete
            )
        }
    }
}

#Preview {
    TripDetailView(trip: Trip(id: "1", tripName: "Sample Trip", destination: "Paris", notes: "Sample notes", startDate: Date(), endDate: Date().addingTimeInterval(86400), ownerId: "user1", collaborators: [], tripId: "1", locations: [], createdAt: Date(), hasPendingWrites: false), isShared: false)
} 