import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var searchText = ""
    @State private var trips: [Trip] = []
    @State private var selectedTrip: Trip?
    @State private var showTripDetail = false
    @State private var isLoadingFromServer = true
    
    // Custom orange color
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    private let db = Firestore.firestore()
    
    func fetchTrips() {
        fetchUserTrips()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Planned trips", text: $searchText)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Orange divider
                    Rectangle()
                        .fill(accentColor)
                        .frame(height: 1)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    if isLoadingFromServer {
                        ProgressView("Loading trips...")
                            .padding()
                    }
                    
                    // Trip list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(trips, id: \.tripId) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip, onDelete: { deleteTrip(trip) })
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if self.isLoadingFromServer {
                        self.isLoadingFromServer = false
                    }
                }
                // Cach documents in case firestore fails to stream
                guard let uid = Auth.auth().currentUser?.uid else {return}
                
                fetchUserTrips()
            }
        }
    }
    func fetchUserTrips() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("trips")
        .whereField("ownerId", isEqualTo: uid)
        .getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                let _ = docs.map { $0.data() } // Forces caching of the doc
            }
        }

        // Listen for trips the user owns
        db.collection("trips")
        .whereField("ownerId", isEqualTo: uid)
        .addSnapshotListener { snapshot1, error in
            var ownedTrips: [Trip] = []
            if let docs = snapshot1?.documents {
                print("📨 Received \(docs.count) owned trip docs")
                ownedTrips = docs.compactMap {
                    do {
                        var trip = try $0.data(as: Trip.self)
                        trip.hasPendingWrites = $0.metadata.hasPendingWrites
                        print("📦 Trip loaded:", trip.tripName, "| tripId:", trip.tripId)
                        return trip
                    } catch {
                        print("❌ Trip decode failed for \( $0.documentID ): \(error)")
                        return nil
                    }
                }
            }

            // Listen for trips where user is a collaborator
            db.collection("trips")
            .whereField("collaborators", arrayContains: uid)
            .addSnapshotListener { snapshot2, error in
                var collabTrips: [Trip] = []
                if let docs = snapshot2?.documents {
                    print("📨 Received \(docs.count) collab trip docs")
                    collabTrips = docs.compactMap {
                        do {
                            var trip = try $0.data(as: Trip.self)
                            trip.hasPendingWrites = $0.metadata.hasPendingWrites
                            print("📦 Trip loaded:", trip.tripName, "| tripId:", trip.tripId)
                            return trip
                        } catch {
                            print("❌ Trip decode failed for \( $0.documentID ): \(error)")
                            return nil
                        }
                    }
                }

                // Merge owned + collab trips, removing duplicates
                let combined = Dictionary(grouping: ownedTrips + collabTrips, by: \.tripId)
                    .compactMap { $0.value.first }

                DispatchQueue.main.async {
                    self.trips = combined.sorted(by: { $0.startDate < $1.startDate })

                    // ✅ This safely disables loading once any data arrives
                    let fromCache1 = snapshot1?.metadata.isFromCache ?? false
                    let fromCache2 = snapshot2?.metadata.isFromCache ?? false
                    let hadData = !ownedTrips.isEmpty || !collabTrips.isEmpty

                    self.isLoadingFromServer = fromCache1 || fromCache2
                    if hadData || (!fromCache1 && !fromCache2) {
                        self.isLoadingFromServer = false
                    }
                }
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
        HStack(spacing: 16) {
            Image(systemName: trip.systemImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.orange)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.destination)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    if trip.hasPendingWrites {
                        Text("Saved offline")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                Text(dateFormatter.string(from: trip.startDate))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                Text(dateFormatter.string(from: trip.endDate))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Trip", systemImage: "trash")
            }
        }
    }
}

struct TripDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var trip: Trip
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    @State private var showPlacePicker = false
    @State private var addedLocations: [Location] = []
    @State private var showEdit = false
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
                        Image(systemName: trip.systemImageName)
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
                        if (trip.locations + addedLocations).isEmpty {
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
                        Image(systemName: "pencil")
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
                    Button(action: { showPlacePicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(accentColor)
                            .shadow(radius: 6)
                    }
                    .accessibilityLabel("Add Place")
                    .padding(.trailing, 18)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showPlacePicker) {
            MapPlacePickerView(selectedLocations: Binding(
                get: { addedLocations },
                set: { newLocations in
                    // Find the newly added location
                    if let newLocation = newLocations.last, !addedLocations.contains(where: { $0.id == newLocation.id }) {
                        addedLocations.append(newLocation)
                        addLocationToTrip(newLocation)
                    }
                }
            ), defaultLocationName: trip.destination)
        }
    }
}

struct LocationRow: View {
    let location: Location
    @State private var showEditSheet = false
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
                if !location.transportation.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        Text(location.transportation)
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
