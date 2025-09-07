import SwiftUI

struct MyHabitationsView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var locationDataCache: [String: LocationData] = [:]
    @State private var featureDataCache: [String: HabitationFeatureData] = [:]
    @State private var pendingLocationRequests: Set<String> = []
    @State private var pendingFeatureRequests: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if isLoading {
                        loadingView
                    } else if habitationViewModel.enhancedHabitations.isEmpty {
                        emptyStateView
                    } else {
                        habitationListView
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadUserHabitations()
            }
            .refreshable {
                loadUserHabitations()
            }
            .onChange(of: profileViewModel.userProfile?.id) { _ in
                loadUserHabitations()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Habitations")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Text("Manage your properties")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                
                Spacer()
                
                NavigationLink(destination: PostPlaceView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(AppColors.background)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.primary)
            Text("Loading your habitations...")
                .font(.subheadline)
                .foregroundColor(AppColors.mutedForeground)
                .padding(.top, 16)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "house.circle")
                .font(.system(size: 70))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("No habitations yet")
                .font(.title3.bold())
                .foregroundColor(AppColors.foreground)
            
            Text("You haven't posted any habitations yet. Tap the + button to create your first listing.")
                .font(.subheadline)
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            NavigationLink(destination: PostPlaceView()) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add New Habitation")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private var habitationListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(habitationViewModel.enhancedHabitations) { habitation in
                    MyHabitationCardView(
                        habitation: habitation,
                        locationData: locationDataCache[habitation.id],
                        featureData: featureDataCache[habitation.id],
                        onLocationFetch: fetchLocationForHabitation,
                        onFeatureFetch: fetchFeatureForHabitation
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .padding(.top, 8)
        }
    }
    
    private func loadUserHabitations() {
        guard let userId = profileViewModel.userProfile?.id else {
            // Try to load profile first if not available
            loadUserProfile()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Fetch all habitations first
        habitationViewModel.fetchAllEnhancedHabitations()
        isLoading = false
        
        // Filter habitations by the current user's ID
        let userHabitations = habitationViewModel.enhancedHabitations.filter { $0.user?.id == userId }
        habitationViewModel.enhancedHabitations = userHabitations
    }
    
    private func loadUserProfile() {
        guard let authId = AuthViewModel.shared.currentUser?.id else {
            errorMessage = "Not logged in"
            return
        }
        
        profileViewModel.fetchUserProfile(userId: authId)
    }
    
    private func fetchLocationForHabitation(_ habitationId: String) {
        guard !pendingLocationRequests.contains(habitationId) && locationDataCache[habitationId] == nil else {
            return
        }
        
        pendingLocationRequests.insert(habitationId)
        
        let locationViewModel = HabitationLocationViewModel()
        locationViewModel.fetchLocationByHabitationId(habitationId: habitationId)
        // We'll need to observe the published properties instead of using a completion handler
        // This is a simplified approach - in a real app, you might want to use Combine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if let location = locationViewModel.selectedLocation {
                locationDataCache[habitationId] = location
            }
            pendingLocationRequests.remove(habitationId)
        }
    }
    
    private func fetchFeatureForHabitation(_ habitationId: String) {
        guard !pendingFeatureRequests.contains(habitationId) && featureDataCache[habitationId] == nil else {
            return
        }
        
        pendingFeatureRequests.insert(habitationId)
        
        let featureViewModel = HabitationFeatureViewModel()
        featureViewModel.fetchFeaturesByHabitationId(habitationId: habitationId)
        // We'll need to observe the published properties instead of using a completion handler
        // This is a simplified approach - in a real app, you might want to use Combine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if let feature = featureViewModel.selectedFeature {
                featureDataCache[habitationId] = feature
            }
            pendingFeatureRequests.remove(habitationId)
        }
    }
}

struct MyHabitationCardView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    @State private var isReserved = false
    @State private var showingOptions = false
    @State private var hasTriedToFetchLocation = false
    @State private var hasTriedToFetchFeature = false
    
    var body: some View {
        NavigationLink(destination: MyHabitationDetailView(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )) {
            VStack(alignment: .leading, spacing: 0) {
                // Habitation Image
                imageSection
                
                // Content Section
                contentSection
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
                isReserved = habitation.isReserved
                
                if !hasTriedToFetchLocation {
                    hasTriedToFetchLocation = true
                    onLocationFetch(habitation.id)
                }
                
                if !hasTriedToFetchFeature {
                    hasTriedToFetchFeature = true
                    onFeatureFetch(habitation.id)
                }
            }
        .contextMenu {
            Button(action: {}) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {}) {
                Label(isReserved ? "Mark as Available" : "Mark as Reserved", 
                      systemImage: isReserved ? "checkmark.circle" : "xmark.circle")
            }
            
            Button(role: .destructive, action: {}) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            if let pictures = habitation.pictures, !pictures.isEmpty, let firstPicture = pictures.first {
                CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                    placeholderImage
                }
                .frame(height: 180)
                .clipped()
                .cornerRadius(16, corners: [.topLeft, .topRight])
            } else {
                placeholderImage
                    .frame(height: 180)
            }
            
            // Status badge
            Text(isReserved ? "Reserved" : "Available")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isReserved ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                .cornerRadius(12)
                .padding(12)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Type
            HStack {
                Text(habitation.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                
                Spacer()
                
                Text(habitation.type)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Price
            Text("Rs. \(habitation.price) / month")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            // Location
            if let locationData = locationData {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("\(locationData.city), \(locationData.district)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .lineLimit(1)
                }
            } else {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    if let user = habitation.user {
                    Text("\(user.city), \(user.district)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .lineLimit(1)
                } else {
                    Text("Unknown location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .lineLimit(1)
                }
                }
            }
            
            // Features
            if let featureData = featureData {
                HStack(spacing: 16) {
                    featureItem(icon: "bed.double.fill", value: "\(featureData.smallBedCount + featureData.largeBedCount) beds")
                    featureItem(icon: "square.fill", value: "\(featureData.sqft) sqft")
                    featureItem(icon: "person.2.fill", value: featureData.familyType)
                }
            }
            
            // Created Date
            Text("Posted on \(formatDate(habitation.createdAt))")
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(16)
    }
    
    private var placeholderImage: some View {
        ZStack {
            Rectangle()
                .fill(AppColors.input)
            
            Image(systemName: "photo")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.mutedForeground)
        }
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
    
    private func featureItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, yyyy"
        return displayFormatter.string(from: date)
    }
}

// Helper extension for rounded corners
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