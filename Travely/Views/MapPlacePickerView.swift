import SwiftUI
import MapKit

// Make MKMapItem Identifiable for SwiftUI Map annotations
extension MKMapItem: Identifiable {
    public var id: String {
        // Use coordinate and name as unique id
        let lat = placemark.coordinate.latitude
        let lng = placemark.coordinate.longitude
        return "\(lat)-\(lng)-\(name ?? "")"
    }
}

struct MapPlacePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocations: [Location]
    var defaultLocationName: String // Trip destination
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapItems: [MKMapItem] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var countryCode: String? = nil
    @State private var arrowBounce = false
    
    var body: some View {
        VStack {
            // Arrow down indicator at the top middle with animation
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .offset(y: arrowBounce ? 8 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: arrowBounce
                        )
                }
                Spacer()
            }
            HStack {
                ZStack(alignment: .trailing) {
                    TextField("Search for places", text: $searchText, onCommit: search)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            mapItems = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 12)
                    }
                }
                Button(action: search) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Map(coordinateRegion: $region, annotationItems: mapItems, annotationContent: { item in
                MapMarker(coordinate: item.placemark.coordinate, tint: .orange)
            })
            .frame(maxHeight: 350)
            
            if isSearching {
                ProgressView()
            }

            List(mapItems, id: \.self) { item in
                Button(action: {
                    var newLocation = Location(mapItem: item)
                    // Set tripId to match the parent trip if available
                    if let tripId = selectedLocations.first?.tripId, !tripId.isEmpty {
                        newLocation.tripId = tripId
                    }
                    selectedLocations.append(newLocation)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown")
                            .font(.headline)
                        if let address = item.placemark.title {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            setRegionToDestination()
            arrowBounce = true
        }
    }

    func setRegionToDestination() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = defaultLocationName
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let item = response?.mapItems.first {
                let coordinate = item.placemark.coordinate
                // Set a city-level span for zoom (narrow to city)
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
                countryCode = item.placemark.isoCountryCode
            }
        }
    }
    
    func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region // Use current map region as bias
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let items = response?.mapItems {
                mapItems = items // Show all results in the region
            } else {
                mapItems = []
            }
        }
    }
}

struct MapPlacePickerView_Previews: PreviewProvider {
    static var previews: some View {
        MapPlacePickerView(selectedLocations: .constant([]), defaultLocationName: "")
    }
}
