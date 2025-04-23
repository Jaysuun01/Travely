import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var searchText = ""
    @State private var trips: [Trip] = []
    @State private var selectedTrip: Trip?
    @State private var showTripDetail = false
    
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
                    
                    // Trip list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(trips) { trip in
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
                fetchUserTrips()
            }
        }
    }
    func fetchUserTrips() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Fetch owned trips
        db.collection("trips")
            .whereField("ownerId", isEqualTo: uid)
            .getDocuments { snapshot1, _ in

                var ownedTrips: [Trip] = []
                if let docs = snapshot1?.documents {
                    ownedTrips = docs.compactMap { try? $0.data(as: Trip.self) }
                }

                // Fetch collaborator trips
                db.collection("trips")
                    .whereField("collaborators", arrayContains: uid)
                    .getDocuments { snapshot2, _ in

                        var collabTrips: [Trip] = []
                        if let docs = snapshot2?.documents {
                            collabTrips = docs.compactMap { try? $0.data(as: Trip.self) }
                        }

                        // Merge & remove duplicates
                        let combined = Dictionary(grouping: ownedTrips + collabTrips, by: \.tripId)
                            .compactMap { $0.value.first }

                        DispatchQueue.main.async {
                            self.trips = combined.sorted(by: { $0.startDate < $1.startDate })
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
                Text(trip.destination)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
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
    let trip: Trip
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                Image(systemName: trip.systemImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .foregroundColor(.orange)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                
                // Trip Info Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(trip.tripName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(trip.startDate, style: .date)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("End")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(trip.endDate, style: .date)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                
                // Orange divider
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 1)
                    .padding(.horizontal)
                
                // Locations Section
                VStack(alignment: .leading, spacing: 16) {
                    
                    if trip.locations.isEmpty {
                        VStack(spacing: 12) {
                            Text("No places added yet")
                                .foregroundColor(.gray)
                            Text("Click on the \"+\" icon at the bottom right to add locations")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ForEach(trip.locations) { location in
                            LocationRow(location: location)
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LocationRow: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(location.displayDateRange)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }
}


#Preview {
    HomeView()
}
