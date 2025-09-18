import Foundation
import SwiftUI

/**
 * User Stories Data Models
 * Defines the structure for user story data and API communication.
 */

/**
 * Represents a complete user story with detailed user information.
 * Used for displaying stories with full user context.
 */
struct UserStoryData: Codable {
    let id: String
    let user: UserStoryUser
    let storyImageUrl: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case storyImageUrl
        case description
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

/**
 * Represents user information associated with a story.
 * Contains profile details for story attribution and display.
 */
struct UserStoryUser: Codable {
    let id: String
    let auth: String?
    let firstName: String?
    let lastName: String?
    let bio: String?
    let phoneNumber: String?
    let addressNo: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let district: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case auth
        case firstName
        case lastName
        case bio
        case phoneNumber
        case addressNo
        case addressLine1
        case addressLine2
        case city
        case district
    }
}

/**
 * Simplified user story data returned from creation API.
 * Contains basic story information with user ID reference.
 */
struct CreateUserStoryData: Codable {
    let id: String
    let user: String  // Just the user ID string
    let storyImageUrl: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case storyImageUrl
        case description
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

/**
 * API Request and Response Models
 */

/**
 * Request structure for creating a new user story.
 */
struct CreateUserStoryRequest: Codable {
    let user: String
    let description: String
    let storyImageUrl: String
}

/**
 * API response structure for story creation operations.
 */
struct CreateUserStoryResponse: Codable {
    let success: Bool
    let message: String
    let data: CreateUserStoryData?
}

/**
 * API response structure for fetching user stories.
 */
struct GetUserStoriesResponse: Codable {
    let success: Bool
    let data: [UserStoryData]
}

/**
 * UserStoriesViewModel manages user story operations for the Bodima application.
 * Handles story creation, fetching, automatic expiration management, and provides
 * comprehensive state management for story-related UI components.
 * 
 * Key Features:
 * - Complete story lifecycle management with validation
 * - Automatic 24-hour story expiration with cleanup
 * - Real-time story filtering and sorting
 * - Timer-based auto-refresh for expired content
 * - Comprehensive error handling and state management
 * - User display formatting and location processing
 */
@MainActor
class UserStoriesViewModel: ObservableObject {
    
    /**
     * Published properties for story data and state management.
     * These properties provide reactive updates to SwiftUI views.
     */
    
    /// Collection of all user stories from the server
    @Published var userStories: [UserStoryData] = []
    
    /// General loading state indicator for story fetch operations
    @Published var isLoading = false
    
    /// General error message for story operations
    @Published var errorMessage: String?
    
    /// Flag indicating if there's an active error state
    @Published var hasError = false
    
    /**
     * Story creation state management properties.
     */
    
    /// Loading state indicator for story creation operations
    @Published var isCreatingStory = false
    
    /// Success flag for story creation completion
    @Published var storyCreationSuccess = false
    
    /// Success or error message for story creation operations
    @Published var storyCreationMessage: String?
    
    /**
     * Dependencies and initialization.
     */
    
    /// Network manager instance for API communication
    private let networkManager = NetworkManager.shared
    
    /// Timer for automatic story cleanup and refresh
    private var autoRefreshTimer: Timer?
    
    /**
     * Core story management methods.
     */
    
    /**
     * Fetches user stories from the server with authentication validation.
     * Handles the complete story retrieval flow including authentication,
     * request processing, and response handling.
     */
    func fetchUserStories() {
        guard let token = validateAuthToken() else { return }
        
        prepareStoryFetch()
        let headers = buildAuthHeaders(token: token)
        
        processStoryFetchRequest(headers: headers)
    }
    
    /**
     * Creates a new user story with comprehensive validation and state management.
     * Handles the complete story creation flow including parameter validation,
     * request construction, API communication, and response processing.
     * 
     * @param userId The unique identifier of the user creating the story
     * @param description The story description text
     * @param storyImageUrl The URL of the story image
     */
    func createUserStory(
        userId: String,
        description: String,
        storyImageUrl: String
    ) {
        guard validateStoryCreationParameters(
            userId: userId,
            description: description,
            storyImageUrl: storyImageUrl
        ) else { return }
        
        guard let token = validateAuthToken() else {
            showStoryCreationError("Authentication token not found. Please login again.")
            return
        }
        
        prepareStoryCreation()
        let request = buildCreateStoryRequest(
            userId: userId,
            description: description,
            storyImageUrl: storyImageUrl
        )
        let headers = buildAuthHeaders(token: token)
        
        processStoryCreationRequest(request: request, headers: headers)
    }
    
