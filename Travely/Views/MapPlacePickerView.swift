import SwiftUI
import MapKit

// Corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

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
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF view
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapItems: [MKMapItem] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var countryCode: String? = nil
    @State private var arrowBounce = false
    @State private var selectedMapItem: MKMapItem?
    @State private var showLocationDetails = false
    @State private var listOffset: CGFloat = 350
    @State private var isDragging = false
    @State private var startOffset: CGFloat = 350
    @State private var scrollOffset: CGFloat = 0
    
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    private let minimizedHeight: CGFloat = 60 // Height when minimized
    
    private var headerHeight: CGFloat { 60 } // Height of the header section
    
    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.bottom, 10)
            
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
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, annotationItems: mapItems, annotationContent: { item in
                    MapMarker(coordinate: item.placemark.coordinate, tint: .orange)
                })
                .frame(maxHeight: .infinity)
                
                if isSearching {
                    ProgressView()
                }
                
                // Search results at the bottom
                if !mapItems.isEmpty {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Drag indicator
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 4)
                                .cornerRadius(2)
                                .padding(.vertical, 8)
                            
                            // Header
                            HStack {
                                Text("Search Results")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(mapItems.count) locations")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            
                            // Results list
                            ScrollView(showsIndicators: false) {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: proxy.frame(in: .named("scroll")).minY
                                    )
                                }
                                .frame(height: 0)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(mapItems, id: \.self) { item in
                                        Button(action: {
                                            zoomToLocation(item.placemark.coordinate)
                                            selectedMapItem = item
                                            showLocationDetails = true
                                        }) {
                                            HStack(alignment: .top, spacing: 12) {
                                                // Location icon
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(white: 0.15))
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(Color(red: 0.97, green: 0.44, blue: 0.11))
                                                }
                                                .padding(.top, 2)
                                                
                                                // Location details
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(item.name ?? "Unknown")
                                                        .font(.system(size: 17, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.leading)
                                                    
                                                    if let address = item.placemark.title {
                                                        Text(address)
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.gray)
                                                            .lineLimit(2)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.gray)
                                                    .padding(.top, 4)
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(white: 0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(white: 0.2), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                                scrollOffset = offset
                                if !isDragging && listOffset > 0 {
                                    let threshold: CGFloat = -50
                                    if offset < threshold {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            listOffset = 0
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height)
                        .background(Color.black)
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                        .offset(y: max(0, min(geometry.size.height - minimizedHeight, listOffset)))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        startOffset = listOffset
                                    }
                                    let translation = value.translation.height
                                    let proposedOffset = startOffset + translation
                                    
                                    // Add resistance when pulling beyond bounds
                                    if proposedOffset < 0 {
                                        listOffset = proposedOffset / 3
                                    } else if proposedOffset > geometry.size.height - minimizedHeight {
                                        let excess = proposedOffset - (geometry.size.height - minimizedHeight)
                                        listOffset = (geometry.size.height - minimizedHeight) + (excess / 3)
                                    } else {
                                        listOffset = proposedOffset
                                    }
                                }
                                .onEnded { value in
                                    isDragging = false
                                    let velocity = value.predictedEndTranslation.height / max(1, abs(value.translation.height))
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.5)) {
                                        if listOffset < geometry.size.height / 3 { // Upper third - expand fully
                                            listOffset = 0
                                        } else if listOffset > geometry.size.height - (minimizedHeight + 50) { // Near bottom - minimize
                                            listOffset = geometry.size.height - minimizedHeight
                                        } else { // Middle - default height
                                            listOffset = geometry.size.height - minHeight
                                        }
                                    }
                                }
                        )
                    }
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            setRegionToDestination()
            arrowBounce = true
        }
        .sheet(isPresented: $showLocationDetails) {
            if let item = selectedMapItem {
                LocationDetailsView(
                    mapItem: item,
                    tripId: selectedLocations.first?.tripId ?? "",
                    onSave: { location in
                        selectedLocations.append(location)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
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
                mapItems = items
                
                // Calculate the region that contains all locations
                if !items.isEmpty {
                    var minLat = items[0].placemark.coordinate.latitude
                    var maxLat = minLat
                    var minLon = items[0].placemark.coordinate.longitude
                    var maxLon = minLon
                    
                    // Find the bounding box for all locations
                    for item in items {
                        let coord = item.placemark.coordinate
                        minLat = min(minLat, coord.latitude)
                        maxLat = max(maxLat, coord.latitude)
                        minLon = min(minLon, coord.longitude)
                        maxLon = max(maxLon, coord.longitude)
                    }
                    
                    // Add padding to the region
                    let latPadding = (maxLat - minLat) * 0.3
                    let lonPadding = (maxLon - minLon) * 0.3
                    
                    let center = CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    )
                    
                    let span = MKCoordinateSpan(
                        latitudeDelta: max(0.01, (maxLat - minLat) + latPadding),
                        longitudeDelta: max(0.01, (maxLon - minLon) + lonPadding)
                    )
                    
                    withAnimation {
                        region = MKCoordinateRegion(center: center, span: span)
                    }
                }
            } else {
                mapItems = []
            }
        }
    }
    
    // Function to zoom to a specific location
    private func zoomToLocation(_ coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

struct MapPlacePickerView_Previews: PreviewProvider {
    static var previews: some View {
        MapPlacePickerView(selectedLocations: .constant([]), defaultLocationName: "")
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
