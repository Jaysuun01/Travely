import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var searchText = ""
    
    // Custom orange color
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    @State private var trips: [Trip] = []
    
    // Sample data
    /*let trips = [
        Trip(destination: "Los Angeles Trip", date: "January 2023", imageName: "la"),
        Trip(destination: "London Trip", date: "March 2025", imageName: "london"),
        Trip(destination: "France Trip", date: "September 2024", imageName: "france"),
        Trip(destination: "Korea Trip", date: "July 2027", imageName: "korea")
    ]*/
    
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
                                    TripCard(trip: trip)
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
        let db = Firestore.firestore()

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
    }


struct TripCard: View {
    let trip: Trip
    let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 16) {
            Image(trip.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
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
                .foregroundColor(accentColor)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TripDetailView: View {
    let trip: Trip
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(trip.tripName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)

                Text("Destination: \(trip.destination)")
                    .font(.title3)
                    .foregroundColor(.white)

                Text("Start Date: \(trip.startDate.formatted(.dateTime.month().day().year()))")
                    .foregroundColor(.gray)
                Text("End Date: \(trip.endDate.formatted(.dateTime.month().day().year()))")
                    .foregroundColor(.gray)

                Text("Notes:")
                    .font(.headline)
                    .foregroundColor(accentColor)
                Text(trip.notes)
                    .foregroundColor(.white)
                    .padding(.top, 2)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    HomeView()
}