    /**
     * Refreshes user stories by re-fetching from the server.
     * Convenience method for manual refresh operations.
     */
    func refreshUserStories() {
        fetchUserStories()
    }
    
    /**
     * Starts automatic refresh timer for expired story cleanup.
     * Schedules periodic cleanup every 5 minutes to remove expired stories.
     */
    func startAutoRefresh() {
        // Refresh every 5 minutes to remove expired stories
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            DispatchQueue.main.async {
                self.cleanupExpiredStories()
            }
        }
    }
    
    /**
     * Stops the automatic refresh timer.
     * Used for cleanup when the view model is deallocated.
     */
    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    /**
     * Non-isolated timer cleanup for deinitializer.
     * This method can be called from deinit without main actor isolation.
     */
    nonisolated private func cleanupTimer() {
        // Timer cleanup that can be called from deinit
        // We access the timer property through MainActor.assumeIsolated
        // since deinit guarantees no other code is running on this instance
        MainActor.assumeIsolated {
            autoRefreshTimer?.invalidate()
            autoRefreshTimer = nil
        }
    }
    
    /**
     * Private helper methods for story management.
     */
    
    /**
     * Cleans up expired stories that are older than 24 hours.
     * Automatically filters out stories beyond the 24-hour window.
     */
    private func cleanupExpiredStories() {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        let initialCount = userStories.count
        
        userStories = userStories.filter { story in
            guard let storyDate = parseStoryDate(story.createdAt) else {
                return false // Remove stories with invalid dates
            }
            
            return storyDate >= twentyFourHoursAgo
        }
        
        let removedCount = initialCount - userStories.count
        if removedCount > 0 {
            print("📱 Cleaned up \(removedCount) expired stories")
        }
    }
    
    /**
     * Private helper methods for validation and request building.
     */
    
