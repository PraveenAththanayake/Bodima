import SwiftUI
import UIKit

// MARK: - Main Home View
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
    // Spotlight deep link state
    @State private var spotlightTargetHabitation: EnhancedHabitationData? = nil
    @State private var showSpotlightDetail: Bool = false
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
        // Present detail when triggered by Spotlight
        .sheet(isPresented: $showSpotlightDetail) {
            if let habitation = spotlightTargetHabitation {
                MyHabitationDetailView(
                    habitation: habitation,
                    locationData: locationDataCache[habitation.id],
                    featureData: featureDataCache[habitation.id]
                )
            }
        }
        // Listen for Core Spotlight deep links
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenHabitationFromSpotlight"))) { notification in
            guard let userInfo = notification.userInfo,
                  let habitationId = userInfo["habitationId"] as? String else { return }
            // Try to find locally first
            if let match = habitationViewModel.enhancedHabitations.first(where: { $0.id == habitationId }) {
                spotlightTargetHabitation = match
                showSpotlightDetail = true
            } else {
                // Fetch by ID and present when loaded
                habitationViewModel.fetchEnhancedHabitationById(habitationId: habitationId)
            }
        }
        // When a single habitation is fetched, present it if awaiting Spotlight navigation
        .onChange(of: habitationViewModel.selectedEnhancedHabitation?.id) { _ in
            if let fetched = habitationViewModel.selectedEnhancedHabitation {
                spotlightTargetHabitation = fetched
                showSpotlightDetail = true
            }
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
    
    // MARK: - Data Loading Methods
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









