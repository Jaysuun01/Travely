import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    
    // Custom orange color
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    // Sample data
    let trips = [
        Trip(destination: "Los Angeles Trip", date: "January 2023", imageName: "la"),
        Trip(destination: "London Trip", date: "March 2025", imageName: "london"),
        Trip(destination: "France Trip", date: "September 2024", imageName: "france"),
        Trip(destination: "Korea Trip", date: "July 2027", imageName: "korea")
    ]
    
    var body: some View {
        NavigationView {
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
                        LazyVStack(spacing: 12) {
                            ForEach(trips) { trip in
                                NavigationLink(destination: Text(trip.destination)) {
                                    TripCard(trip: trip)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Custom navigation bar
                    CustomNavigationBar()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TripCard: View {
    let trip: Trip
    let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(trip.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.destination)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Text(trip.date)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(accentColor)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    HomeView()
}
