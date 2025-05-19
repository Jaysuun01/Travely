import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

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
    
    var upcomingTrips: [Trip] {
        let now = Date()
        return filteredTrips.filter { $0.endDate >= now && $0.ownerId == Auth.auth().currentUser?.uid }
            .sorted(by: { $0.startDate < $1.startDate })
    }
    var pastTrips: [Trip] {
        let now = Date()
        return filteredTrips.filter { $0.endDate < now && $0.ownerId == Auth.auth().currentUser?.uid }
            .sorted(by: { $0.startDate > $1.startDate })
    }
    var sharedTrips: [Trip] {
        return filteredTrips.filter { $0.ownerId != Auth.auth().currentUser?.uid }
            .sorted(by: { $0.startDate < $1.startDate })
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
                                Text("Your adventures, organized by time and friends")
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
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 44) {
                            // Shared Trips Section
                            if !sharedTrips.isEmpty {
                                VStack(alignment: .leading, spacing: 18) {
                                    SectionHeader(icon: "person.2.fill", title: "Shared Trips", color: .orange)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 18) {
                                            ForEach(sharedTrips, id: \ .tripId) { trip in
                                                NavigationLink(destination: TripDetailView(trip: trip, isShared: true)) {
                                                    ModernTripCard(trip: trip, onDelete: { deleteTrip(trip) }, isShared: true)
                                                        .frame(minWidth: 0, maxWidth: .infinity)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Upcoming Trips Section
                            if !upcomingTrips.isEmpty {
                                VStack(alignment: .leading, spacing: 18) {
                                    SectionHeader(icon: "calendar.badge.clock", title: "Upcoming Trips", color: .blue)
                                    ForEach(upcomingTrips, id: \ .tripId) { trip in
                                        NavigationLink(destination: TripDetailView(trip: trip, isShared: trip.ownerId != Auth.auth().currentUser?.uid)) {
                                            ModernTripCard(trip: trip, onDelete: { deleteTrip(trip) }, isShared: trip.ownerId != Auth.auth().currentUser?.uid)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.opacity)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Past Trips Section
                            if !pastTrips.isEmpty {
                                VStack(alignment: .leading, spacing: 18) {
                                    SectionHeader(icon: "clock.arrow.circlepath", title: "Past Trips", color: .gray)
                                    ForEach(pastTrips, id: \ .tripId) { trip in
                                        NavigationLink(destination: TripDetailView(trip: trip, isShared: trip.ownerId != Auth.auth().currentUser?.uid)) {
                                            ModernTripCard(trip: trip, onDelete: { deleteTrip(trip) }, isShared: trip.ownerId != Auth.auth().currentUser?.uid)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.opacity)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            if upcomingTrips.isEmpty && pastTrips.isEmpty && sharedTrips.isEmpty {
                                VStack {
                                    Text("No trips found. Start planning your next adventure!")
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 40)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 120)
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
        guard let email = Auth.auth().currentUser?.email else { return }
        
        // Use a single listener for both owned and collaborative trips
        let query = db.collection("trips")
            .whereFilter(Filter.orFilter([
                Filter.whereField("ownerId", isEqualTo: uid),
                Filter.whereField("collaborators", arrayContains: email)
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

struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .bold))
                .padding(6)
                .background(color)
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .cornerRadius(12)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ModernTripCard: View {
    let trip: Trip
    let onDelete: () -> Void
    let isShared: Bool
    let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    @State private var showDeleteConfirmation = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                // Solid orange bar
                accentColor
                    .frame(height: 6)
                    .cornerRadius(3)
                    .padding(.bottom, 2)
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "airplane")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .padding(10)
                        .background(accentColor)
                        .cornerRadius(12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.tripName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(trip.destination)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(dateFormatter.string(from: trip.startDate))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: trip.endDate))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(trip.locations.count) Places")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding(18)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .opacity(0.95)
                    .background(Color.white.opacity(0.03))
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
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
            // Shared badge
            if isShared {
                Text("Shared")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .cornerRadius(12)
                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(10)
            }
            // Owner badge
            if trip.ownerId == Auth.auth().currentUser?.uid && !trip.collaborators.isEmpty {
                Text("Owner")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(10)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
