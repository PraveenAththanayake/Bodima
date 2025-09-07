import SwiftUI
import MapKit
import UIKit

struct MapView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var locationViewModel = HabitationLocationViewModel()
    @StateObject private var featureViewModel = HabitationFeatureViewModel()
    @State private var currentUserId: String?
    @State private var locationDataCache: [String: LocationData] = [:]
    @State private var featureDataCache: [String: HabitationFeatureData] = [:]
    @State private var pendingLocationRequests: Set<String> = []
    @State private var pendingFeatureRequests: Set<String> = []
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718), // Sri Lanka center
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    @State private var selectedHabitation: EnhancedHabitationData? = nil
    @State private var showingDetails = false
    
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
            
            // Fixed: Remove Double() conversion since latitude/longitude are already Double
            let latitude = locationData.latitude
            let longitude = locationData.longitude
            
            return HabitationMapAnnotation(
                habitation: habitation,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Map View
            mapView
            
            // Header
            VStack {
                headerView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                Spacer()
                
                // Loading indicator
                loadingIndicator
            }
        }
        .onAppear {
            loadData()
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
    }
    
    // Fix 3: Break up complex expressions into smaller computed properties
    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: habitationAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                mapAnnotationButton(for: annotation)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
    }
    
    private func mapAnnotationButton(for annotation: HabitationMapAnnotation) -> some View {
        Button(action: {
            selectedHabitation = annotation.habitation
            showingDetails = true
        }) {
            annotationView(for: annotation)
        }
        .buttonStyle(.plain)
    }
    
    private func annotationView(for annotation: HabitationMapAnnotation) -> some View {
        VStack(spacing: 4) {
            annotationIcon(for: annotation)
            
            // Show name and price only when zoomed in
            if isZoomedIn {
                annotationLabel(for: annotation)
            }
        }
    }
    
    private func annotationIcon(for annotation: HabitationMapAnnotation) -> some View {
        Image(systemName: getHabitationIcon(for: annotation.habitation.type))
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(getHabitationColor(for: annotation.habitation.type))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func annotationLabel(for annotation: HabitationMapAnnotation) -> some View {
        VStack(spacing: 2) {
            Text(annotation.habitation.name)
                .font(.caption2.bold())
                .foregroundStyle(AppColors.foreground)
                .lineLimit(1)
            
            Text(annotation.habitation.type)
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if habitationViewModel.isFetchingEnhancedHabitations {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading habitations...")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: AppColors.border.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            headerTitle
            Spacer()
            headerButtons
        }
    }
    
    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bodima")
                .font(.title2.bold())
                .foregroundStyle(AppColors.foreground)
            
            Text("Explore Places (\(habitationAnnotations.count))")
                .font(.caption)
                .foregroundStyle(AppColors.mutedForeground)
        }
    }
    
    private var headerButtons: some View {
        HStack(spacing: 12) {
            resetLocationButton
            refreshButton
        }
    }
    
    private var resetLocationButton: some View {
        Button(action: {
            // Reset to Sri Lanka view
            withAnimation(.easeInOut(duration: 0.8)) {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
                    span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                )
            }
        }) {
            Image(systemName: "location")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.foreground)
                .frame(width: 44, height: 44)
                .background(AppColors.input)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset view")
    }
    
    private var refreshButton: some View {
        Button(action: {
            loadData()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.foreground)
                .frame(width: 44, height: 44)
                .background(AppColors.input)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh")
    }
    
    // MARK: - Helper Methods
    
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
    
    private func getHabitationIcon(for type: String) -> String {
        switch type.lowercased() {
        case "apartment":
            return "building.2.fill"
        case "house":
            return "house.fill"
        case "room":
            return "bed.double.fill"
        case "hostel":
            return "building.fill"
        case "studio":
            return "square.fill"
        default:
            return "house.fill"
        }
    }
    
    private func getHabitationColor(for type: String) -> Color {
        switch type.lowercased() {
        case "apartment":
            return AppColors.primary
        case "house":
            return .green
        case "room":
            return .orange
        case "hostel":
            return .purple
        case "studio":
            return .pink
        default:
            return AppColors.primary
        }
    }
}

struct HabitationMapAnnotation: Identifiable {
    let id = UUID()
    let habitation: EnhancedHabitationData
    let coordinate: CLLocationCoordinate2D
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
                Text("\(user.city), \(user.district)")
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
                        
                        Text("@\(user.auth)")
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
