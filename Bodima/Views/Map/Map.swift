import SwiftUI
import MapKit
import UIKit
import CoreLocation

struct MapView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var locationViewModel = HabitationLocationViewModel()
    @StateObject private var featureViewModel = HabitationFeatureViewModel()
    @State private var locationManager = CLLocationManager()
    @State private var currentUserId: String?
    @State private var locationDataCache: [String: LocationData] = [:]
    @State private var featureDataCache: [String: HabitationFeatureData] = [:]
    @State private var pendingLocationRequests: Set<String> = []
    @State private var pendingFeatureRequests: Set<String> = []
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var isLoadingLocation = false
    @State private var selectedHabitation: EnhancedHabitationData? = nil
    @State private var showingDetails = false
    @State private var showingRoutePopup = false
    @State private var routeDistance: CLLocationDistance = 0
    @State private var routePolyline: MKPolyline? = nil
    @State private var isCalculatingRoute = false
    
    let profileId: String
    
    // Track zoom level for showing/hiding labels
    private var isZoomedIn: Bool {
        region.span.latitudeDelta < 0.5 && region.span.longitudeDelta < 0.5
    }
    
    // Convert habitations with location data to map annotations
    private var habitationAnnotations: [HabitationMapAnnotation] {
        return habitationViewModel.enhancedHabitations.compactMap { habitation in
            guard let locationData = locationDataCache[habitation.id] else {
                return nil
            }
            
            let latitude = locationData.latitude
            let longitude = locationData.longitude
            
            return HabitationMapAnnotation(
                habitation: habitation,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
    }
    
    // All map annotations including user location and habitations
    private var allMapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Add user location if available
        if let userLocation = userLocation {
            annotations.append(MapAnnotationItem(
                id: "user_location",
                coordinate: userLocation,
                type: .userLocation
            ))
        }
        
        // Add habitation annotations
        for habitation in habitationAnnotations {
            annotations.append(MapAnnotationItem(
                id: habitation.id.uuidString,
                coordinate: habitation.coordinate,
                type: .habitation(habitation.habitation)
            ))
        }
        
        return annotations
    }
    
    var body: some View {
        ZStack {
            mapView
            
            VStack {
                MapHeaderComponent(
                    habitationCount: habitationAnnotations.count,
                    onResetLocation: resetLocation,
                    onRefresh: loadData
                )
                
                Spacer()
                
                MapLoadingComponent(
                    isLoading: habitationViewModel.isFetchingEnhancedHabitations
                )
            }
        }
        .onAppear {
            loadData()
            setupLocationManager()
            getCurrentLocation()
        }
        .refreshable {
            loadData()
        }
        .onChange(of: locationViewModel.selectedLocation?.id) { locationId in
            if let location = locationViewModel.selectedLocation {
                let habitationId = location.habitation.id
                locationDataCache[habitationId] = location
                pendingLocationRequests.remove(habitationId)
            }
        }
        .onChange(of: locationViewModel.fetchLocationError) { error in
            if error != nil {
                if let lastRequestedHabitation = pendingLocationRequests.first {
                    pendingLocationRequests.remove(lastRequestedHabitation)
                }
            }
        }
        .onChange(of: featureViewModel.selectedFeature?.id) { featureId in
            if let feature = featureViewModel.selectedFeature {
                let habitationId = feature.habitation
                featureDataCache[habitationId] = feature
                pendingFeatureRequests.remove(habitationId)
            }
        }
        .onChange(of: featureViewModel.fetchFeatureError) { error in
            if error != nil {
                if let lastRequestedHabitation = pendingFeatureRequests.first {
                    pendingFeatureRequests.remove(lastRequestedHabitation)
                }
            }
        }
        // Fix 2: Use count instead of the array directly to avoid Equatable requirement
        .onChange(of: habitationViewModel.enhancedHabitations.count) { _ in
            // Fetch location data for all habitations
            for habitation in habitationViewModel.enhancedHabitations {
                fetchLocationForHabitation(habitationId: habitation.id)
                fetchFeatureForHabitation(habitationId: habitation.id)
            }
        }
        .sheet(isPresented: $showingDetails) {
            if let habitation = selectedHabitation {
                HabitationDetailSheet(
                    habitation: habitation,
                    locationData: locationDataCache[habitation.id],
                    featureData: featureDataCache[habitation.id]
                )
            }
        }
        .overlay(
            routePopupOverlay
        )
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: allMapAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                mapAnnotationView(for: annotation)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func mapAnnotationView(for annotation: MapAnnotationItem) -> some View {
        MapAnnotationComponent(
            annotation: annotation,
            isZoomedIn: isZoomedIn,
            onHabitationTap: { habitation, coordinate in
                selectedHabitation = habitation
                if let userLoc = userLocation {
                    calculateRouteAndShowPopup(from: userLoc, to: coordinate, habitation: habitation)
                } else {
                    showingDetails = true
                }
            }
        )
    }
    
    
    @ViewBuilder
    private var routePopupOverlay: some View {
        if showingRoutePopup, let habitation = selectedHabitation {
            RoutePopupComponent(
                habitation: habitation,
                routeDistance: routeDistance,
                isCalculatingRoute: isCalculatingRoute,
                onClose: {
                    showingRoutePopup = false
                    routePolyline = nil
                },
                onSeeDetails: {
                    showingRoutePopup = false
                    showingDetails = true
                }
            )
        }
    }
    
    private func resetLocation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            )
        }
    }
    
    private func loadData() {
        habitationViewModel.fetchAllEnhancedHabitations()
        
        if let userId = AuthViewModel.shared.currentUser?.id {
            currentUserId = userId
        }
        
        pendingLocationRequests.removeAll()
        pendingFeatureRequests.removeAll()
        locationDataCache.removeAll()
        featureDataCache.removeAll()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = LocationDelegate(onLocationUpdate: { location in
            DispatchQueue.main.async {
                userLocation = location.coordinate
                isLoadingLocation = false
            }
        })
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func getCurrentLocation() {
        // Use hardcoded location for simulator (Colombo, Sri Lanka)
        #if targetEnvironment(simulator)
        userLocation = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        isLoadingLocation = false
        #else
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            // Fallback to hardcoded location if permission denied
            userLocation = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
            return
        }
        
        isLoadingLocation = true
        locationManager.requestLocation()
        #endif
    }
    
    private func calculateRouteAndShowPopup(from userLoc: CLLocationCoordinate2D, to habitationLoc: CLLocationCoordinate2D, habitation: EnhancedHabitationData) {
        isCalculatingRoute = true
        showingRoutePopup = true
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: habitationLoc))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isCalculatingRoute = false
                
                if let route = response?.routes.first {
                    routeDistance = route.distance
                    routePolyline = route.polyline
                    
                    // Adjust map region to show both points
                    adjustMapRegionForRoute(userLoc: userLoc, habitationLoc: habitationLoc)
                } else {
                    // Fallback to straight-line distance
                    let userLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                    let habitationLocation = CLLocation(latitude: habitationLoc.latitude, longitude: habitationLoc.longitude)
                    routeDistance = userLocation.distance(from: habitationLocation)
                }
            }
        }
    }
    
    private func adjustMapRegionForRoute(userLoc: CLLocationCoordinate2D, habitationLoc: CLLocationCoordinate2D) {
        let minLat = min(userLoc.latitude, habitationLoc.latitude)
        let maxLat = max(userLoc.latitude, habitationLoc.latitude)
        let minLon = min(userLoc.longitude, habitationLoc.longitude)
        let maxLon = max(userLoc.longitude, habitationLoc.longitude)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    private func formatTravelTime(_ distance: CLLocationDistance) -> String {
        // Assume average walking speed of 5 km/h (1.39 m/s)
        let timeInSeconds = distance / 1.39
        let minutes = Int(timeInSeconds / 60)
        
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func fetchLocationForHabitation(habitationId: String) {
        if locationDataCache[habitationId] != nil {
            return
        }
        
        if pendingLocationRequests.contains(habitationId) {
            return
        }
        
        pendingLocationRequests.insert(habitationId)
        locationViewModel.fetchLocationByHabitationId(habitationId: habitationId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if pendingLocationRequests.contains(habitationId) {
                pendingLocationRequests.remove(habitationId)
            }
        }
    }
    
    private func fetchFeatureForHabitation(habitationId: String) {
        if featureDataCache[habitationId] != nil {
            return
        }
        
        if pendingFeatureRequests.contains(habitationId) {
            return
        }
        
        pendingFeatureRequests.insert(habitationId)
        featureViewModel.fetchFeaturesByHabitationId(habitationId: habitationId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if pendingFeatureRequests.contains(habitationId) {
                pendingFeatureRequests.remove(habitationId)
            }
        }
    }
    
}

struct HabitationDetailSheet: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    @Environment(\.dismiss) private var dismiss
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var likesCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Drag indicator
                    dragIndicator
                    
                    // Header Image
                    headerImage
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Habitation Info
                        habitationInfo
                        
                        // User Info
                        userInfo
                        
                        // Location Details
                        locationDetails
                        
                        // Features
                        featuresSection
                        
                        // Actions
                        actionButtons
                        
                        // Contact Button
                        contactButton
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppColors.mutedForeground.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
    }
    
    @ViewBuilder
    private var headerImage: some View {
        if let pictures = habitation.pictures, !pictures.isEmpty, let firstPicture = pictures.first {
            CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                placeholderImage
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.input)
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(AppColors.mutedForeground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
    
    private var habitationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habitation.name)
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Spacer()
                
                habitationTypeBadge
            }
            
            locationAndAvailability
            
            Text(habitation.description)
                .font(.subheadline)
                .foregroundStyle(AppColors.foreground)
                .lineLimit(nil)
        }
    }
    
    private var habitationTypeBadge: some View {
        Text(habitation.type)
            .font(.caption.bold())
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var locationAndAvailability: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.mutedForeground)
            
            if let user = habitation.user {
                Text("\(user.phoneNumber)")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
            } else {
                Text("Unknown location")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            availabilityBadge
        }
    }
    
    @ViewBuilder
    private var availabilityBadge: some View {
        if habitation.isReserved {
            Text("Reserved")
                .font(.caption.bold())
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        } else {
            Text("Available")
                .font(.caption.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hosted by")
                .font(.headline)
                .foregroundStyle(AppColors.foreground)
            
            if let user = habitation.user {
                HStack {
                    userAvatar
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.foreground)
                        
                        Text("@\(user.fullName)")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                }
            } else {
                Text("Unknown host")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
            }
        }
    }
    
    @ViewBuilder
    private var userAvatar: some View {
        if let user = habitation.user {
            Circle()
                .fill(AppColors.input)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .overlay(
                    Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                )
        } else {
            Circle()
                .fill(AppColors.input)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .overlay(
                    Text("?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                )
        }
    }
    
    @ViewBuilder
    private var locationDetails: some View {
        if let locationData = locationData {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location Details")
                    .font(.headline)
                    .foregroundStyle(AppColors.foreground)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("City: \(locationData.city)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                    
                    Text("Coordinates: \(locationData.latitude), \(locationData.longitude)")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
            }
        }
    }
    
    @ViewBuilder
    private var featuresSection: some View {
        if let featureData = featureData {
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.headline)
                    .foregroundStyle(AppColors.foreground)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    FeatureRow(label: "Bedrooms", value: "\(featureData.largeBedCount)")
                                    }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            likeButton
            saveButton
            Spacer()
        }
    }
    
    private var likeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isLiked.toggle()
                likesCount += isLiked ? 1 : -1
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isLiked ? AppColors.primary : AppColors.mutedForeground)
                
                Text("Like")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.input)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var saveButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isBookmarked.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isBookmarked ? AppColors.primary : AppColors.mutedForeground)
                
                Text("Save")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.input)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var contactButton: some View {
        NavigationLink(destination: DetailView(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )) {
            Text("View Details")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct FeatureRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.mutedForeground)
            
            Spacer()
            
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppColors.foreground)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
}
