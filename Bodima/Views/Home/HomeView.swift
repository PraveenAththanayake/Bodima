import SwiftUI

struct HomeView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var locationViewModel = HabitationLocationViewModel()
    @StateObject private var featureViewModel = HabitationFeatureViewModel()
    @State private var searchText = ""
    @State private var currentUserId: String?
    @State private var locationDataCache: [String: LocationData] = [:]
    @State private var featureDataCache: [String: HabitationFeatureData] = [:]
    @State private var pendingLocationRequests: Set<String> = []
    @State private var pendingFeatureRequests: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(searchText: $searchText)
                MainContentView(
                    habitations: habitationViewModel.enhancedHabitations,
                    isLoading: habitationViewModel.isFetchingEnhancedHabitations,
                    searchText: searchText,
                    locationDataCache: locationDataCache,
                    featureDataCache: featureDataCache,
                    onLocationFetch: { habitationId in
                        fetchLocationForHabitation(habitationId: habitationId)
                    },
                    onFeatureFetch: { habitationId in
                        fetchFeatureForHabitation(habitationId: habitationId)
                    }
                )
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
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
                printLocationDataForDebug(location: location)
            }
        }
        .onChange(of: locationViewModel.fetchLocationError) { error in
            if let error = error {
                if let lastRequestedHabitation = pendingLocationRequests.first {
                    pendingLocationRequests.remove(lastRequestedHabitation)
                }
            }
        }
        .onChange(of: locationViewModel.hasError) { hasError in
            if hasError {
                print("Location ViewModel error: \(locationViewModel.errorMessage ?? "Unknown error")")
            }
        }
        .onChange(of: featureViewModel.selectedFeature?.id) { featureId in
            if let feature = featureViewModel.selectedFeature {
                let habitationId = feature.habitation
                featureDataCache[habitationId] = feature
                pendingFeatureRequests.remove(habitationId)
                printFeatureDataForDebug(feature: feature)
            }
        }
        .onChange(of: featureViewModel.fetchFeatureError) { error in
            if let error = error {
                print("Feature fetch error: \(error)")
                if let lastRequestedHabitation = pendingFeatureRequests.first {
                    pendingFeatureRequests.remove(lastRequestedHabitation)
                }
            }
        }
        .onChange(of: featureViewModel.hasError) { hasError in
            if hasError {
                print("Feature ViewModel error: \(featureViewModel.errorMessage ?? "Unknown error")")
            }
        }
    }
    
    private func loadData() {
        print("Loading data...")
        habitationViewModel.fetchAllEnhancedHabitations()
        
        if let userId = AuthViewModel.shared.currentUser?.id {
            currentUserId = userId
            print("Current user ID: \(userId)")
        }
        
        pendingLocationRequests.removeAll()
        pendingFeatureRequests.removeAll()
        locationDataCache.removeAll()
        featureDataCache.removeAll()
    }
    
    private func fetchLocationForHabitation(habitationId: String) {
        if let cachedLocation = locationDataCache[habitationId] {
            print("Location already cached for habitation: \(habitationId)")
            printLocationDataForDebug(location: cachedLocation)
            return
        }
        
        if pendingLocationRequests.contains(habitationId) {
            print("Location request already pending for habitation: \(habitationId)")
            return
        }
        
        pendingLocationRequests.insert(habitationId)
        
        print("Fetching location for habitation: \(habitationId)")
        locationViewModel.fetchLocationByHabitationId(habitationId: habitationId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if pendingLocationRequests.contains(habitationId) {
                print("Location request timeout for \(habitationId)")
                pendingLocationRequests.remove(habitationId)
            }
        }
    }
    
    private func fetchFeatureForHabitation(habitationId: String) {
        if let cachedFeature = featureDataCache[habitationId] {
            print("Feature already cached for habitation: \(habitationId)")
            printFeatureDataForDebug(feature: cachedFeature)
            return
        }
        
        if pendingFeatureRequests.contains(habitationId) {
            print("Feature request already pending for habitation: \(habitationId)")
            return
        }
        
        pendingFeatureRequests.insert(habitationId)
        
        print("Fetching features for habitation: \(habitationId)")
        featureViewModel.fetchFeaturesByHabitationId(habitationId: habitationId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if pendingFeatureRequests.contains(habitationId) {
                print("Feature request timeout for \(habitationId)")
                pendingFeatureRequests.remove(habitationId)
            }
        }
    }
    
    private func printLocationDataForDebug(location: LocationData) {
        print("===== LOCATION DATA FOR DETAIL VIEW =====")
        print("Location ID: \(location.id)")
        print("Habitation ID: \(location.habitation.id)")
        print("Habitation Name: \(location.habitation.name)")
        print("Habitation Type: \(location.habitation.type)")
        print("Habitation Description: \(location.habitation.description)")
        print("Address No: \(location.addressNo)")
        print("Address Line 1: \(location.addressLine01)")
        print("Address Line 2: \(location.addressLine02)")
        print("City: \(location.city)")
        print("District: \(location.district)")
        print("Latitude: \(location.latitude)")
        print("Longitude: \(location.longitude)")
        print("Nearest Habitation Lat: \(location.nearestHabitationLatitude)")
        print("Nearest Habitation Lng: \(location.nearestHabitationLongitude)")
        print("Created At: \(location.createdAt)")
        print("Updated At: \(location.updatedAt)")
        print("Full Address: \(locationViewModel.getFullAddress(from: location))")
        print("Formatted Coordinates: \(locationViewModel.formatCoordinate(location.latitude)), \(locationViewModel.formatCoordinate(location.longitude))")
        print("==========================================")
    }
    
    private func printFeatureDataForDebug(feature: HabitationFeatureData) {
        print("===== HABITATION FEATURE DATA FOR DETAIL VIEW =====")
        print("Feature ID: \(feature.id)")
        print("Habitation ID: \(feature.habitation)")
        print("Square Footage: \(feature.sqft) sq ft")
        print("Family Type: \(feature.familyType)")
        print("Windows Count: \(feature.windowsCount)")
        print("Small Bed Count: \(feature.smallBedCount)")
        print("Large Bed Count: \(feature.largeBedCount)")
        print("Total Bedrooms: \(featureViewModel.getTotalBedrooms(from: feature))")
        print("Chair Count: \(feature.chairCount)")
        print("Table Count: \(feature.tableCount)")
        print("Total Furniture: \(featureViewModel.getTotalFurniture(from: feature))")
        print("Electricity Available: \(feature.isElectricityAvailable ? "Yes" : "No")")
        print("Washing Machine Available: \(feature.isWachineMachineAvailable ? "Yes" : "No")")
        print("Water Available: \(feature.isWaterAvailable ? "Yes" : "No")")
        print("Available Utilities: \(featureViewModel.getAvailableUtilities(from: feature).joined(separator: ", "))")
        print("Utility Availability Score: \(featureViewModel.getUtilityAvailabilityScore(from: feature))/3")
        print("Feature Summary: \(featureViewModel.getFeatureSummary(from: feature))")
        print("Created At: \(feature.createdAt)")
        print("Updated At: \(feature.updatedAt)")
        print("Version: \(feature.v)")
        print("====================================================")
    }
}

