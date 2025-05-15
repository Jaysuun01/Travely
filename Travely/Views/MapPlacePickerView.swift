// Created by Jason Huynh

import SwiftUI
import MapKit
import FirebaseFirestore

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
    @State private var showingSearchResults = true
    @State private var listOffset: CGFloat = 350
    @State private var isDragging = false
    @State private var startOffset: CGFloat = 350
    @State private var scrollOffset: CGFloat = 0
    
    // Location details state
    @State private var locationName: String = ""
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var transportation: TransportationType = .car
    @State private var notes = ""
    
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.8
    private let minimizedHeight: CGFloat = 60 // Height when minimized
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
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
                    MapAnnotation(coordinate: item.placemark.coordinate) {
                        Button(action: {
                            zoomToLocation(item.placemark.coordinate)
                            selectedMapItem = item
                            locationName = item.name ?? "Unknown"
                            withAnimation {
                                showingSearchResults = false
                            }
                        }) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color.orange)
                                .shadow(radius: 4)
                        }
                    }
                })
                .frame(maxHeight: .infinity)
                
                if isSearching {
                    ProgressView()
                }
                
                // Search results or location form at the bottom
                if !mapItems.isEmpty {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Drag indicator
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 4)
                                .cornerRadius(2)
                                .padding(.vertical, 8)
                            
                            // Header with back button when showing location form
                            HStack {
                                if !showingSearchResults {
                                    Button(action: {
                                        withAnimation {
                                            showingSearchResults = true
                                        }
                                        zoomToAllLocations()
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8)
                                }
                                
                                Text(showingSearchResults ? "Search Results" : "Location Details")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                if showingSearchResults {
                                    Text("\(mapItems.count) locations")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            
                            // Content changes based on whether we're showing search results or location form
                            if showingSearchResults {
                                // SEARCH RESULTS LIST
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
                                                locationName = item.name ?? "Unknown"
                                                withAnimation {
                                                    showingSearchResults = false
                                                }
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
                            } else {
                                // LOCATION DETAILS FORM
                                ScrollView {
                                    VStack(spacing: 16) {
                                        // Location info
                                        if let item = selectedMapItem {
                                            // Location name
                                            HStack(spacing: 12) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .resizable()
                                                    .frame(width: 28, height: 28)
                                                    .foregroundColor(accentColor)
                                                TextField("Location Name", text: $locationName)
                                                    .font(.headline)
                                                    .padding(12)
                                                    .background(Color.white.opacity(0.08))
                                                    .cornerRadius(10)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Address
                                            if let address = item.placemark.title {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "map")
                                                        .resizable()
                                                        .frame(width: 28, height: 28)
                                                        .foregroundColor(.orange)
                                                    Text(address)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                        .padding(12)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .background(Color.white.opacity(0.08))
                                                        .cornerRadius(10)
                                                }
                                            }
                                            
                                            // Single Date Picker
                                            HStack(spacing: 12) {
                                                Image(systemName: "calendar")
                                                    .resizable()
                                                    .frame(width: 28, height: 28)
                                                    .foregroundColor(.blue)
                                                VStack(alignment: .leading) {
                                                    Text("Date")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                                        .labelsHidden()
                                                        .colorScheme(.dark)
                                                }
                                                Spacer()
                                            }
                                            
                                            // Time Pickers
                                            HStack(spacing: 16) {
                                                // Start Time
                                                HStack(spacing: 12) {
                                                    Image(systemName: "clock")
                                                        .resizable()
                                                        .frame(width: 24, height: 24)
                                                        .foregroundColor(.blue)
                                                    VStack(alignment: .leading) {
                                                        Text("Start Time")
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                                            .labelsHidden()
                                                            .colorScheme(.dark)
                                                    }
                                                }
                                                
                                                // End Time
                                                HStack(spacing: 12) {
                                                    Image(systemName: "clock.fill")
                                                        .resizable()
                                                        .frame(width: 24, height: 24)
                                                        .foregroundColor(.blue)
                                                    VStack(alignment: .leading) {
                                                        Text("End Time")
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                                            .labelsHidden()
                                                            .colorScheme(.dark)
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 4)
                                            
                                            // Transportation picker
                                            HStack(spacing: 12) {
                                                Picker("Transportation", selection: $transportation) {
                                                    ForEach(TransportationType.allCases) { type in
                                                        HStack {
                                                            Image(systemName: type.iconName)
                                                                .foregroundColor(type.iconColor)
                                                            Text(type.displayName)
                                                        }
                                                        .tag(type)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .padding(12)
                                                .background(Color.white.opacity(0.08))
                                                .cornerRadius(10)
                                                .foregroundColor(.white)
                                            }
                                            
                                            // Notes
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "note.text")
                                                    .resizable()
                                                    .frame(width: 28, height: 28)
                                                    .foregroundColor(.yellow)
                                                TextField("Notes", text: $notes, axis: .vertical)
                                                    .lineLimit(3, reservesSpace: true)
                                                    .padding(12)
                                                    .background(Color.white.opacity(0.08))
                                                    .cornerRadius(10)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Add to Trip button
                                            Button(action: saveLocation) {
                                                HStack {
                                                    Image(systemName: "plus.circle.fill")
                                                        .foregroundColor(.white)
                                                    Text("Add to Trip")
                                                        .fontWeight(.semibold)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(accentColor)
                                                .cornerRadius(12)
                                                .foregroundColor(.white)
                                                .shadow(color: accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
                                            }
                                            .padding(.top, 12)
                                        }
                                    }
                                    .padding(16)
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
                
                // Reset to showing search results
                withAnimation {
                    showingSearchResults = true
                }
                
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: coordinate.latitude - 0.0012, 
                        longitude: coordinate.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            }
        }
    }
    
    private func zoomToAllLocations() {
        guard !mapItems.isEmpty else { return }
        var minLat = mapItems[0].placemark.coordinate.latitude
        var maxLat = minLat
        var minLon = mapItems[0].placemark.coordinate.longitude
        var maxLon = minLon
        for item in mapItems {
            let coord = item.placemark.coordinate
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
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
        withAnimation(.spring(response: 2.5, dampingFraction: 0.85, blendDuration: 0.5)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    // Function to save location
    private func saveLocation() {
        guard let mapItem = selectedMapItem else { return }
        
        // Create start and end dates by combining the selected date with the times
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startDate = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                    minute: startComponents.minute ?? 0,
                                    second: 0,
                                    of: selectedDate) ?? selectedDate
        
        let endDate = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                  minute: endComponents.minute ?? 0,
                                  second: 0,
                                  of: selectedDate) ?? selectedDate
        
        let location = Location(
            id: UUID().uuidString,
            name: locationName,
            startDate: startDate,
            endDate: endDate,
            transportation: transportation,
            coordinates: GeoPoint(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            ),
            notes: notes,
            createdAt: Date(),
            tripId: selectedLocations.first?.tripId ?? ""
        )
        
        selectedLocations.append(location)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            presentationMode.wrappedValue.dismiss()
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
