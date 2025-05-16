import SwiftUI
import MapKit
import CoreLocation

struct NavigationMapView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager()
    let locations: [Location]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showLocationPermissionAlert = false
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var selectedLocation: Location?
    @State private var routeInfo: (distance: String, time: String)? = nil
    @State private var routeError: String? = nil
    @State private var showRouteSheet = false
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: location.coordinates.latitude,
                        longitude: location.coordinates.longitude
                    )) {
                        Button(action: {
                            selectedLocation = location
                            calculateRoute(to: location)
                            withAnimation {
                                region = MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: location.coordinates.latitude - 0.004,
                                        longitude: location.coordinates.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(accentColor)
                                    .shadow(radius: 4)
                                Text(location.name)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: 120)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .overlay(
                    Group {
                        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if let userLoc = userLocation ?? locationManager.userLocation {
                                            withAnimation {
                                                region = MKCoordinateRegion(
                                                    center: userLoc,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                )
                                            }
                                        }
                                    }) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Circle().fill(Color.accentColor))
                                            .shadow(radius: 4)
                                    }
                                    .padding(.trailing, 18)
                                    .padding(.bottom, 32)
                                }
                            }
                        }
                    }
                )
                .onAppear {
                    // Zoom out to fit all trip locations and user location (same logic as Close button)
                    var coords = locations.map { CLLocationCoordinate2D(latitude: $0.coordinates.latitude, longitude: $0.coordinates.longitude) }
                    if let userLoc = userLocation ?? locationManager.userLocation {
                        coords.append(userLoc)
                    }
                    if !coords.isEmpty {
                        withAnimation {
                            region = regionThatFitsAll(coordinates: coords)
                        }
                    }
                }
                .sheet(isPresented: $showRouteSheet) {
                    Group {
                        if routeInfo != nil && selectedLocation != nil {
                            let routeInfo = routeInfo!
                            let selectedLocation = selectedLocation!
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .fill(accentColor.opacity(0.15))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(accentColor)
                                        .shadow(radius: 5)
                                }
                                Text(selectedLocation.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 14)
                                    .padding(.bottom, 14)
                                    .padding(.horizontal, 12)
                                HStack(spacing: 24) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "car.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.gray)
                                        Text("Distance")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(String(format: "%.2f mi", (Double(routeInfo.distance.replacingOccurrences(of: ",", with: ".").components(separatedBy: " ").first ?? "0") ?? 0.0) * 0.621371))
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    VStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.gray)
                                        Text("Est. Time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(routeInfo.time)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.09))
                                .cornerRadius(16)
                                .padding(.bottom, 20)
                                VStack(spacing: 10) {
                                    Button(action: {
                                        let dest = selectedLocation.coordinates
                                        let url = URL(string: "http://maps.apple.com/?daddr=\(dest.latitude),\(dest.longitude)&dirflg=d")!
                                        UIApplication.shared.open(url)
                                    }) {
                                        Text("Get Directions")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.accentColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                    Button(action: {
                                        // Zoom out to fit all trip locations and user location
                                        var coords = locations.map { CLLocationCoordinate2D(latitude: $0.coordinates.latitude, longitude: $0.coordinates.longitude) }
                                        if let userLoc = userLocation ?? locationManager.userLocation {
                                            coords.append(userLoc)
                                        }
                                        if !coords.isEmpty {
                                            withAnimation {
                                                region = regionThatFitsAll(coordinates: coords)
                                            }
                                        }
                                        showRouteSheet = false
                                    }) {
                                        Text("Close")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemGray4).opacity(0.5))
                                            .foregroundColor(.accentColor)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(.separator), lineWidth: 0.5)
                                            )
                                    }
                                }
                                .frame(width: 210)
                                .padding(.bottom, 12)
                            }
                            .padding(.horizontal, 0)
                            .background(Color(.systemGray6).opacity(0.98))
                            .cornerRadius(22)
                        } else if routeError != nil && selectedLocation != nil {
                            let routeError = routeError!
                            let selectedLocation = selectedLocation!
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(.red)
                                        .shadow(radius: 5)
                                }
                                Text(selectedLocation.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 14)
                                    .padding(.bottom, 14)
                                    .padding(.horizontal, 12)
                                Text(routeError)
                                    .foregroundColor(.red)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 18)
                                    .padding(.horizontal, 8)
                                Spacer(minLength: 3)
                                VStack(spacing: 0) {
                                    Button(action: {
                                        // Zoom out to fit all trip locations and user location
                                        var coords = locations.map { CLLocationCoordinate2D(latitude: $0.coordinates.latitude, longitude: $0.coordinates.longitude) }
                                        if let userLoc = userLocation ?? locationManager.userLocation {
                                            coords.append(userLoc)
                                        }
                                        if !coords.isEmpty {
                                            withAnimation {
                                                region = regionThatFitsAll(coordinates: coords)
                                            }
                                        }
                                        showRouteSheet = false
                                    }) {
                                        Text("Close")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemGray4).opacity(0.5))
                                            .foregroundColor(.accentColor)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(.separator), lineWidth: 0.5)
                                            )
                                    }
                                    .frame(width: 210)
                                    .padding(.top, 18)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 12)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
                            .padding(.horizontal, 0)
                            .background(Color(.systemGray6).opacity(0.98))
                            .cornerRadius(22)
                        } else {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                                    .scaleEffect(1.5)
                                    .padding(.top, 32)
                                Text("Calculating route...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 16)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.95))
                            .cornerRadius(24)
                        }
                    }
                    .presentationDetents([.medium])
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentColor)
                    
                    Text("Location Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Please enable location access to use navigation features.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        locationManager.requestLocationPermission()
                    }) {
                        Text("Enable Location")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 200)
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(.secondary)
                        .shadow(radius: 1)
                }
                .accessibilityLabel("Close")
            }
        }
        .onAppear {
            if locationManager.authorizationStatus == .denied {
                showLocationPermissionAlert = true
            }
        }
        .alert("Location Access Required", isPresented: $showLocationPermissionAlert) {
            Button("Cancel", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable location access in Settings to use navigation features.")
        }
    }
    
    private func calculateRoute(to location: Location) {
        // Reset state before calculation
        routeInfo = nil
        routeError = nil

        guard let userCoord = locationManager.userLocation else {
            routeInfo = nil
            routeError = "Unable to get your current location."
            showRouteSheet = true
            return
        }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: location.coordinates.latitude, longitude: location.coordinates.longitude)))
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                let distance = String(format: "%.2f km", route.distance / 1000)
                let time = String(format: "%.0f min", route.expectedTravelTime / 60)
                self.routeInfo = (distance, time)
                self.routeError = nil
            } else {
                self.routeInfo = nil
                self.routeError = "Unable to get direction."
            }
            self.showRouteSheet = true
        }
    }
    
    private func regionThatFitsAll(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return region
        }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        let latDelta = (maxLat - minLat) * 1.2 + 0.03
        let lonDelta = (maxLon - minLon) * 1.2 + 0.03
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location.coordinate
        }
    }
}

#Preview {
    NavigationMapView(locations: [])
} 