struct HeaderView: View {
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            TopBarView()
            SearchBarView(searchText: $searchText)
        }
        .background(AppColors.background)
    }
}

struct TopBarView: View {
    var body: some View {
        HStack {
            TitleSection()
            Spacer()
            NotificationButton()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

struct TitleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bodima")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Stories • Feed")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

struct NotificationButton: View {
    var body: some View {
        Button(action: {
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.foreground)
            }
        }
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            SearchIcon()
            SearchTextField(searchText: $searchText)
            ClearButton(searchText: $searchText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(searchBarBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.input)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

struct SearchIcon: View {
    var body: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(AppColors.mutedForeground)
            .font(.system(size: 16, weight: .medium))
    }
}

struct SearchTextField: View {
    @Binding var searchText: String
    
    var body: some View {
        TextField("Search posts, users...", text: $searchText)
            .font(.system(size: 16))
            .foregroundColor(AppColors.foreground)
    }
}

struct ClearButton: View {
    @Binding var searchText: String
    
    var body: some View {
        if !searchText.isEmpty {
            Button(action: {
                searchText = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.mutedForeground)
                    .font(.system(size: 16))
            }
        }
    }
}

struct MainContentView: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let searchText: String
    let locationDataCache: [String: LocationData]
    let featureDataCache: [String: HabitationFeatureData]
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    var filteredHabitations: [EnhancedHabitationData] {
        if searchText.isEmpty {
            return habitations
        } else {
            return habitations.filter { habitation in
                habitation.name.localizedCaseInsensitiveContains(searchText) ||
                habitation.description.localizedCaseInsensitiveContains(searchText) ||
                habitation.userFullName.localizedCaseInsensitiveContains(searchText) ||
                habitation.user.city.localizedCaseInsensitiveContains(searchText) ||
                habitation.user.district.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                StoriesSection()
                FeedSection(
                    habitations: filteredHabitations,
                    isLoading: isLoading,
                    locationDataCache: locationDataCache,
                    featureDataCache: featureDataCache,
                    onLocationFetch: onLocationFetch,
                    onFeatureFetch: onFeatureFetch
                )
            }
        }
    }
}

struct StoriesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            StoriesHeader()
            StoriesScrollView()
        }
        .padding(.bottom, 24)
    }
}

