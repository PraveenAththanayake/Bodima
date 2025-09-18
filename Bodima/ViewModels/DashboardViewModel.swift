import Foundation
import SwiftUI
import CoreData

/**
 * DashboardViewModel - Comprehensive Dashboard Data Management System
 *
 * Manages dashboard data retrieval, caching, and presentation for the Bodima application.
 * Provides offline functionality through Core Data integration and handles real-time
 * synchronization with the backend server.
 *
 * Key Responsibilities:
 * - Fetch and manage dashboard data and summary statistics
 * - Implement offline-first architecture with Core Data caching
 * - Provide computed properties for easy UI data binding
 * - Handle network errors and authentication failures
 * - Support Core Data bypass mode for troubleshooting
 * - Manage data filtering and sorting operations
 * - Provide utility methods for data formatting and presentation
 */
@MainActor
class DashboardViewModel: ObservableObject {
    
    /// Complete dashboard data including statistics, habitations, and recent activity
    @Published var dashboardData: DashboardData?
    
    /// Summary statistics for quick dashboard overview
    @Published var dashboardSummary: DashboardSummary?
    
    /// Loading state for UI feedback during API operations
    @Published var isLoading = false
    
    /// Current error message for user display
    @Published var errorMessage: String?
    
    /// Flag indicating if there's an active error
    @Published var hasError = false
    
    /// Flag indicating if app is operating in offline mode
    @Published var isOfflineMode = false
    
    /// Timestamp of last successful data synchronization
    @Published var lastSyncTime: Date?
    
    /// Network manager for API communication
    private let networkManager = NetworkManager.shared
    
    /// Core Data manager for local persistence and offline functionality
    private let coreDataManager = CoreDataManager.shared
    
    /**
     * Fetches comprehensive dashboard data for a specific user.
     * Implements offline-first architecture by checking cache before making API calls.
     * Supports Core Data bypass mode for troubleshooting scenarios.
     * 
     * @param userId The unique identifier for the user whose dashboard to fetch
     */
    func fetchDashboardData(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        loadCachedDataIfAvailable()
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            isOfflineMode = true
            return
        }
        
