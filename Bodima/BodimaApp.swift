import SwiftUI
import CoreData

@main
struct BodimaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    init() {
        // Configure Core Data on app launch
        CoreDataConfiguration.shared.configureCoreDataStack()
        CoreDataConfiguration.shared.performDataMigrationIfNeeded()
        CoreDataConfiguration.shared.optimizeCoreDataPerformance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
                .globalAccessibility()
                .onAppear {
                    // Validate Core Data integrity
                    _ = CoreDataConfiguration.shared.validateCoreDataIntegrity()
                    
                    // Initialize global accessibility settings
                    GlobalAccessibilityManager.shared.loadLocalSettings()
                }
        }
    }
}