struct StoriesHeader: View {
    var body: some View {
        HStack {
            Text("Stories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Spacer()
            
            Button(action: {
            }) {
                Text("View All")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct StoriesScrollView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                AddStoryView()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct AddStoryView: View {
    var body: some View {
        Button(action: {
        }) {
            VStack(spacing: 8) {
                AddStoryCircle()
                AddStoryLabel()
            }
            .frame(width: 76)
        }
    }
}

struct AddStoryCircle: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.input)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 2)
                )
            
            Circle()
                .fill(AppColors.primary)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

struct AddStoryLabel: View {
    var body: some View {
        Text("Your Story")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppColors.foreground)
            .lineLimit(1)
    }
}

struct FeedSection: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let locationDataCache: [String: LocationData]
    let featureDataCache: [String: HabitationFeatureData]
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    var body: some View {
        if isLoading {
            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
                Text("Loading habitations...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(.top, 40)
        } else if habitations.isEmpty {
            VStack {
                Image(systemName: "house.slash")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(.bottom, 16)
                Text("No habitations found")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                Text("Try adjusting your search or check back later")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(habitations, id: \.id) { habitation in
                    HabitationCardView(
                        habitation: habitation,
                        locationData: locationDataCache[habitation.id],
                        featureData: featureDataCache[habitation.id],
                        onLocationFetch: onLocationFetch,
                        onFeatureFetch: onFeatureFetch
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
}

struct HabitationCardView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likesCount = 0
    @State private var isFollowing = false
    @State private var hasTriedToFetchLocation = false
    @State private var hasTriedToFetchFeature = false
    
    var body: some View {
        NavigationLink(destination: DetailView(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )) {
            VStack(alignment: .leading, spacing: 0) {
                HabitationHeader(habitation: habitation, isFollowing: $isFollowing)
                HabitationImage(pictures: habitation.pictures)
                HabitationActions(isLiked: $isLiked, likesCount: $likesCount, isBookmarked: $isBookmarked)
                HabitationContent(habitation: habitation)
            }
            .padding(20)
            .background(habitationCardBackground)
            .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !hasTriedToFetchLocation {
                print("HabitationCardView appeared for: \(habitation.name)")
                onLocationFetch(habitation.id)
                hasTriedToFetchLocation = true
            }
            
            if !hasTriedToFetchFeature {
                print("Fetching features for habitation: \(habitation.name)")
                onFeatureFetch(habitation.id)
                hasTriedToFetchFeature = true
            }
        }
        .onTapGesture {
            printNavigationData()
        }
    }
    
    private var habitationCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
    
    private func printNavigationData() {
        print("===== NAVIGATING TO DETAIL VIEW =====")
        print("Habitation Data:")
        print("   ID: \(habitation.id)")
        print("   Name: \(habitation.name)")
        print("   Description: \(habitation.description)")
        print("   Type: \(habitation.type)")
        print("   Is Reserved: \(habitation.isReserved)")
        print("   User: \(habitation.userFullName)")
        print("   City: \(habitation.user.city)")
        print("   District: \(habitation.user.district)")
        
        if let location = locationData {
            print("Location Data Available:")
            print("   Location ID: \(location.id)")
            print("   Habitation ID: \(location.habitation.id)")
            print("   Habitation Name: \(location.habitation.name)")
            print("   Full Address: \(location.addressNo), \(location.addressLine01), \(location.addressLine02)")
            print("   City: \(location.city)")
            print("   District: \(location.district)")
            print("   Coordinates: \(location.latitude), \(location.longitude)")
            print("   Nearest Habitation: \(location.nearestHabitationLatitude), \(location.nearestHabitationLongitude)")
        } else {
            print("No Location Data Available - DetailView will receive nil location")
        }
        
        if let feature = featureData {
            print("Feature Data Available:")
            print("   Feature ID: \(feature.id)")
            print("   Habitation ID: \(feature.habitation)")
            print("   Square Footage: \(feature.sqft) sq ft")
            print("   Family Type: \(feature.familyType)")
            print("   Total Bedrooms: \(feature.smallBedCount + feature.largeBedCount)")
            print("   Windows: \(feature.windowsCount)")
            print("   Chairs: \(feature.chairCount)")
            print("   Tables: \(feature.tableCount)")
            print("   Utilities: Electricity=\(feature.isElectricityAvailable), Water=\(feature.isWaterAvailable), WashingMachine=\(feature.isWachineMachineAvailable)")
            print("   Created: \(feature.createdAt)")
            print("   Updated: \(feature.updatedAt)")
        } else {
            print("No Feature Data Available - DetailView will receive nil feature")
        }
        
        print("=====================================")
    }
}

struct HabitationHeader: View {
    let habitation: EnhancedHabitationData
    @Binding var isFollowing: Bool
    
    var body: some View {
        HStack {
            UserAvatar(user: habitation.user)
            UserInfo(user: habitation.user, createdAt: habitation.createdAt)
            Spacer()
            FollowButton(isFollowing: $isFollowing)
            MenuButton()
        }
        .padding(.bottom, 16)
    }
}

struct UserAvatar: View {
    let user: EnhancedUserData
    
    var body: some View {
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
    }
}

struct UserInfo: View {
    let user: EnhancedUserData
    let createdAt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(user.firstName) \(user.lastName)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("@\(user.auth) • \(formatTime(createdAt))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else { return "now" }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "now"
        }
    }
}

struct FollowButton: View {
    @Binding var isFollowing: Bool
    
    var body: some View {
        Button(action: {
            isFollowing.toggle()
        }) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isFollowing ? AppColors.foreground : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(followButtonBackground)
        }
    }
    
    private var followButtonBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isFollowing ? AppColors.input : AppColors.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isFollowing ? AppColors.border : AppColors.primary, lineWidth: 1)
            )
    }
}

