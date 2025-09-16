import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var locationViewModel = HabitationLocationViewModel()
    @StateObject private var featureViewModel = HabitationFeatureViewModel()
    @StateObject private var userStoriesViewModel = UserStoriesViewModel()
    @State private var searchText = ""
    @State private var selectedHabitationType: HabitationType? = nil
    @State private var showFilterMenu = false
    @State private var currentUserId: String?
    @State private var locationDataCache: [String: LocationData] = [:]
    @State private var featureDataCache: [String: HabitationFeatureData] = [:]
    @State private var pendingLocationRequests: Set<String> = []
    @State private var pendingFeatureRequests: Set<String> = []
    @State private var selectedStory: UserStoryData?
    @State private var showStoryOverlay = false
    @State private var showStoryCreation = false
    let profileId: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(
                    searchText: $searchText,
                    selectedHabitationType: $selectedHabitationType,
                    showFilterMenu: $showFilterMenu
                )
                MainContentView(
                    habitations: habitationViewModel.enhancedHabitations,
                    isLoading: habitationViewModel.isFetchingEnhancedHabitations,
                    searchText: searchText,
                    selectedHabitationType: selectedHabitationType,
                    locationDataCache: locationDataCache,
                    featureDataCache: featureDataCache,
                    userStories: userStoriesViewModel.sortedStories,
                    isStoriesLoading: userStoriesViewModel.isLoading,
                    onLocationFetch: { habitationId in
                        fetchLocationForHabitation(habitationId: habitationId)
                    },
                    onFeatureFetch: { habitationId in
                        fetchFeatureForHabitation(habitationId: habitationId)
                    },
                    onStoryTap: { story in
                        selectedStory = story
                        showStoryOverlay = true
                    },
                    onCreateStoryTap: {
                        showStoryCreation = true
                    },
                    storiesViewModel: userStoriesViewModel
                )
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if showStoryOverlay, let story = selectedStory {
                        StoryOverlayView(
                            story: story,
                            isPresented: $showStoryOverlay,
                            storiesViewModel: userStoriesViewModel
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showStoryOverlay)
                    }
                    if showStoryCreation {
                        CreateStoryView(
                            viewModel: userStoriesViewModel,
                            userId: profileId,
                            isPresented: $showStoryCreation
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showStoryCreation)
                    }
                }
            )
        }
        .onAppear {
            loadData()
            // Start auto-refresh to cleanup expired stories
            userStoriesViewModel.startAutoRefresh()
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
    }
    
    private func loadData() {
        habitationViewModel.fetchAllEnhancedHabitations()
        userStoriesViewModel.fetchUserStories()
        
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
}

struct HeaderView: View {
    @Binding var searchText: String
    @Binding var selectedHabitationType: HabitationType?
    @Binding var showFilterMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TopBarView()
            SearchBarView(searchText: $searchText)
            FilterBarView(
                selectedHabitationType: $selectedHabitationType,
                showFilterMenu: $showFilterMenu
            )
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
    @StateObject private var notificationViewModel = NotificationViewModel()
    
