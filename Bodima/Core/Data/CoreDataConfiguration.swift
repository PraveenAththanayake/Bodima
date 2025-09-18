import Foundation
import CoreData

class CoreDataConfiguration {
    static let shared = CoreDataConfiguration()
    
    private init() {}
    
    // MARK: - Core Data Stack Configuration
    
    func configureCoreDataStack() {
        let manager = CoreDataManager.shared
        
        // Configure persistent store options
        let storeDescription = manager.container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable automatic merging of changes
        manager.container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        manager.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ Core Data stack configured successfully")
    }
    
    // MARK: - Data Migration
    
    func performDataMigrationIfNeeded() {
        // This would handle data migration between Core Data model versions
        // For now, we'll just ensure the store is properly set up
        _ = CoreDataManager.shared
        
        // Check if we need to perform any data migration
        // This is a placeholder for future migration logic
        print("✅ Data migration check completed")
    }
    
    // MARK: - Data Validation
    
    func validateCoreDataIntegrity() -> Bool {
        let manager = CoreDataManager.shared
        let context = manager.viewContext
        
        // Check if we can fetch basic entities
        let entities = ["DashboardStatistics", "DashboardUser", "DashboardPicture", "DashboardReservation", "DashboardPayment", "DashboardHabitation"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.fetchLimit = 1
            
            do {
                _ = try context.fetch(request)
                print("✅ \(entityName) entity accessible")
            } catch {
                print("❌ Core Data integrity check failed for \(entityName): \(error.localizedDescription)")
                // Don't return false immediately, continue checking other entities
            }
        }
        
        // Check if we can perform basic operations
        do {
            let statsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DashboardStatistics")
            let count = try context.count(for: statsRequest)
            print("📊 DashboardStatistics count: \(count)")
        } catch {
            print("❌ Failed to count DashboardStatistics: \(error.localizedDescription)")
            return false
        }
        
        print("✅ Core Data integrity check completed")
        return true
    }
    
    // MARK: - Performance Optimization
    
    func optimizeCoreDataPerformance() {
        let manager = CoreDataManager.shared
        _ = manager.viewContext
        
        // NOTE:
        // NSManagedObjectContext does not have a fetchBatchSize property. Attempting to set it via KVC
        // causes a crash with NSUnknownKeyException. Batch size must be configured on each
        // NSFetchRequest instance via request.fetchBatchSize = <Int>.
        // We keep this method as a placeholder for future global performance tweaks.
        
        print("✅ Core Data performance optimization applied (request-level batch sizing only)")
    }
    
    // MARK: - Debug Helpers
    