struct MenuButton: View {
    var body: some View {
        Button(action: {
        }) {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.mutedForeground)
                .rotationEffect(.degrees(90))
        }
    }
}

struct HabitationImage: View {
    let pictures: [HabitationPicture]?
    
    var body: some View {
        if let pictures = pictures, !pictures.isEmpty, let firstPicture = pictures.first {
            AsyncImage(url: URL(string: firstPicture.pictureUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .clipped()
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(height: 280)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .padding(.bottom, 16)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.input)
                .frame(height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppColors.mutedForeground)
                )
                .padding(.bottom, 16)
        }
    }
}

struct HabitationActions: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    @Binding var isBookmarked: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            LikeButton(isLiked: $isLiked, likesCount: $likesCount)
            ShareButton()
            Spacer()
            BookmarkButton(isBookmarked: $isBookmarked)
        }
        .padding(.bottom, 16)
    }
}

struct LikeButton: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isLiked.toggle()
                likesCount += isLiked ? 1 : -1
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isLiked ? AppColors.primary : AppColors.mutedForeground)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
                
                if likesCount > 0 {
                    Text("\(likesCount)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                }
            }
        }
    }
}

struct ShareButton: View {
    var body: some View {
        Button(action: {
        }) {
            Image(systemName: "paperplane")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}


struct BookmarkButton: View {
    @Binding var isBookmarked: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isBookmarked.toggle()
            }
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isBookmarked ? AppColors.primary : AppColors.mutedForeground)
                .scaleEffect(isBookmarked ? 1.1 : 1.0)
        }
    }
}

struct HabitationContent: View {
    let habitation: EnhancedHabitationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(habitation.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Text(habitation.type)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text(habitation.description)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.foreground)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("\(habitation.user.city), \(habitation.user.district)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
                
                if habitation.isReserved {
                    Text("Reserved")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("Available")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    HomeView()
}
