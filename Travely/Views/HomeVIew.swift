import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var searchText = ""
    @State private var trips: [Trip] = []
    @State private var selectedTrip: Trip?
    @State private var showTripDetail = false
    @State private var isRefreshing = false
    
    // Custom orange color
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    private let db = Firestore.firestore()
    
    var filteredTrips: [Trip] {
        if searchText.isEmpty {
            return trips
        }
        return trips.filter { trip in
            trip.tripName.localizedCaseInsensitiveContains(searchText) ||
            trip.destination.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Trips")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Plan your next adventure")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search trips...", text: $searchText)
                                .foregroundColor(.white)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Orange divider
                    Rectangle()
                        .fill(accentColor)
                        .frame(height: 1)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Trip list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTrips, id: \.tripId) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip, onDelete: { deleteTrip(trip) })
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.opacity)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        isRefreshing = true
                        await refreshTrips()
                        isRefreshing = false
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .bottom)
            .onAppear {
                fetchUserTrips()
            }
        }
    }
    
    @MainActor
    private func refreshTrips() async {
        fetchUserTrips()
    }
    
    func fetchTrips() {
        fetchUserTrips()
    }
    
    func fetchUserTrips() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Use a single listener for both owned and collaborative trips
        let query = db.collection("trips")
            .whereFilter(Filter.orFilter([
                Filter.whereField("ownerId", isEqualTo: uid),
                Filter.whereField("collaborators", arrayContains: uid)
            ]))
        
        query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching trips: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            print("📨 Received \(documents.count) trip docs")
            
            let fetchedTrips = documents.compactMap { document -> Trip? in
                do {
                    var trip = try document.data(as: Trip.self)
                    trip.hasPendingWrites = document.metadata.hasPendingWrites
                    
                    // Validate and fix transportation values
                    trip.locations = trip.locations.map { location in
                        var fixedLocation = location
                        if fixedLocation.transportation.rawValue.isEmpty {
                            fixedLocation.transportation = .walking // Default to walking if empty
                        }
                        return fixedLocation
                    }
                    
                    print("📦 Trip loaded:", trip.tripName, "| tripId:", trip.tripId)
                    return trip
                } catch {
                    print("❌ Trip decode failed for \(document.documentID): \(error)")
                    // Try to recover the trip with default values
                    if let data = try? document.data() {
                        let tripId = document.documentID
                        let tripName = data["tripName"] as? String ?? "Untitled Trip"
                        let destination = data["destination"] as? String ?? ""
                        let notes = data["notes"] as? String ?? ""
                        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                        let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                        let ownerId = data["ownerId"] as? String ?? ""
                        let collaborators = data["collaborators"] as? [String] ?? []
                        let locations = (data["locations"] as? [[String: Any]])?.compactMap { locationData -> Location? in
                            guard let locationId = locationData["id"] as? String,
                                  let name = locationData["name"] as? String,
                                  let startDate = (locationData["startDate"] as? Timestamp)?.dateValue(),
                                  let endDate = (locationData["endDate"] as? Timestamp)?.dateValue(),
                                  let transportationRaw = locationData["transportation"] as? String,
                                  let transportation = TransportationType(rawValue: transportationRaw),
                                  let coordinates = locationData["coordinates"] as? GeoPoint
                            else { return nil }
                            
                            return Location(
                                id: locationId,
                                name: name,
                                startDate: startDate,
                                endDate: endDate,
                                transportation: transportation,
                                coordinates: coordinates,
                                notes: locationData["notes"] as? String,
                                createdAt: (locationData["createdAt"] as? Timestamp)?.dateValue(),
                                tripId: tripId
                            )
                        } ?? []
                        
                        var trip = Trip(
                            id: tripId,
                            tripName: tripName,
                            destination: destination,
                            notes: notes,
                            startDate: startDate,
                            endDate: endDate,
                            ownerId: ownerId,
                            collaborators: collaborators,
                            tripId: tripId,
                            locations: locations,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                            hasPendingWrites: false
                        )
                        trip.hasPendingWrites = document.metadata.hasPendingWrites
                        print("📦 Recovered trip:", trip.tripName, "| tripId:", trip.tripId)
                        return trip
                    }
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                self.trips = fetchedTrips.sorted(by: { $0.startDate < $1.startDate })
                self.isRefreshing = snapshot?.metadata.isFromCache ?? false
            }
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Only allow deletion if user is the owner
        guard trip.ownerId == uid else {
            print("Cannot delete: User is not the owner of this trip")
            return
        }
        
        db.collection("trips").document(trip.tripId).delete { error in
            if let error = error {
                print("Error deleting trip: \(error.localizedDescription)")
            } else {
                // Remove the trip from local array
                DispatchQueue.main.async {
                    self.trips.removeAll { $0.tripId == trip.tripId }
                }
            }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    let onDelete: () -> Void
    let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    @State private var showDeleteConfirmation = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top section with icon and dates
            HStack(alignment: .top, spacing: 16) {
                // Trip icon with gradient background
                Image(systemName: "airplane")  // Default to airplane icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding(12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor.opacity(0.7), accentColor.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Trip name and destination
                    Text(trip.tripName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(trip.destination)
                        .font(.system(size: 15))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                // Dates
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dateFormatter.string(from: trip.startDate))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(dateFormatter.string(from: trip.endDate))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            // Bottom section with places count and arrow
            HStack {
                // Places count
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(trip.locations.count) Places")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Trip", systemImage: "trash")
            }
        }
        .alert("Delete Trip", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
    }
}

struct TripDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var trip: Trip
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    @State private var showPlacePicker = false
    @State private var showEdit = false
    @State private var showNavigation = false
    private let db = Firestore.firestore()

    func addLocationToTrip(_ location: Location) {
        guard !trip.tripId.isEmpty else { return }
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
                }
            }
        } catch {
            print("Encoding error: \(error)")
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
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
                        .padding(.top, 40) // Increased gap above divider
                    // Locations Section
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
                                    onEdit: updateLocation,
                                    onDelete: deleteLocation
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                }
            }
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
                    self.trip = updatedTrip
                }, onDelete: { _ in
                    presentationMode.wrappedValue.dismiss()
                })
            }
            // Floating Add Button always overlays bottom right, above nav bar
            VStack {
                Spacer()
                HStack {
                    Spacer()
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
                    .padding(.trailing, 18)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showPlacePicker) {
            MapPlacePickerView(selectedLocations: Binding(
                get: { [] }, // We don't need to pass existing locations
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
                onSave: onEdit,
                onDelete: onDelete
            )
        }
    }
}

#Preview {
    HomeView()
}
