import Foundation
import CoreData

/// Helper class to test Core Data functionality
class CoreDataTestHelper {
    
    static let shared = CoreDataTestHelper()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    /// Run comprehensive Core Data tests
    func runAllTests() {
        print("🧪 === Starting Core Data Tests ===")
        
        test1_BasicOperations()
        test2_DataPersistence()
        test3_DataIntegrity()
        test4_OfflineMode()
        
        print("🧪 === Core Data Tests Complete ===")
    }
    
    /// Test 1: Basic Core Data operations
    private func test1_BasicOperations() {
        print("\n🧪 Test 1: Basic Operations")
        
        // Create test data
        let testData = createTestDashboardData()
        
        // Save data
        print("💾 Saving test data...")
        coreDataManager.saveDashboardData(testData)
        
        // Verify save
        let hasData = coreDataManager.hasCachedData()
        print("✅ Data saved: \(hasData)")
        
        // Fetch data
        print("📥 Fetching test data...")
        if let fetchedData = coreDataManager.fetchDashboardData() {
            print("✅ Data fetched successfully")
            print("📊 Habitations: \(fetchedData.habitations.count)")
            print("📊 Statistics: \(fetchedData.statistics.totalHabitations)")
        } else {
            print("❌ Failed to fetch data")
        }
    }
    
    /// Test 2: Data persistence across app restarts
    private func test2_DataPersistence() {
        print("\n🧪 Test 2: Data Persistence")
        
        // Check if data persists
        let hasData = coreDataManager.hasCachedData()
        print("📊 Data persists: \(hasData)")
        
        if hasData {
            let lastUpdate = coreDataManager.getLastUpdateTime()
            print("⏰ Last update: \(lastUpdate?.description ?? "Unknown")")
        }
    }
    
    /// Test 3: Data integrity verification
    private func test3_DataIntegrity() {
        print("\n🧪 Test 3: Data Integrity")
        
        let isValid = coreDataManager.verifyDataIntegrity()
        print("✅ Data integrity: \(isValid ? "Valid" : "Invalid")")
        
        if isValid {
            print("🔍 All data structures are intact")
        } else {
            print("❌ Data corruption detected")
        }
    }
    
    /// Test 4: Offline mode simulation
    private func test4_OfflineMode() {
        print("\n🧪 Test 4: Offline Mode")
        
        // Simulate offline mode
        print("📱 Simulating offline mode...")
        
        // Try to load cached data
        if let cachedData = coreDataManager.fetchDashboardData() {
            print("✅ Offline data available")
            print("📊 Cached habitations: \(cachedData.habitations.count)")
        } else {
            print("❌ No offline data available")
        }
    }
    
    /// Create test dashboard data
    private func createTestDashboardData() -> DashboardData {
        let testUser = DashboardUser(id: "test-user-123")
        
        let testStatistics = DashboardStatistics(
            totalHabitations: 2,
            totalReservations: 1,
            totalPayments: 1,
            totalEarnings: 5000.0,
            activeReservations: 1,
            completedReservations: 0,
            availableHabitations: 1,
            reservedHabitations: 1
        )
        
        let testUserData = EnhancedUserData(
            id: "test-user-123",
            firstName: "Test",
            lastName: "User",
            phoneNumber: "+1234567890"
        )
        
        let testPicture = HabitationPicture(
            id: "test-picture-1",
            habitation: "test-habitation-1",
            pictureUrl: "https://example.com/test-image.jpg"
        )
        
        let testHabitation = DashboardHabitation(
            id: "test-habitation-1",
            user: testUserData,
            name: "Test Property",
            description: "A test property for Core Data",
            type: "Apartment",
            isReserved: true,
            createdAt: "2025-01-01T00:00:00.000Z",
            updatedAt: "2025-01-01T00:00:00.000Z",
            v: 0,
            price: 5000,
            pictures: [testPicture],
            reservationHistory: [],
            payments: [],
            activeReservation: nil,
            reservedUser: testUserData,
            totalEarnings: 5000.0,
            reservationCount: 1,
            paymentCount: 1
        )
        
        let testRecentActivity = RecentActivity(
            recentReservations: [],
            recentPayments: []
        )
        
        return DashboardData(
            user: testUser,
            habitations: [testHabitation],
            statistics: testStatistics,
            recentActivity: testRecentActivity
        )
    }
    
    /// Clear all test data
    func clearTestData() {
        print("🗑️ Clearing test data...")
        CoreDataConfiguration.shared.clearAllData()
        print("✅ Test data cleared")
    }
    
    /// Get Core Data status summary
    func getStatusSummary() -> String {
        let hasData = coreDataManager.hasCachedData()
        let lastUpdate = coreDataManager.getLastUpdateTime()
        let isValid = coreDataManager.verifyDataIntegrity()
        
        var summary = "Core Data Status Summary:\n"
        summary += "• Has Data: \(hasData ? "Yes" : "No")\n"
        summary += "• Data Integrity: \(isValid ? "Valid" : "Invalid")\n"
        
        if let lastUpdate = lastUpdate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            summary += "• Last Update: \(formatter.string(from: lastUpdate))\n"
        } else {
            summary += "• Last Update: Never\n"
        }
        
        return summary
    }
}
