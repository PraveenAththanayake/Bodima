import SwiftUI

struct HomeView: View {
    @StateObject private var habitationViewModel = HabitationViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var locationViewModel = HabitationLocationViewModel()
    @StateObject private var featureViewModel = HabitationFeatureViewModel()
    @StateObject private var userStoriesViewModel = UserStoriesViewModel()
    @State private var searchText = ""
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
                HeaderView(searchText: $searchText)
                MainContentView(
                    habitations: habitationViewModel.enhancedHabitations,
                    isLoading: habitationViewModel.isFetchingEnhancedHabitations,
                    searchText: searchText,
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
        Button(action: {}) {
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

struct MainContentView: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let searchText: String
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
    }
}

struct StoriesHeader: View {
    let storiesCount: Int
    
    var body: some View {
        HStack {
            Text("Stories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            if storiesCount > 0 {
                Text("(\(storiesCount))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("View All")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary)
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
    
    // Group stories by user ID
    private var storiesByUser: [String: [UserStoryData]] {
        Dictionary(grouping: stories) { $0.user.id }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                CreateStoryButton(onTap: onCreateStoryTap)
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        StoryPlaceholderView()
                    }
                } else if stories.isEmpty {
                    EmptyStoriesView()
                } else {
                    // Display one circle per user with their stories
                    ForEach(Array(storiesByUser.keys), id: \.self) { userId in
                        if let userStories = storiesByUser[userId], !userStories.isEmpty {
                            UserStoriesView(
                                userStories: userStories,
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
    
    var body: some View {
        Button(action: {
            onStoryTap(userStories[currentStoryIndex])
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Display the current story image
                    AsyncImage(url: URL(string: userStories[currentStoryIndex].storyImageUrl)) { image in
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
                    
                    // Story segments indicator
                    StorySegmentsIndicator(totalSegments: userStories.count, currentSegment: currentStoryIndex)
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
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
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
                            isActive: index <= currentSegment
                        )
                    }
                }
            )
    }
}

// Individual segment arc for the story indicator
struct SegmentArc: View {
    let index: Int
    let total: Int
    let isActive: Bool
    
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
        .stroke(isActive ? AppColors.primary : AppColors.mutedForeground, lineWidth: 3)
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
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.mutedForeground)
                )
            
            Text("No Stories")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(width: 76)
    }
}

struct CreateStoryView: View {
    @ObservedObject var viewModel: UserStoriesViewModel
    @ObservedObject var profileViewModel = ProfileViewModel()
    let userId: String
    @Binding var isPresented: Bool
    @State private var description: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    
    // Extract gradient as computed property to reduce compiler complexity
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.2, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.4, blue: 0.9)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var imageSelectionGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var textEditorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.04)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Image Selection Section
                    imageSelectionSection
                    
                    // Description Section
                    descriptionSection
                    
                    // Error Message
                    errorMessageView
                    
                    // Post Button
                    postButton
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                message: Text("Choose how you'd like to add a photo"),
                buttons: [
                    .default(Text("Photo Library")) {
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: viewModel.storyCreationSuccess) { success in
            if success {
                isPresented = false
                viewModel.resetStoryCreationState()
                // Reset form
                selectedImage = nil
                description = ""
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            Text("Create Story")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Add Photo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            Button(action: {
                showImagePicker = true
            }) {
                imageSelectionContent
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var imageSelectionContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(imageSelectionGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(height: 200)
            
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(20)
            } else {
                emptyImagePlaceholder
            }
        }
    }
    
    private var emptyImagePlaceholder: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("Tap to add photo")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Choose from gallery or take a new photo")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    private var descriptionSection: some View {
        VStack(spacing: 16) {
            Text("Add Description")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(textEditorGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 100)
                
                TextEditor(text: $description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .frame(minHeight: 100)
                    .padding(16)
                
                if description.isEmpty {
                    Text("Tell your story...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 24)
                        .padding(.leading, 20)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = viewModel.storyCreationMessage, !viewModel.storyCreationSuccess {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var postButton: some View {
        Button(action: {
            if let selectedImage = selectedImage {
                // Convert image to base64 or upload to server
                // For now, we'll use a placeholder URL
                let imageUrl = "https://example.com/images/story1.jpg"
                // Get user ID from the correct location in your data structure
                let userIdToUse = getUserId()
                
                guard !userIdToUse.isEmpty else {
                    print("❌ Error: User ID is empty or nil")
                    return
                }
                
                viewModel.createUserStory(
                    userId: userIdToUse,
                    description: description,
                    storyImageUrl: imageUrl
                )
            }
        }) {
            HStack(spacing: 8) {
                if viewModel.isCreatingStory {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(viewModel.isCreatingStory ? "Posting..." : "Post Story")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if canPostStory {
                        buttonGradient
                    } else {
                        Color.white.opacity(0.2)
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .disabled(!canPostStory || viewModel.isCreatingStory)
        .scaleEffect(canPostStory ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canPostStory)
    }
    
    private var canPostStory: Bool {
        selectedImage != nil && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Helper Methods
    
    /// Get user ID from various possible sources
    private func getUserId() -> String {
        // Option 1: Try to get from the passed userId parameter
        if !userId.isEmpty {
            return userId
        }
        
        // Option 2: Try to get from profile data - adjust path based on your ProfileData structure
        // Common patterns in profile data structures:
        if let profileId = profileViewModel.userProfile?.id {
            return profileId
        }
        
        // Option 3: Try to get from auth data within profile (based on your ProfileViewModel code)
        if let authId = profileViewModel.userProfile?.auth.id {
            return authId
        }
        
        // Option 4: Try to get from UserDefaults or AuthViewModel
        if let storedUserId = UserDefaults.standard.string(forKey: "user_id") {
            return storedUserId
        }
        
        // Option 5: Try to get from AuthViewModel if available
        // Uncomment if you have access to AuthViewModel
        // if let authUserId = AuthViewModel.shared.currentUser?.id {
        //     return authUserId
        // }
        
        print("❌ Warning: Could not find user ID from any source")
        return ""
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
        // Find all stories from the same user
        let allStories = storiesViewModel.userStories
        userStories = allStories.filter { $0.user.id == story.user.id }
        
        // If no other stories found, just use the current story
        if userStories.isEmpty {
            userStories = [story]
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
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
}

struct StoryImageView: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(height: 300)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
        }
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