    var body: some View {
        NavigationLink(destination: NotificationsView()) {
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
                
                // Notification badge
                if notificationViewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 18, height: 18)
                        
                        Text("\(min(notificationViewModel.unreadCount, 9))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 12, y: -12)
                }
            }
        }
        .onAppear {
            notificationViewModel.fetchNotifications()
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
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

struct FilterBarView: View {
    @Binding var selectedHabitationType: HabitationType?
    @Binding var showFilterMenu: Bool
    
    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All filter button
                    FilterChip(
                        title: "All",
                        isSelected: selectedHabitationType == nil,
                        action: {
                            selectedHabitationType = nil
                        }
                    )
                    
                    // Individual type filter buttons
                    ForEach(HabitationType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: selectedHabitationType == type,
                            action: {
                                selectedHabitationType = type
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : AppColors.foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.primary : AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct MainContentView: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let searchText: String
    let selectedHabitationType: HabitationType?
    let locationDataCache: [String: LocationData]
    let featureDataCache: [String: HabitationFeatureData]
    let userStories: [UserStoryData]
    let isStoriesLoading: Bool
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    var filteredHabitations: [EnhancedHabitationData] {
        var filtered = habitations
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { habitation in
                habitation.name.localizedCaseInsensitiveContains(searchText) ||
                habitation.description.localizedCaseInsensitiveContains(searchText) ||
                habitation.userFullName.localizedCaseInsensitiveContains(searchText) ||
                (habitation.user?.city.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (habitation.user?.district.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by habitation type
        if let selectedType = selectedHabitationType {
            filtered = filtered.filter { habitation in
                habitation.type == selectedType.rawValue
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                StoriesSection(
                    stories: userStories,
                    isLoading: isStoriesLoading,
                    onStoryTap: onStoryTap,
                    onCreateStoryTap: onCreateStoryTap,
                    storiesViewModel: storiesViewModel
                )
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
    let stories: [UserStoryData]
    let isLoading: Bool
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    var body: some View {
        // Only show stories section if there are active stories or if loading
        if isLoading || !stories.isEmpty {
            VStack(spacing: 16) {
                StoriesHeader(storiesCount: stories.count)
                StoriesScrollView(
                    stories: stories,
                    isLoading: isLoading,
                    onStoryTap: onStoryTap,
                    onCreateStoryTap: onCreateStoryTap,
                    storiesViewModel: storiesViewModel
                )
            }
            .padding(.bottom, 24)
        } else {
            // When no stories, show only the create story button
            VStack(spacing: 16) {
                HStack {
                    Text("Stories")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        CreateStoryButton(onTap: onCreateStoryTap)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct StoriesHeader: View {
    let storiesCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                if storiesCount > 0 {
                    Text("\(storiesCount) active • disappear in 24h")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Text("Stories disappear after 24 hours")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            if storiesCount > 0 {
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct StoriesScrollView: View {
    let stories: [UserStoryData]
    let isLoading: Bool
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    // Group stories by user ID and filter to only include 24-hour stories
    private var activeStoriesByUser: [String: [UserStoryData]] {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // First filter stories to only include those within 24 hours
        let activeStories = stories.filter { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
        
        // Then group by user ID
        return Dictionary(grouping: activeStories) { $0.user.id }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                CreateStoryButton(onTap: onCreateStoryTap)
                
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        StoryPlaceholderView()
                    }
                } else {
                    // Display one circle per user with their active stories
                    ForEach(Array(activeStoriesByUser.keys), id: \.self) { userId in
                        if let userStories = activeStoriesByUser[userId], !userStories.isEmpty {
                            UserStoriesView(
                                userStories: userStories.sorted { story1, story2 in
                                    let formatter = ISO8601DateFormatter()
                                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                    
                                    guard let date1 = formatter.date(from: story1.createdAt),
                                          let date2 = formatter.date(from: story2.createdAt) else {
                                        return false
                                    }
                                    
                                    return date1 > date2 // Most recent first
                                },
                                onStoryTap: onStoryTap
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// New component to display all stories from a single user
struct UserStoriesView: View {
    let userStories: [UserStoryData]
    let onStoryTap: (UserStoryData) -> Void
    @State private var currentStoryIndex = 0
    
    private var user: UserStoryUser {
        userStories.first?.user ?? UserStoryUser(id: "", auth: nil, firstName: nil, lastName: nil, bio: nil, phoneNumber: nil, addressNo: nil, addressLine1: nil, addressLine2: nil, city: nil, district: nil)
    }
    
    // Filter stories to only include those within 24 hours
    private var activeStories: [UserStoryData] {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        return userStories.filter { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
    }
    
    var body: some View {
        // Only show if there are active stories
        if !activeStories.isEmpty {
            Button(action: {
                let validIndex = min(currentStoryIndex, activeStories.count - 1)
                onStoryTap(activeStories[validIndex])
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        // Display the current story image
                        AsyncImage(url: URL(string: activeStories[min(currentStoryIndex, activeStories.count - 1)].storyImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 66, height: 66)
                                .clipped()
                        } placeholder: {
                            Circle()
                                .fill(AppColors.input)
                                .frame(width: 66, height: 66)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .clipShape(Circle())
                        
                        // Story segments indicator with time-based styling
                        StorySegmentsIndicator(
                            totalSegments: activeStories.count, 
                            currentSegment: currentStoryIndex,
                            stories: activeStories
                        )
                    }
                    
                    Text(getUserDisplayName(from: user))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                        .frame(width: 76)
                        .truncationMode(.tail)
                }
            }
            .frame(width: 76)
            .onAppear {
                // Reset to first story when view appears
                currentStoryIndex = 0
            }
        }
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty {
            if let lastName = user.lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return "User"
    }
}

// New component to show the segmented circle indicator for multiple stories
struct StorySegmentsIndicator: View {
    let totalSegments: Int
    let currentSegment: Int
    let stories: [UserStoryData]
    
    var body: some View {
        Circle()
            .stroke(
                getStoryBorderGradient(),
                lineWidth: 3
            )
            .frame(width: 66, height: 66)
            .overlay(
                ZStack {
                    // Create segment indicators
                    ForEach(0..<totalSegments, id: \.self) { index in
                        SegmentArc(
                            index: index,
                            total: totalSegments,
                            isActive: index <= currentSegment,
                            storyAge: getStoryAge(at: index)
                        )
                    }
                }
            )
    }
    
    private func getStoryBorderGradient() -> LinearGradient {
        // Check if any story is close to expiring (less than 3 hours left)
        let hasExpiringStory = stories.contains { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            let now = Date()
            let hoursLeft = (24 * 60 * 60 - now.timeIntervalSince(storyDate)) / 3600
            return hoursLeft <= 3 && hoursLeft > 0
        }
        
        if hasExpiringStory {
            return LinearGradient(
                colors: [Color.orange, Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func getStoryAge(at index: Int) -> TimeInterval {
        guard index < stories.count else { return 0 }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let storyDate = formatter.date(from: stories[index].createdAt) else {
            return 0
        }
        
        return Date().timeIntervalSince(storyDate)
    }
}

// Individual segment arc for the story indicator
struct SegmentArc: View {
    let index: Int
    let total: Int
    let isActive: Bool
    let storyAge: TimeInterval
    
    var body: some View {
        let angleSize = 360.0 / Double(total)
        let startAngle = Double(index) * angleSize - 90
        let endAngle = startAngle + angleSize
        
        Path { path in
            path.addArc(
                center: CGPoint(x: 33, y: 33),
                radius: 33,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle - 4), // Gap between segments
                clockwise: false
            )
        }
        .stroke(getSegmentColor(), lineWidth: 3)
    }
    
    private func getSegmentColor() -> Color {
        if !isActive {
            return AppColors.mutedForeground
        }
        
        // Color based on story age
        let hoursOld = storyAge / 3600
        
        if hoursOld > 20 {
            return Color.red.opacity(0.8) // Very close to expiring
        } else if hoursOld > 12 {
            return Color.orange.opacity(0.9) // Getting old
        } else {
            return AppColors.primary // Fresh story
        }
    }
}

struct CreateStoryButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
                Text("Your Story")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                    .frame(width: 76)
            }
        }
        .frame(width: 76)
    }
}

struct StoryView: View {
    let story: UserStoryData
    let onTap: (UserStoryData) -> Void
    
    var body: some View {
        Button(action: {
            onTap(story)
        }) {
            VStack(spacing: 8) {
                ZStack {
                    AsyncImage(url: URL(string: story.storyImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 66)
                            .clipped()
                    } placeholder: {
                        Circle()
                            .fill(AppColors.input)
                            .frame(width: 66, height: 66)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                }
                
                Text(getUserDisplayName(from: story.user))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                    .frame(width: 76)
                    .truncationMode(.tail)
            }
        }
        .frame(width: 76)
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        return "User"
    }
}

struct StoryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppColors.input)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 2)
                )
                .redacted(reason: .placeholder)
            
            Text("Loading...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .redacted(reason: .placeholder)
        }
        .frame(width: 76)
    }
}

struct EmptyStoriesView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppColors.input)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.mutedForeground)
                )
            
            Text("No Recent Stories")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("Stories disappear after 24h")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppColors.mutedForeground.opacity(0.7))
        }
        .frame(width: 76)
    }
}


// Using the existing ImagePicker from your project
struct StoryOverlayView: View {
    let story: UserStoryData
    @Binding var isPresented: Bool
    let storiesViewModel: UserStoriesViewModel
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var currentStoryIndex: Int = 0
    @State private var userStories: [UserStoryData] = []
    
    private let storyDuration: Double = 5.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Left tap area for previous story
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: UIScreen.main.bounds.width * 0.3)
                    .onTapGesture {
                        showPreviousStory()
                    }
                
                Spacer()
                
                // Right tap area for next story
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: UIScreen.main.bounds.width * 0.3)
                    .onTapGesture {
                        showNextStory()
                    }
            }
            
            VStack(spacing: 0) {
                // Progress bars for all stories from this user
                HStack(spacing: 4) {
                    ForEach(0..<userStories.count, id: \.self) { index in
                        StoryProgressBar(
                            progress: index == currentStoryIndex ? progress : (index < currentStoryIndex ? 1.0 : 0.0)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                StoryHeader(
                    user: getCurrentStory().user,
                    createdAt: getCurrentStory().createdAt,
                    onClose: dismissStory
                )
                
                Spacer()
                
                StoryImageView(imageUrl: getCurrentStory().storyImageUrl)
                
                Spacer()
                
                if !getCurrentStory().description.isEmpty {
                    StoryDescriptionView(description: getCurrentStory().description)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadUserStories()
            startStoryTimer()
        }
        .onDisappear {
            stopStoryTimer()
        }
    }
    
    // Load all stories from the same user
    private func loadUserStories() {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // Find all active stories from the same user (within 24 hours)
        let allStories = storiesViewModel.userStories
        let userActiveStories = allStories.filter { userStory in
            // Same user check
            guard userStory.user.id == story.user.id else { return false }
            
            // 24-hour check
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: userStory.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
        
        userStories = userActiveStories.sorted { story1, story2 in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date1 = formatter.date(from: story1.createdAt),
                  let date2 = formatter.date(from: story2.createdAt) else {
                return false
            }
            
            return date1 > date2 // Most recent first
        }
        
        // If no active stories found, just use the current story if it's still active
        if userStories.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let storyDate = formatter.date(from: story.createdAt),
               storyDate >= twentyFourHoursAgo {
                userStories = [story]
            } else {
                // Story has expired, close the overlay
                dismissStory()
                return
            }
        }
        
        // Find the index of the current story
        if let index = userStories.firstIndex(where: { $0.id == story.id }) {
            currentStoryIndex = index
        } else {
            currentStoryIndex = 0
        }
    }
    
    // Get the current story being displayed
    private func getCurrentStory() -> UserStoryData {
        if userStories.isEmpty {
            return story
        }
        return userStories[currentStoryIndex]
    }
    
    // Show the previous story
    private func showPreviousStory() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            resetStoryTimer()
        }
    }
    
    // Show the next story
    private func showNextStory() {
        if currentStoryIndex < userStories.count - 1 {
            currentStoryIndex += 1
            resetStoryTimer()
        } else {
            // If we're at the last story, dismiss
            dismissStory()
        }
    }
    
    private func resetStoryTimer() {
        stopStoryTimer()
        progress = 0
        startStoryTimer()
    }
    
    private func startStoryTimer() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                progress += 0.1 / storyDuration
                if progress >= 1.0 {
                    // Auto-advance to next story when timer completes
                    if currentStoryIndex < userStories.count - 1 {
                        currentStoryIndex += 1
                        progress = 0
                    } else {
                        dismissStory()
                    }
                }
            }
        }
    }
    
    private func stopStoryTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func dismissStory() {
        stopStoryTimer()
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

struct StoryProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 3)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct StoryHeader: View {
    let user: UserStoryUser
    let createdAt: String
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(from: user))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(getUserDisplayName(from: user))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(getRelativeTime(from: createdAt))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty,
           let lastName = user.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        
        return "User"
    }
    
    private func getInitials(from user: UserStoryUser) -> String {
        let firstName = user.firstName ?? ""
        let lastName = user.lastName ?? ""
        
        let firstInitial = firstName.isEmpty ? "" : String(firstName.prefix(1))
        let lastInitial = lastName.isEmpty ? "" : String(lastName.prefix(1))
        
        if firstInitial.isEmpty && lastInitial.isEmpty {
            return "U"
        }
        
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func getRelativeTime(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "now"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        let hoursLeft = max(0, (24 * 60 * 60 - timeInterval) / 3600)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            let remaining = Int(hoursLeft)
            if remaining <= 3 {
                return "\(hours)h • \(remaining)h left"
            } else {
                return "\(hours)h"
            }
        } else {
            return "expired"
        }
    }
}

struct StoryImageView: View {
    let imageUrl: String
    
    var body: some View {
        CachedImage(url: imageUrl, contentMode: .fit) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(height: 300)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct StoryDescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
            .padding(.horizontal, 16)
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
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !hasTriedToFetchLocation {
                onLocationFetch(habitation.id)
                hasTriedToFetchLocation = true
            }
            
            if !hasTriedToFetchFeature {
                onFeatureFetch(habitation.id)
                hasTriedToFetchFeature = true
            }
        }
    }
}

struct HabitationHeader: View {
    let habitation: EnhancedHabitationData
    @Binding var isFollowing: Bool
    
    var body: some View {
        HStack {
            if let user = habitation.user {
                    UserAvatar(user: user)
                    UserInfo(user: user, createdAt: habitation.createdAt)
                } else {
                    // Fallback for missing user data
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("?")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                        )
                    
                    Text("Unknown User")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.foreground)
                }
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isFollowing ? AppColors.input : AppColors.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isFollowing ? AppColors.border : AppColors.primary, lineWidth: 1)
                        )
                )
        }
    }
}

struct MenuButton: View {
    var body: some View {
        Button(action: {}) {
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
            CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(width: 320, height: 280)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
            .frame(width: 320, height: 280)
            .clipped()
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .padding(.bottom, 16)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.input)
                .frame(width: 320, height: 280)
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
        Button(action: {}) {
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
                
                if let user = habitation.user {
                    Text("\(user.city), \(user.district)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Text("Unknown location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
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

