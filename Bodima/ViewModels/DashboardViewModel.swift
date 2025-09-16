import Foundation
import SwiftUI
import CoreData

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dashboardData: DashboardData?
    @Published var dashboardSummary: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var isOfflineMode = false
    @Published var lastSyncTime: Date?
    
    private let networkManager = NetworkManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Dashboard Data Methods
    
    func fetchDashboardData(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        // Try to load from Core Data first (unless bypass mode is enabled)
        if !isCoreDataBypassMode {
            if let cachedData = coreDataManager.fetchDashboardData() {
                dashboardData = cachedData
                lastSyncTime = coreDataManager.getLastUpdateTime()
                print("✅ Loaded dashboard data from Core Data cache")
            }
        } else {
            print("🚫 Core Data bypass mode enabled - skipping cache load")
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            isOfflineMode = true
            return
        }
        
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
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetDashboard success: \(response.success)")
                    print("🔍 DEBUG - GetDashboard data: \(String(describing: response.data))")
                    
                        if response.success, let data = response.data {
                            self?.dashboardData = data
                            self?.lastSyncTime = Date()
                            
                            // Save to Core Data (unless bypass mode is enabled)
                            if !(self?.isCoreDataBypassMode ?? false) {
                                self?.coreDataManager.saveDashboardData(data)
                                print("✅ Dashboard data fetched and cached successfully")
                            } else {
                                print("✅ Dashboard data fetched successfully (bypass mode - not cached)")
                            }
                        } else {
                            self?.showError(response.message ?? "Failed to fetch dashboard data")
                        }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch dashboard error: \(error)")
                    self?.handleNetworkError(error)
                    
                    // If we have cached data, show it in offline mode
                    if self?.dashboardData != nil {
                        self?.isOfflineMode = true
                        print("📱 Showing cached data in offline mode")
                    }
                }
            }
        }
    }
    
    func fetchDashboardSummary(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
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
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetDashboardSummary success: \(response.success)")
                    print("🔍 DEBUG - GetDashboardSummary data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.dashboardSummary = response.data
                        print("✅ Dashboard summary fetched successfully")
                    } else {
                        self?.showError(response.message ?? "Failed to fetch dashboard summary")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch dashboard summary error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func fetchDashboardForCurrentUser() {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.fetchDashboardData(userId: userId)
        }
    }
    
    func fetchDashboardSummaryForCurrentUser() {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.fetchDashboardSummary(userId: userId)
        }
    }
    
    // MARK: - Computed Properties
    
    var totalEarnings: Double {
        return dashboardData?.statistics.totalEarnings ?? 0.0
    }
    
    var totalHabitations: Int {
        return dashboardData?.statistics.totalHabitations ?? 0
    }
    
    var availableHabitations: Int {
        return dashboardData?.statistics.availableHabitations ?? 0
    }
    
    var reservedHabitations: Int {
        return dashboardData?.statistics.reservedHabitations ?? 0
    }
    
    var totalReservations: Int {
        return dashboardData?.statistics.totalReservations ?? 0
    }
    
    var activeReservations: Int {
        return dashboardData?.statistics.activeReservations ?? 0
    }
    
    var completedReservations: Int {
        return dashboardData?.statistics.completedReservations ?? 0
    }
    
    var totalPayments: Int {
        return dashboardData?.statistics.totalPayments ?? 0
    }
    
    var recentReservations: [DashboardReservation] {
        return dashboardData?.recentActivity.recentReservations ?? []
    }
    
    var recentPayments: [DashboardPayment] {
        return dashboardData?.recentActivity.recentPayments ?? []
    }
    
    var habitations: [DashboardHabitation] {
        return dashboardData?.habitations ?? []
    }
    
    // MARK: - Filter Methods
    
    func getAvailableHabitations() -> [DashboardHabitation] {
        return habitations.filter { !$0.isReserved }
    }
    
    func getReservedHabitations() -> [DashboardHabitation] {
        return habitations.filter { $0.isReserved }
    }
    
    func getHabitationsWithActiveReservations() -> [DashboardHabitation] {
        return habitations.filter { $0.activeReservation != nil }
    }
    
    func getHabitationsWithPayments() -> [DashboardHabitation] {
        return habitations.filter { $0.paymentCount > 0 }
    }
    
    func getTopEarningHabitations() -> [DashboardHabitation] {
        return habitations.sorted { $0.totalEarnings > $1.totalEarnings }
    }
    
    func getRecentReservations(limit: Int = 5) -> [DashboardReservation] {
        return Array(recentReservations.prefix(limit))
    }
    
    func getRecentPayments(limit: Int = 5) -> [DashboardPayment] {
        return Array(recentPayments.prefix(limit))
    }
    
    // MARK: - Helper Methods
    
    private func getUserIdFromProfile(completion: @escaping (String?) -> Void) {
        guard let userId = AuthViewModel.shared.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            completion(nil)
            return
        }
        
        let profileViewModel = ProfileViewModel()
        
        func checkProfile() {
            if let profileId = profileViewModel.userProfile?.id {
                completion(profileId)
            } else if !profileViewModel.isLoading && profileViewModel.hasError {
                completion(nil)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    checkProfile()
                }
            }
        }
        
        profileViewModel.fetchUserProfile(userId: userId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkProfile()
        }
    }
    
    // MARK: - Error Handling
    
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
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Dashboard Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    // MARK: - Utility Methods
    
    func formatCurrency(_ amount: Double, currency: String = "LKR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(String(format: "%.2f", amount))"
    }
    
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
    
    func clearDashboardData() {
        dashboardData = nil
        dashboardSummary = nil
        clearError()
    }
    
    func refreshDashboard() {
        fetchDashboardForCurrentUser()
        fetchDashboardSummaryForCurrentUser()
    }
    
    // MARK: - Core Data Methods
    
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
    
    func clearCache() {
        coreDataManager.performBackgroundTask { context in
            // Clear all dashboard data
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
    
    func hasCachedData() -> Bool {
        return coreDataManager.hasCachedData()
    }
    
    func getCacheAge() -> TimeInterval? {
        guard let lastUpdate = coreDataManager.getLastUpdateTime() else {
            return nil
        }
        return Date().timeIntervalSince(lastUpdate)
    }
    
    func isCacheStale(maxAge: TimeInterval = 300) -> Bool { // 5 minutes default
        guard let cacheAge = getCacheAge() else {
            return true
        }
        return cacheAge > maxAge
    }
    
    // MARK: - Offline Support
    
    func enableOfflineMode() {
        isOfflineMode = true
        loadCachedData()
    }
    
    func disableOfflineMode() {
        isOfflineMode = false
    }
    
    func syncWhenOnline() {
        guard !isOfflineMode else { return }
        
        if isCacheStale() {
            fetchDashboardForCurrentUser()
        }
    }
    
    // MARK: - Core Data Debug Methods
    
    func debugCoreDataStatus() {
        coreDataManager.debugCoreDataStatus()
    }
    
    func verifyCoreDataIntegrity() -> Bool {
        return coreDataManager.verifyDataIntegrity()
    }
    
    func testCoreDataOperations() {
        coreDataManager.testCoreDataOperations()
    }
    
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
    
    func forceResetCoreData() {
        print("🔄 Force resetting Core Data from DashboardViewModel...")
        
        // Clear current data
        dashboardData = nil
        dashboardSummary = nil
        lastSyncTime = nil
        isOfflineMode = false
        
        // Reset Core Data
        CoreDataConfiguration.shared.completelyResetCoreData()
        
        // Clear error state
        clearError()
        
        print("✅ Core Data force reset completed")
    }
    
    func enableCoreDataBypassMode() {
        print("🚫 Enabling Core Data bypass mode...")
        print("⚠️ Dashboard will work without caching until Core Data is fixed")
        
        // Disable Core Data operations
        UserDefaults.standard.set(true, forKey: "core_data_bypass_mode")
        
        // Clear any cached data references
        dashboardData = nil
        dashboardSummary = nil
        lastSyncTime = nil
        isOfflineMode = false
        
        // Clear error state
        clearError()
        
        print("✅ Core Data bypass mode enabled")
    }
    
    func disableCoreDataBypassMode() {
        print("✅ Disabling Core Data bypass mode...")
        UserDefaults.standard.set(false, forKey: "core_data_bypass_mode")
        print("✅ Core Data bypass mode disabled")
    }
    
    private var isCoreDataBypassMode: Bool {
        return UserDefaults.standard.bool(forKey: "core_data_bypass_mode")
    }
}