        performDashboardDataRequest(userId: userId, token: token)
    }
    
    /**
     * Loads cached dashboard data if available and bypass mode is disabled.
     * Provides immediate data display while fresh data is being fetched.
     */
    private func loadCachedDataIfAvailable() {
        if !isCoreDataBypassMode {
            if let cachedData = coreDataManager.fetchDashboardData() {
                dashboardData = cachedData
                lastSyncTime = coreDataManager.getLastUpdateTime()
                print("✅ Loaded dashboard data from Core Data cache")
            }
        } else {
            print("🚫 Core Data bypass mode enabled - skipping cache load")
        }
    }
    
    /**
     * Performs the actual API request to fetch dashboard data.
     * Handles response processing and error management.
     */
    private func performDashboardDataRequest(userId: String, token: String) {
        isLoading = true
        clearError()
        isOfflineMode = false
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getDashboard(userId: userId),
            headers: headers,
            responseType: GetDashboardResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDashboardDataResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from dashboard data API call.
     * Processes successful responses and manages error scenarios with offline fallback.
     */
    private func handleDashboardDataResponse(_ result: Result<GetDashboardResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetDashboard success: \(response.success)")
            print("🔍 DEBUG - GetDashboard data: \(String(describing: response.data))")
            
            if response.success, let data = response.data {
                processDashboardDataSuccess(data)
            } else {
                showError(response.message ?? "Failed to fetch dashboard data")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch dashboard error: \(error)")
            handleNetworkError(error)
            enableOfflineModeIfDataAvailable()
        }
    }
    
    /**
     * Processes successful dashboard data response.
     * Updates local data and handles caching based on bypass mode settings.
     */
    private func processDashboardDataSuccess(_ data: DashboardData) {
        dashboardData = data
        lastSyncTime = Date()
        
        if !isCoreDataBypassMode {
            coreDataManager.saveDashboardData(data)
            print("✅ Dashboard data fetched and cached successfully")
        } else {
            print("✅ Dashboard data fetched successfully (bypass mode - not cached)")
        }
    }
    
    /**
     * Enables offline mode if cached data is available when network request fails.
     * Provides graceful degradation for network connectivity issues.
     */
    private func enableOfflineModeIfDataAvailable() {
        if dashboardData != nil {
            isOfflineMode = true
            print("📱 Showing cached data in offline mode")
        }
    }
    
    /**
     * Fetches dashboard summary statistics for a specific user.
     * Provides lightweight overview data for quick dashboard insights.
     * 
     * @param userId The unique identifier for the user whose summary to fetch
     */
    func fetchDashboardSummary(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        performDashboardSummaryRequest(userId: userId, token: token)
    }
    
    /**
     * Performs the API request to fetch dashboard summary data.
     * Handles authentication and response processing.
     */
    private func performDashboardSummaryRequest(userId: String, token: String) {
        isLoading = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getDashboardSummary(userId: userId),
            headers: headers,
            responseType: GetDashboardSummaryResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDashboardSummaryResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from dashboard summary API call.
     * Updates summary data on success or displays error messages.
     */
    private func handleDashboardSummaryResponse(_ result: Result<GetDashboardSummaryResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetDashboardSummary success: \(response.success)")
            print("🔍 DEBUG - GetDashboardSummary data: \(String(describing: response.data))")
            
            if response.success {
                dashboardSummary = response.data
                print("✅ Dashboard summary fetched successfully")
            } else {
                showError(response.message ?? "Failed to fetch dashboard summary")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch dashboard summary error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Convenience method to fetch dashboard data for the currently authenticated user.
     * Automatically resolves user ID from profile and handles error cases.
     */
    func fetchDashboardForCurrentUser() {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.fetchDashboardData(userId: userId)
        }
    }
    
    /**
     * Convenience method to fetch dashboard summary for the currently authenticated user.
     * Automatically resolves user ID from profile and handles error cases.
     */
    func fetchDashboardSummaryForCurrentUser() {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.fetchDashboardSummary(userId: userId)
        }
    }
    
    /**
     * Computed properties for easy access to dashboard statistics and data.
     * Provide safe access with default values when data is not available.
     */
    
    /// Total earnings across all habitations
    var totalEarnings: Double {
        return dashboardData?.statistics.totalEarnings ?? 0.0
    }
    
    /// Total number of habitations owned by the user
    var totalHabitations: Int {
        return dashboardData?.statistics.totalHabitations ?? 0
    }
    
    /// Number of habitations currently available for booking
    var availableHabitations: Int {
        return dashboardData?.statistics.availableHabitations ?? 0
    }
    
    /// Number of habitations currently reserved
    var reservedHabitations: Int {
        return dashboardData?.statistics.reservedHabitations ?? 0
    }
    
    /// Total number of reservations across all habitations
    var totalReservations: Int {
        return dashboardData?.statistics.totalReservations ?? 0
    }
    
    /// Number of currently active reservations
    var activeReservations: Int {
        return dashboardData?.statistics.activeReservations ?? 0
    }
    
    /// Number of completed reservations
    var completedReservations: Int {
        return dashboardData?.statistics.completedReservations ?? 0
    }
    
    /// Total number of payments processed
    var totalPayments: Int {
        return dashboardData?.statistics.totalPayments ?? 0
    }
    
    /// Recent reservation activity for dashboard display
    var recentReservations: [DashboardReservation] {
        return dashboardData?.recentActivity.recentReservations ?? []
    }
    
    /// Recent payment activity for dashboard display
    var recentPayments: [DashboardPayment] {
        return dashboardData?.recentActivity.recentPayments ?? []
    }
    
    /// All habitations owned by the user
    var habitations: [DashboardHabitation] {
        return dashboardData?.habitations ?? []
    }
    
    /**
     * Data filtering and sorting methods for dashboard analytics and display.
     * Provide convenient access to filtered subsets of dashboard data.
     */
    
    /// Returns habitations that are currently available for booking
    func getAvailableHabitations() -> [DashboardHabitation] {
        return habitations.filter { !$0.isReserved }
    }
    
    /// Returns habitations that are currently reserved
    func getReservedHabitations() -> [DashboardHabitation] {
        return habitations.filter { $0.isReserved }
    }
    
    /// Returns habitations that have active reservations
    func getHabitationsWithActiveReservations() -> [DashboardHabitation] {
        return habitations.filter { $0.activeReservation != nil }
    }
    
    /// Returns habitations that have processed payments
    func getHabitationsWithPayments() -> [DashboardHabitation] {
        return habitations.filter { $0.paymentCount > 0 }
    }
    
    /// Returns habitations sorted by total earnings in descending order
    func getTopEarningHabitations() -> [DashboardHabitation] {
        return habitations.sorted { $0.totalEarnings > $1.totalEarnings }
    }
    
    /// Returns a limited number of recent reservations for dashboard display
    func getRecentReservations(limit: Int = 5) -> [DashboardReservation] {
        return Array(recentReservations.prefix(limit))
    }
    
    /// Returns a limited number of recent payments for dashboard display
    func getRecentPayments(limit: Int = 5) -> [DashboardPayment] {
        return Array(recentPayments.prefix(limit))
    }
    
    /**
     * Resolves user ID from current authentication state or profile data.
     * Attempts multiple sources and validates profile completion before returning ID.
     * 
     * @param completion Callback with resolved user ID or nil if unavailable
     */
    private func getUserIdFromProfile(completion: @escaping (String?) -> Void) {
        guard let userId = AuthViewModel.shared.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            completion(nil)
            return
        }
        
        let profileViewModel = ProfileViewModel()
        profileViewModel.fetchUserProfile(userId: userId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.waitForProfileCompletion(profileViewModel: profileViewModel, completion: completion)
        }
    }
    
    /**
     * Waits for profile loading to complete and returns the profile ID.
     * Implements polling mechanism to check profile loading status.
     */
    private func waitForProfileCompletion(profileViewModel: ProfileViewModel, completion: @escaping (String?) -> Void) {
        if let profileId = profileViewModel.userProfile?.id {
            completion(profileId)
        } else if !profileViewModel.isLoading && profileViewModel.hasError {
            completion(nil)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitForProfileCompletion(profileViewModel: profileViewModel, completion: completion)
            }
        }
    }
    
    /**
     * Handles network errors with appropriate user feedback and recovery actions.
     * Provides specific handling for different error types including authentication failures.
     */
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            handleTypedNetworkError(networkError)
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Handles specific NetworkError types with tailored responses.
     * Includes automatic token cleanup for unauthorized errors.
     */
    private func handleTypedNetworkError(_ networkError: NetworkError) {
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
    }
    
    /**
     * Displays error message to user and logs for debugging.
     * Sets error flags for UI state management.
     */
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Dashboard Error: \(message)")
    }
    
    /**
     * Clears current error state and message.
     * Used when starting new operations or on successful completion.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Utility methods for data formatting and dashboard management.
     * Provide common functionality for UI presentation and data manipulation.
     */
    
    /**
     * Formats monetary amounts with proper currency symbols and localization.
     * 
     * @param amount The monetary amount to format
     * @param currency The currency code (defaults to LKR for Sri Lankan Rupees)
     * @return Formatted currency string
     */
    func formatCurrency(_ amount: Double, currency: String = "LKR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(String(format: "%.2f", amount))"
    }
    
    /**
     * Formats ISO8601 date strings into user-friendly display format.
     * 
     * @param dateString ISO8601 formatted date string
     * @return Human-readable date and time string
     */
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    /**
     * Clears all dashboard data and resets error state.
     * Used for logout scenarios or data reset operations.
     */
    func clearDashboardData() {
        dashboardData = nil
        dashboardSummary = nil
        clearError()
    }
    
    /**
     * Refreshes both dashboard data and summary for the current user.
     * Convenient method for full dashboard reload.
     */
    func refreshDashboard() {
        fetchDashboardForCurrentUser()
        fetchDashboardSummaryForCurrentUser()
    }
    
    /**
     * Core Data management methods for offline functionality and data persistence.
     * Handle caching, cache validation, and offline mode operations.
     */
    
    /**
     * Loads cached dashboard data from Core Data storage.
     * Sets offline mode flag when cached data is successfully loaded.
     */
    func loadCachedData() {
        if let cachedData = coreDataManager.fetchDashboardData() {
            dashboardData = cachedData
            lastSyncTime = coreDataManager.getLastUpdateTime()
            isOfflineMode = true
            print("✅ Loaded cached dashboard data")
        } else {
            print("❌ No cached data available")
        }
    }
    
    /**
     * Clears all cached dashboard data from Core Data storage.
     * Performs background deletion of all dashboard-related entities.
     */
    func clearCache() {
        coreDataManager.performBackgroundTask { context in
            let entities = ["DashboardStatistics", "DashboardUser", "DashboardPicture", "DashboardReservation", "DashboardPayment", "DashboardHabitation"]
            
            for entityName in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("❌ Failed to clear \(entityName): \(error.localizedDescription)")
                }
            }
            
            do {
                try context.save()
                print("✅ Cache cleared successfully")
            } catch {
                print("❌ Failed to save after clearing cache: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Checks if cached dashboard data exists in Core Data storage.
     * 
     * @return True if cached data is available, false otherwise
     */
    func hasCachedData() -> Bool {
        return coreDataManager.hasCachedData()
    }
    
    /**
     * Calculates the age of cached data in seconds.
     * 
     * @return Time interval since last cache update, or nil if no cached data
     */
    func getCacheAge() -> TimeInterval? {
        guard let lastUpdate = coreDataManager.getLastUpdateTime() else {
            return nil
        }
        return Date().timeIntervalSince(lastUpdate)
    }
    
    /**
     * Determines if cached data is stale based on maximum age threshold.
     * 
     * @param maxAge Maximum acceptable cache age in seconds (default: 5 minutes)
     * @return True if cache is stale or doesn't exist, false if fresh
     */
    func isCacheStale(maxAge: TimeInterval = 300) -> Bool {
        guard let cacheAge = getCacheAge() else {
            return true
        }
        return cacheAge > maxAge
    }
    
    /**
     * Offline mode management for graceful degradation during network issues.
     * Provides seamless transition between online and offline states.
     */
    
    /**
     * Enables offline mode and loads cached data for immediate display.
     * Used when network connectivity is unavailable.
     */
    func enableOfflineMode() {
        isOfflineMode = true
        loadCachedData()
    }
    
    /**
     * Disables offline mode to resume normal online operations.
     * Called when network connectivity is restored.
     */
    func disableOfflineMode() {
        isOfflineMode = false
    }
    
    /**
     * Synchronizes data with server when online and cache is stale.
     * Automatically refreshes dashboard if data is outdated.
     */
    func syncWhenOnline() {
        guard !isOfflineMode else { return }
        
        if isCacheStale() {
            fetchDashboardForCurrentUser()
        }
    }
    
    /**
     * Core Data debugging and diagnostic methods for troubleshooting.
     * Provide detailed information about cache status and data integrity.
     */
    
    /**
     * Outputs comprehensive Core Data status information to console.
     * Used for debugging cache-related issues.
     */
    func debugCoreDataStatus() {
        coreDataManager.debugCoreDataStatus()
    }
    
    /**
     * Verifies the integrity of cached dashboard data.
     * 
     * @return True if data integrity checks pass, false otherwise
     */
    func verifyCoreDataIntegrity() -> Bool {
        return coreDataManager.verifyDataIntegrity()
    }
    
    /**
     * Performs comprehensive Core Data operation tests.
     * Used for validating cache functionality during development.
     */
    func testCoreDataOperations() {
        coreDataManager.testCoreDataOperations()
    }
    
    /**
     * Generates formatted Core Data status information for display.
     * 
     * @return Multi-line string containing cache status details
     */
    func getCoreDataInfo() -> String {
        let hasData = coreDataManager.hasCachedData()
        let lastUpdate = coreDataManager.getLastUpdateTime()
        
        var info = "Core Data Status:\n"
        info += "• Has Cached Data: \(hasData ? "Yes" : "No")\n"
        
        if let lastUpdate = lastUpdate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            info += "• Last Update: \(formatter.string(from: lastUpdate))\n"
        } else {
            info += "• Last Update: Never\n"
        }
        
        info += "• Offline Mode: \(isOfflineMode ? "Yes" : "No")\n"
        
        return info
    }
    
    /**
     * Forces a complete reset of Core Data storage and clears all dashboard state.
     * Used as a last resort for resolving persistent Core Data issues.
     */
    func forceResetCoreData() {
        print("🔄 Force resetting Core Data from DashboardViewModel...")
        
        resetDashboardState()
        CoreDataConfiguration.shared.completelyResetCoreData()
        clearError()
        
        print("✅ Core Data force reset completed")
    }
    
    /**
     * Enables Core Data bypass mode for troubleshooting scenarios.
     * Dashboard will function without caching until Core Data issues are resolved.
     */
    func enableCoreDataBypassMode() {
        print("🚫 Enabling Core Data bypass mode...")
        print("⚠️ Dashboard will work without caching until Core Data is fixed")
        
        UserDefaults.standard.set(true, forKey: "core_data_bypass_mode")
        resetDashboardState()
        clearError()
        
        print("✅ Core Data bypass mode enabled")
    }
    
    /**
     * Disables Core Data bypass mode to resume normal caching operations.
     * Called when Core Data issues have been resolved.
     */
    func disableCoreDataBypassMode() {
        print("✅ Disabling Core Data bypass mode...")
        UserDefaults.standard.set(false, forKey: "core_data_bypass_mode")
        print("✅ Core Data bypass mode disabled")
    }
    
    /**
     * Resets all dashboard-related state variables to their initial values.
     * Used during Core Data reset and bypass mode operations.
     */
    private func resetDashboardState() {
        dashboardData = nil
        dashboardSummary = nil
        lastSyncTime = nil
        isOfflineMode = false
    }
    
    /**
     * Checks if Core Data bypass mode is currently enabled.
     * 
     * @return True if bypass mode is active, false otherwise
     */
    private var isCoreDataBypassMode: Bool {
        return UserDefaults.standard.bool(forKey: "core_data_bypass_mode")
    }
}