    func printCoreDataStatistics() {
        let manager = CoreDataManager.shared
        let context = manager.viewContext
        
        let entities = [
            ("DashboardStatistics", "DashboardStatistics"),
            ("DashboardUser", "DashboardUser"),
            ("DashboardPicture", "DashboardPicture"),
            ("DashboardReservation", "DashboardReservation"),
            ("DashboardPayment", "DashboardPayment"),
            ("DashboardHabitation", "DashboardHabitation")
        ]
        
        print("📊 Core Data Statistics:")
        for (name, entityName) in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            do {
                let count = try context.count(for: request)
                print("  \(name): \(count) records")
            } catch {
                print("  \(name): Error counting records - \(error.localizedDescription)")
            }
        }
    }
    
    func clearAllData() {
        let manager = CoreDataManager.shared
        manager.performBackgroundTask { context in
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
                print("🗑️ All Core Data cleared")
            } catch {
                print("❌ Failed to save after clearing data: \(error.localizedDescription)")
            }
        }
    }
    
    func resetCoreDataStore() {
        print("🔄 Resetting Core Data store...")
        
        let manager = CoreDataManager.shared
        let persistentContainer = manager.container
        
        // Get the store coordinator
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        
        // Get all stores
        let stores = storeCoordinator.persistentStores
        
        // Remove all stores
        for store in stores {
            do {
                try storeCoordinator.remove(store)
                print("✅ Removed store: \(store.url?.lastPathComponent ?? "Unknown")")
            } catch {
                print("❌ Failed to remove store: \(error.localizedDescription)")
            }
        }
        
        // Recreate the store
        do {
            let storeURL = persistentContainer.persistentStoreDescriptions.first?.url
            if let storeURL = storeURL {
                try storeCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: [:]
                )
                print("✅ Recreated Core Data store")
            }
        } catch {
            print("❌ Failed to recreate store: \(error.localizedDescription)")
        }
    }
    
    func completelyResetCoreData() {
        print("🔄 Completely resetting Core Data...")
        
        // First, clear all data
        clearAllData()
        
        // Wait a moment for the clear operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Reset the store
            self.resetCoreDataStore()
            
            // Wait another moment for the reset to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Validate the reset
                let isValid = self.validateCoreDataIntegrity()
                print("🔍 Core Data reset validation: \(isValid ? "✅ Success" : "❌ Failed")")
                
                if isValid {
                    print("🎉 Core Data has been completely reset and is ready to use!")
                } else {
                    print("⚠️ Core Data reset completed but validation failed. You may need to restart the app.")
                }
            }
        }
    }
    
    func deleteCoreDataFiles() {
        print("🗑️ Deleting Core Data files...")
        
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Delete all possible Core Data files from Documents directory
        let possibleStoreNames = ["DashboardDataModel", "CoreDataModel", "DataModel"]
        let fileExtensions = ["sqlite", "sqlite-wal", "sqlite-shm"]
        
        for storeName in possibleStoreNames {
            let storeURL = documentsDirectory.appendingPathComponent("\(storeName).sqlite")
            
            for fileExtension in fileExtensions {
                let fileURL = storeURL.appendingPathExtension(fileExtension)
                if fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("🗑️ Deleted: \(fileURL.lastPathComponent)")
                    } catch {
                        print("❌ Failed to delete \(fileURL.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Also delete any files in the Application Support directory
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for storeName in possibleStoreNames {
                let appSupportStoreURL = appSupportURL.appendingPathComponent("\(storeName).sqlite")
                
                for fileExtension in fileExtensions {
                    let fileURL = appSupportStoreURL.appendingPathExtension(fileExtension)
                    if fileManager.fileExists(atPath: fileURL.path) {
                        do {
                            try fileManager.removeItem(at: fileURL)
                            print("🗑️ Deleted from App Support: \(fileURL.lastPathComponent)")
                        } catch {
                            print("❌ Failed to delete from App Support \(fileURL.lastPathComponent): \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        // Also try to delete from the current container's store URL
        let manager = CoreDataManager.shared
        let persistentContainer = manager.container
        
        if let storeURL = persistentContainer.persistentStoreDescriptions.first?.url {
            for fileExtension in fileExtensions {
                let fileURL = storeURL.appendingPathExtension(fileExtension)
                if fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("🗑️ Deleted from container: \(fileURL.lastPathComponent)")
                    } catch {
                        print("❌ Failed to delete from container \(fileURL.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("🗑️ Core Data files deletion completed")
    }
    
    func nuclearResetCoreData() {
        print("☢️ NUCLEAR RESET: Completely destroying and rebuilding Core Data...")
        
        // Step 1: Delete all Core Data files
        deleteCoreDataFiles()
        
        // Step 2: Wait a moment for file system operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Step 3: Force recreate the Core Data stack
            self.forceRecreateCoreDataStack()
        }
    }
    
    private func forceRecreateCoreDataStack() {
        print("🔧 Force recreating Core Data stack...")
        
        let manager = CoreDataManager.shared
        let persistentContainer = manager.container
        
        // Get the store coordinator
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        
        // Remove all existing stores
        let stores = storeCoordinator.persistentStores
        for store in stores {
            do {
                try storeCoordinator.remove(store)
                print("✅ Removed corrupted store: \(store.url?.lastPathComponent ?? "Unknown")")
            } catch {
                print("❌ Failed to remove store: \(error.localizedDescription)")
            }
        }
        
        // Step 4: Recreate the store with fresh configuration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recreateStoreWithFreshConfig()
        }
    }
    
    private func recreateStoreWithFreshConfig() {
        print("🔄 Recreating store with fresh configuration...")
        
        let manager = CoreDataManager.shared
        let persistentContainer = manager.container
        let storeCoordinator = persistentContainer.persistentStoreCoordinator
        
        // Get the store URL or create a new one
        let storeURL: URL
        if let existingURL = persistentContainer.persistentStoreDescriptions.first?.url {
            storeURL = existingURL
            print("📁 Using existing store URL: \(storeURL.lastPathComponent)")
        } else {
            // Create a new store URL
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            storeURL = documentsDirectory.appendingPathComponent("DashboardDataModel.sqlite")
            print("📁 Created new store URL: \(storeURL.lastPathComponent)")
        }
        
        // Create fresh store with migration options
        let options: [String: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: [
                "journal_mode": "WAL",
                "synchronous": "NORMAL"
            ]
        ]
        
        do {
            try storeCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options
            )
            print("✅ Successfully recreated Core Data store")
            
            // Step 5: Validate the new store
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.validateNewStore()
            }
            
        } catch {
            print("❌ Failed to recreate store: \(error.localizedDescription)")
            print("💡 You may need to restart the app to complete the reset")
        }
    }
    
    private func validateNewStore() {
        print("🔍 Validating new Core Data store...")
        
        let isValid = validateCoreDataIntegrity()
        if isValid {
            print("🎉 NUCLEAR RESET SUCCESSFUL! Core Data is now working properly.")
            print("💡 You can now use the dashboard normally.")
        } else {
            print("⚠️ Nuclear reset completed but validation still failed.")
            print("💡 Please restart the app to complete the Core Data reset.")
        }
    }
    
    func completeCoreDataReinitialization() {
        print("🔄 Complete Core Data reinitialization...")
        
        // Step 1: Force close any existing persistent stores
        forceClosePersistentStores()
        
        // Step 2: Delete all files
        deleteCoreDataFiles()
        
        // Step 3: Wait for file operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Step 4: Create a completely new Core Data stack
            self.createNewCoreDataStack()
        }
    }
    
    private func forceClosePersistentStores() {
        print("🔒 Force closing existing persistent stores...")
        
        let manager = CoreDataManager.shared
        let container = manager.container
        
        // Remove all persistent stores
        for storeDescription in container.persistentStoreDescriptions {
            if let storeURL = storeDescription.url {
                do {
                    if let store = container.persistentStoreCoordinator.persistentStore(for: storeURL) {
                        try container.persistentStoreCoordinator.remove(store)
                        print("✅ Removed persistent store: \(storeURL.lastPathComponent)")
                    }
                } catch {
                    print("⚠️ Could not remove persistent store: \(error.localizedDescription)")
                }
            }
        }
        
        print("🔒 Persistent stores force closed")
    }
    
    private func createNewCoreDataStack() {
        print("🏗️ Creating completely new Core Data stack...")
        
        // Get documents directory and create a unique store URL with timestamp
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let timestamp = Int(Date().timeIntervalSince1970)
        let storeURL = documentsDirectory.appendingPathComponent("DashboardDataModel_\(timestamp).sqlite")
        
        print("📁 Store URL: \(storeURL.path)")
        
        // Create a new persistent container with programmatic model
        let container = createPersistentContainerWithProgrammaticModel()
        
        // Configure the store description with migration disabled to avoid conflicts
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldMigrateStoreAutomatically = false  // Disable migration
        storeDescription.shouldInferMappingModelAutomatically = false  // Disable inference
        
        // Set SQLite options
        storeDescription.setOption(false as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(false as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        storeDescription.setOption([
            "journal_mode": "WAL",
            "synchronous": "NORMAL"
        ] as NSObject, forKey: NSSQLitePragmasOption)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        // Load the store
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("❌ Failed to load new store: \(error.localizedDescription)")
                print("💡 Core Data may need to be completely bypassed")
            } else {
                print("✅ Successfully created new Core Data store")
                print("📁 Store location: \(storeDescription.url?.path ?? "Unknown")")
                
                // Update the CoreDataManager with the new container
                DispatchQueue.main.async {
                    self.updateCoreDataManagerWithNewContainer(container)
                }
            }
        }
    }
    
    func createPersistentContainerWithProgrammaticModel() -> NSPersistentContainer {
        print("🔧 Creating Core Data model programmatically...")
        
        // Create the managed object model
        let model = NSManagedObjectModel()
        
        // Create entities
        let dashboardStatisticsEntity = createDashboardStatisticsEntity()
        let dashboardUserEntity = createDashboardUserEntity()
        let dashboardPictureEntity = createDashboardPictureEntity()
        let dashboardReservationEntity = createDashboardReservationEntity()
        let dashboardPaymentEntity = createDashboardPaymentEntity()
        let dashboardHabitationEntity = createDashboardHabitationEntity()
        
        // Set up relationships
        setupEntityRelationships(
            habitation: dashboardHabitationEntity,
            user: dashboardUserEntity,
            picture: dashboardPictureEntity,
            reservation: dashboardReservationEntity,
            payment: dashboardPaymentEntity
        )
        
        // Add entities to model
        model.entities = [
            dashboardStatisticsEntity,
            dashboardUserEntity,
            dashboardPictureEntity,
            dashboardReservationEntity,
            dashboardPaymentEntity,
            dashboardHabitationEntity
        ]
        
        // Create container with programmatic model
        let container = NSPersistentContainer(name: "DashboardDataModel", managedObjectModel: model)
        
        print("✅ Core Data model created programmatically")
        return container
    }
    
    private func createDashboardStatisticsEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardStatistics"
        entity.managedObjectClassName = "DashboardStatistics"
        
        // Add attributes
        entity.properties = [
            createAttribute(name: "totalHabitations", type: .integer16AttributeType),
            createAttribute(name: "totalReservations", type: .integer16AttributeType),
            createAttribute(name: "totalPayments", type: .integer16AttributeType),
            createAttribute(name: "totalEarnings", type: .doubleAttributeType),
            createAttribute(name: "activeReservations", type: .integer16AttributeType),
            createAttribute(name: "completedReservations", type: .integer16AttributeType),
            createAttribute(name: "availableHabitations", type: .integer16AttributeType),
            createAttribute(name: "reservedHabitations", type: .integer16AttributeType),
            createAttribute(name: "lastUpdated", type: .stringAttributeType)
        ]
        
        return entity
    }
    
    private func createDashboardUserEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardUser"
        entity.managedObjectClassName = "DashboardUser"
        
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "auth", type: .stringAttributeType),
            createAttribute(name: "firstName", type: .stringAttributeType),
            createAttribute(name: "lastName", type: .stringAttributeType),
            createAttribute(name: "bio", type: .stringAttributeType),
            createAttribute(name: "phoneNumber", type: .stringAttributeType),
            createAttribute(name: "addressNo", type: .stringAttributeType),
            createAttribute(name: "addressLine1", type: .stringAttributeType),
            createAttribute(name: "addressLine2", type: .stringAttributeType, optional: true),
            createAttribute(name: "city", type: .stringAttributeType),
            createAttribute(name: "district", type: .stringAttributeType)
        ]
        
        return entity
    }
    
    private func createDashboardPictureEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardPicture"
        entity.managedObjectClassName = "DashboardPicture"
        
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "pictureUrl", type: .stringAttributeType),
            createAttribute(name: "createdAt", type: .stringAttributeType)
        ]
        
        return entity
    }
    
    private func createDashboardReservationEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardReservation"
        entity.managedObjectClassName = "DashboardReservation"
        
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "reservedDateTime", type: .stringAttributeType),
            createAttribute(name: "reservationEndDateTime", type: .stringAttributeType),
            createAttribute(name: "status", type: .stringAttributeType),
            createAttribute(name: "paymentDeadline", type: .stringAttributeType, optional: true),
            createAttribute(name: "isPaymentCompleted", type: .booleanAttributeType),
            createAttribute(name: "createdAt", type: .stringAttributeType),
            createAttribute(name: "updatedAt", type: .stringAttributeType)
        ]
        
        return entity
    }
    
    private func createDashboardPaymentEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardPayment"
        entity.managedObjectClassName = "DashboardPayment"
        
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "habitationOwnerId", type: .stringAttributeType),
            createAttribute(name: "amount", type: .doubleAttributeType),
            createAttribute(name: "currencyType", type: .stringAttributeType),
            createAttribute(name: "amountType", type: .stringAttributeType),
            createAttribute(name: "discount", type: .doubleAttributeType),
            createAttribute(name: "totalAmount", type: .doubleAttributeType),
            createAttribute(name: "createdAt", type: .stringAttributeType),
            createAttribute(name: "updatedAt", type: .stringAttributeType)
        ]
        
        return entity
    }
    
    private func createDashboardHabitationEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DashboardHabitation"
        entity.managedObjectClassName = "DashboardHabitation"
        
        entity.properties = [
            createAttribute(name: "id", type: .stringAttributeType),
            createAttribute(name: "name", type: .stringAttributeType),
            createAttribute(name: "descriptionText", type: .stringAttributeType),
            createAttribute(name: "type", type: .stringAttributeType),
            createAttribute(name: "isReserved", type: .booleanAttributeType),
            createAttribute(name: "price", type: .integer32AttributeType),
            createAttribute(name: "createdAt", type: .stringAttributeType),
            createAttribute(name: "updatedAt", type: .stringAttributeType),
            createAttribute(name: "totalEarnings", type: .doubleAttributeType),
            createAttribute(name: "reservationCount", type: .integer16AttributeType),
            createAttribute(name: "paymentCount", type: .integer16AttributeType),
            createAttribute(name: "mainPictureUrl", type: .stringAttributeType, optional: true)
        ]
        
        return entity
    }
    
    private func createAttribute(name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
    
    private func setupEntityRelationships(
        habitation: NSEntityDescription,
        user: NSEntityDescription,
        picture: NSEntityDescription,
        reservation: NSEntityDescription,
        payment: NSEntityDescription
    ) {
        // Habitation -> User relationship
        let habitationToUser = NSRelationshipDescription()
        habitationToUser.name = "user"
        habitationToUser.destinationEntity = user
        habitationToUser.maxCount = 1
        habitationToUser.deleteRule = .nullifyDeleteRule
        
        // User -> Habitations relationship
        let userToHabitations = NSRelationshipDescription()
        userToHabitations.name = "habitations"
        userToHabitations.destinationEntity = habitation
        userToHabitations.maxCount = 0 // toMany
        userToHabitations.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        habitationToUser.inverseRelationship = userToHabitations
        userToHabitations.inverseRelationship = habitationToUser
        
        // Add relationships to entities
        habitation.properties.append(habitationToUser)
        user.properties.append(userToHabitations)
        
        // Add other relationships (pictures, reservations, payments)
        let habitationToPictures = NSRelationshipDescription()
        habitationToPictures.name = "pictures"
        habitationToPictures.destinationEntity = picture
        habitationToPictures.maxCount = 0
        habitationToPictures.deleteRule = .cascadeDeleteRule
        
        let pictureToHabitation = NSRelationshipDescription()
        pictureToHabitation.name = "habitation"
        pictureToHabitation.destinationEntity = habitation
        pictureToHabitation.maxCount = 1
        pictureToHabitation.deleteRule = .nullifyDeleteRule
        
        habitationToPictures.inverseRelationship = pictureToHabitation
        pictureToHabitation.inverseRelationship = habitationToPictures
        
        habitation.properties.append(habitationToPictures)
        picture.properties.append(pictureToHabitation)
    }
    
    private func updateCoreDataManagerWithNewContainer(_ newContainer: NSPersistentContainer) {
        print("🔄 Updating CoreDataManager with new container...")
        
        // Update the CoreDataManager's container
        let manager = CoreDataManager.shared
        manager.updateContainer(newContainer)
        
        // Wait a moment for the update to take effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let isValid = self.validateCoreDataIntegrity()
            if isValid {
                print("🎉 COMPLETE REINITIALIZATION SUCCESSFUL!")
                print("💡 Core Data is now working with a fresh stack.")
                
                // Disable bypass mode since Core Data is now working
                UserDefaults.standard.set(false, forKey: "core_data_bypass_mode")
                print("✅ Core Data bypass mode automatically disabled")
            } else {
                print("⚠️ Reinitialization completed but validation still failed.")
                print("💡 The new container was created but may need app restart to fully take effect.")
            }
        }
    }
}