    /**
     * Validates authentication token from UserDefaults.
     * 
     * @return Authentication token if valid, nil otherwise
     */
    private func validateAuthToken() -> String? {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return nil
        }
        return token
    }
    
    /**
     * Validates story creation parameters for completeness.
     * 
     * @param userId The user ID to validate
     * @param description The story description to validate
     * @param storyImageUrl The story image URL to validate
     * @return True if all parameters are valid, false otherwise
     */
    private func validateStoryCreationParameters(
        userId: String,
        description: String,
        storyImageUrl: String
    ) -> Bool {
        guard !userId.isEmpty else {
            showStoryCreationError("User ID is required")
            return false
        }
        
        guard !description.isEmpty else {
            showStoryCreationError("Story description is required")
            return false
        }
        
        guard !storyImageUrl.isEmpty else {
            showStoryCreationError("Story image URL is required")
            return false
        }
        
        return true
    }
    
    /**
     * Builds authentication headers for API requests.
     * 
     * @param token The authentication token
     * @return Dictionary of authentication headers
     */
    private func buildAuthHeaders(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    /**
     * Builds a structured story creation request.
     * 
     * @param userId The user ID
     * @param description The story description
     * @param storyImageUrl The story image URL
     * @return Structured CreateUserStoryRequest object
     */
    private func buildCreateStoryRequest(
        userId: String,
        description: String,
        storyImageUrl: String
    ) -> CreateUserStoryRequest {
        return CreateUserStoryRequest(
            user: userId,
            description: description,
            storyImageUrl: storyImageUrl
        )
    }
    
    /**
     * Prepares the view model state for story fetch operations.
     */
    private func prepareStoryFetch() {
        isLoading = true
        clearError()
    }
    
    /**
     * Prepares the view model state for story creation operations.
     */
    private func prepareStoryCreation() {
        isCreatingStory = true
        clearStoryCreationError()
    }
    
    /**
     * Processes the story fetch request through the network manager.
     * 
     * @param headers Authentication headers for the request
     */
    private func processStoryFetchRequest(headers: [String: String]) {
        networkManager.requestWithHeaders(
            endpoint: .getUserStories,
            headers: headers,
            responseType: GetUserStoriesResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleStoryFetchResponse(result)
            }
        }
    }
    
    /**
     * Processes the story creation request through the network manager.
     * 
     * @param request The story creation request
     * @param headers Authentication headers for the request
     */
    private func processStoryCreationRequest(
        request: CreateUserStoryRequest,
        headers: [String: String]
    ) {
        networkManager.requestWithHeaders(
            endpoint: .createStories,
            body: request,
            headers: headers,
            responseType: CreateUserStoryResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingStory = false
                self?.handleStoryCreationResponse(result)
            }
        }
    }
    
    /**
     * Response handling methods.
     */
    
    /**
     * Handles the API response for story fetch operations.
     * 
     * @param result The API response result
     */
    private func handleStoryFetchResponse(_ result: Result<GetUserStoriesResponse, Error>) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetUserStories success: \(response.success)")
            print("🔍 DEBUG - GetUserStories data count: \(response.data.count)")
            
            if response.success {
                userStories = response.data
                print("✅ User stories fetched successfully - Count: \(response.data.count)")
            } else {
                showError("Failed to fetch user stories")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Network error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles the API response for story creation operations.
     * 
     * @param result The API response result
     */
    private func handleStoryCreationResponse(_ result: Result<CreateUserStoryResponse, Error>) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - CreateStory success: \(response.success)")
            print("🔍 DEBUG - CreateStory message: \(response.message)")
            print("🔍 DEBUG - CreateStory data: \(String(describing: response.data))")
            
            if response.success {
                handleSuccessfulStoryCreation(message: response.message)
            } else {
                showStoryCreationError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Create story error: \(error)")
            handleStoryCreationError(error)
        }
    }
    
    /**
     * Handles successful story creation by updating state and refreshing stories.
     * 
     * @param message Success message from the API
     */
    private func handleSuccessfulStoryCreation(message: String) {
        storyCreationSuccess = true
        storyCreationMessage = message
        print("✅ User story created successfully")
        
        // Refresh the entire list to get the complete data with user objects
        // Since the create response only contains user ID, we need to fetch
        // the complete list to get the full user data
        fetchUserStories()
    }
    
    /**
     * Error handling methods.
     */
    
    /**
     * Handles network errors for story fetch operations.
     * 
     * @param error The network error that occurred
     */
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showError(message)
                
            case .serverError(let message):
                showError("Server error: \(message)")
                
            default:
                showError(networkError.localizedDescription)
            }
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Handles network errors for story creation operations.
     * 
     * @param error The network error that occurred
     */
    private func handleStoryCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showStoryCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showStoryCreationError(message)
                
            case .serverError(let message):
                showStoryCreationError("Server error: \(message)")
                
            default:
                showStoryCreationError(networkError.localizedDescription)
            }
        } else {
            showStoryCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * State management methods.
     */
    
    /**
     * Shows a general error message and updates error state.
     * 
     * @param message The error message to display
     */
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ User Stories Error: \(message)")
    }
    
    /**
     * Clears the general error state.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Shows a story creation error message and updates creation state.
     * 
     * @param message The error message to display
     */
    private func showStoryCreationError(_ message: String) {
        storyCreationMessage = message
        storyCreationSuccess = false
        print("❌ Story Creation Error: \(message)")
    }
    
    /**
     * Clears the story creation error state.
     */
    private func clearStoryCreationError() {
        storyCreationMessage = nil
        storyCreationSuccess = false
    }
    
    /**
     * Utility methods for date processing and user display formatting.
     */
    
    /**
     * Formats ISO8601 date strings into user-friendly display format.
     * 
     * @param dateString The ISO8601 formatted date string to format
     * @return Human-readable date and time string
     */
    func formatDate(_ dateString: String) -> String {
        guard let date = parseStoryDate(dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    /**
     * Parses ISO8601 date strings with proper error handling.
     * 
     * @param dateString The date string to parse
     * @return Parsed Date object or nil if parsing fails
     */
    private func parseStoryDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    /**
     * Generates relative time strings for story timestamps.
     * 
     * @param dateString The ISO8601 date string to process
     * @return Relative time string (e.g., "2h ago", "Just now")
     */
    func getRelativeTimeString(from dateString: String) -> String {
        guard let date = parseStoryDate(dateString) else {
            return "Unknown time"
        }
        
        return calculateRelativeTime(from: date)
    }
    
    /**
     * Calculates relative time from a given date to now.
     * 
     * @param date The date to calculate relative time from
     * @return Formatted relative time string
     */
    private func calculateRelativeTime(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    /**
     * 24-hour story management methods.
     */
    
    /**
     * Checks if a story is within the 24-hour visibility window.
     * 
     * @param story The story to check
     * @return True if story is within 24 hours, false otherwise
     */
    func isStoryWithin24Hours(_ story: UserStoryData) -> Bool {
        guard let storyDate = parseStoryDate(story.createdAt) else {
            return false
        }
        
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        return storyDate >= twentyFourHoursAgo
    }
    
    /**
     * Calculates remaining hours before a story expires.
     * 
     * @param story The story to check expiration for
     * @return Number of hours remaining before expiration
     */
    func getRemainingHours(for story: UserStoryData) -> Int {
        guard let storyDate = parseStoryDate(story.createdAt) else {
            return 0
        }
        
        let now = Date()
        let twentyFourHoursLater = storyDate.addingTimeInterval(24 * 60 * 60)
        let remainingTime = twentyFourHoursLater.timeIntervalSince(now)
        
        return max(0, Int(remainingTime / 3600))
    }
    
    /**
     * Generates WhatsApp-style compact time display for stories.
     * 
     * @param dateString The ISO8601 date string to process
     * @return Compact time string (e.g., "2h", "now")
     */
    func getWhatsAppStyleTime(from dateString: String) -> String {
        guard let date = parseStoryDate(dateString) else {
            return "Unknown"
        }
        
        return generateCompactTimeString(from: date)
    }
    
    /**
     * Generates compact time representation for UI display.
     * 
     * @param date The date to generate compact time for
     * @return Compact time string
     */
    private func generateCompactTimeString(from date: Date) -> String {
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
            // This should rarely happen since we filter out 24+ hour old stories
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
    
    /**
     * User display formatting methods.
     */
    
    /**
     * Generates a display-friendly name from user story data.
     * 
     * @param user The user story user data
     * @return Formatted display name with fallback options
     */
    func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty,
           let lastName = user.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        
        return "Unknown User"
    }
    
    /**
     * Generates a formatted location string from user address data.
     * 
     * @param user The user story user data
     * @return Formatted location string with fallback
     */
    func getUserLocation(from user: UserStoryUser) -> String {
        var locationComponents: [String] = []
        
        if let city = user.city, !city.isEmpty {
            locationComponents.append(city)
        }
        
        if let district = user.district, !district.isEmpty {
            locationComponents.append(district)
        }
        
        return locationComponents.isEmpty ? "Unknown Location" : locationComponents.joined(separator: ", ")
    }
    
    /**
     * Computed properties for story analysis and UI presentation.
     */
    
    /**
     * Count of active stories within the 24-hour window.
     */
    var storiesCount: Int {
        return sortedStories.count // Use filtered stories count
    }
    
    /**
     * Total count of all stories regardless of expiration.
     */
    var totalStoriesCount: Int {
        return userStories.count // All stories regardless of age
    }
    
    /**
     * Flag indicating if there are any active stories to display.
     */
    var hasStories: Bool {
        return !sortedStories.isEmpty // Check filtered stories
    }
    
    /**
     * Flag indicating if there are active stories within 24 hours.
     */
    var hasActiveStories: Bool {
        return !sortedStories.isEmpty
    }
    
    /**
     * Count of expired stories that have been filtered out.
     */
    var expiredStoriesCount: Int {
        return totalStoriesCount - storiesCount
    }
    
    /**
     * Filtered and sorted stories within the 24-hour visibility window.
     * Automatically excludes expired stories and sorts by creation date.
     */
    var sortedStories: [UserStoryData] {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        
        return userStories
            .filter { story in
                guard let storyDate = parseStoryDate(story.createdAt) else {
                    return false // Exclude stories with invalid dates
                }
                
                // Only include stories from the last 24 hours
                return storyDate >= twentyFourHoursAgo
            }
            .sorted { story1, story2 in
                guard let date1 = parseStoryDate(story1.createdAt),
                      let date2 = parseStoryDate(story2.createdAt) else {
                    return false
                }
                
                return date1 > date2 // Most recent first
            }
    }
    
    /**
     * Data management and cleanup methods.
     */
    
    /**
     * Clears all story data and resets error states.
     * Used for logout operations and complete data cleanup.
     */
    func clearStories() {
        userStories.removeAll()
        clearError()
        clearStoryCreationError()
        stopAutoRefresh()
    }
    
    /**
     * Resets story creation state to initial values.
     * Clears creation flags and messages for new operations.
     */
    func resetStoryCreationState() {
        isCreatingStory = false
        storyCreationSuccess = false
        storyCreationMessage = nil
    }
    
    /**
     * Story collection management methods.
     */
    
    /**
     * Removes a specific story from the collection by ID.
     * 
     * @param storyId The unique identifier of the story to remove
     */
    func removeStory(withId storyId: String) {
        userStories.removeAll { $0.id == storyId }
    }
    
    /**
     * Retrieves a specific story from the collection by ID.
     * 
     * @param storyId The unique identifier of the story to retrieve
     * @return The story data if found, nil otherwise
     */
    func getStory(withId storyId: String) -> UserStoryData? {
        return userStories.first { $0.id == storyId }
    }
    
    /**
     * Deinitializer to ensure proper cleanup of timers.
     */
    deinit {
        cleanupTimer()
    }
}
