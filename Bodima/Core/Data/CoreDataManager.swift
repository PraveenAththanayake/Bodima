import Foundation
import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    var container: NSPersistentContainer
    
    init() {
        // Try to load compiled model first
        var initializedContainer = NSPersistentContainer(name: "DashboardDataModel")
        
        // If model is empty (not found in bundle), fall back to programmatic model
        if initializedContainer.managedObjectModel.entities.isEmpty {
            print("⚠️ Compiled Core Data model 'DashboardDataModel' not found. Falling back to programmatic model...")
            initializedContainer = CoreDataConfiguration.shared.createPersistentContainerWithProgrammaticModel()
            if initializedContainer.persistentStoreDescriptions.isEmpty {
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let dir = appSupport.appendingPathComponent("DashboardData", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let url = dir.appendingPathComponent("DashboardDataModel.sqlite")
                let desc = NSPersistentStoreDescription(url: url)
                desc.type = NSSQLiteStoreType
                desc.shouldMigrateStoreAutomatically = true
                desc.shouldInferMappingModelAutomatically = true
                initializedContainer.persistentStoreDescriptions = [desc]
            }
        }
        
        container = initializedContainer
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription). Retrying with programmatic model...")
                // Retry with programmatic model once
                let fallback = CoreDataConfiguration.shared.createPersistentContainerWithProgrammaticModel()
                if fallback.persistentStoreDescriptions.isEmpty {
                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let dir = appSupport.appendingPathComponent("DashboardData", isDirectory: true)
                    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    let url = dir.appendingPathComponent("DashboardDataModel.sqlite")
                    let desc = NSPersistentStoreDescription(url: url)
                    desc.type = NSSQLiteStoreType
                    desc.shouldMigrateStoreAutomatically = true
                    desc.shouldInferMappingModelAutomatically = true
                    fallback.persistentStoreDescriptions = [desc]
                }
                fallback.loadPersistentStores { _, err in
                    if let err = err {
                        print("❌ Fallback Core Data store load failed: \(err.localizedDescription)")
                    } else {
                        print("✅ Fallback Core Data store loaded successfully")
                        self.updateContainer(fallback)
                    }
                }
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        // Enable automatic merging of changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Context Management
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                print("❌ Core Data save failed: \(error.localizedDescription)")
            }
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    func updateContainer(_ newContainer: NSPersistentContainer) {
        print("🔄 Updating CoreDataManager container...")
        
        // Update the container
        self.container = newContainer
        
        // Enable automatic merging of changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        print("✅ CoreDataManager container updated successfully")
    }
    
    // MARK: - Dashboard Data Operations
    
    func saveDashboardData(_ dashboardData: DashboardData) {
        performBackgroundTask { context in
            // Clear existing data
            self.clearAllDashboardData(context: context)
            
            // Save statistics
            self.saveStatistics(dashboardData.statistics, context: context)
            
            // Save users
            let users = dashboardData.habitations.compactMap { $0.user }
            let uniqueUsers = Dictionary(grouping: users, by: { $0.id }).compactMapValues { $0.first }
            for user in uniqueUsers.values {
                self.saveUser(user, context: context)
            }
            
            // Save habitations with relationships
            for habitation in dashboardData.habitations {
                self.saveHabitation(habitation, context: context)
            }
            
            // Save recent activity
            self.saveRecentActivity(dashboardData.recentActivity, context: context)
            
            // Save context
            do {
                try context.save()
                print("✅ Dashboard data saved to Core Data")
            } catch {
                print("❌ Failed to save dashboard data: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchDashboardData() -> DashboardData? {
        let context = viewContext
        
        // Fetch statistics
        guard let statistics = fetchStatistics(context: context) else {
            return nil
        }
        
        // Fetch habitations with relationships
        let habitations = fetchHabitations(context: context)
        
        // Fetch recent activity
        let recentActivity = fetchRecentActivity(context: context)
        
        return DashboardData(
            user: DashboardUser(id: ""), // This would be set from auth
            habitations: habitations,
            statistics: statistics,
            recentActivity: recentActivity
        )
    }
    
    // MARK: - Individual Entity Operations
    
    private func saveStatistics(_ statistics: DashboardStatistics, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardStatistics", in: context)!
        let statsObject = NSManagedObject(entity: entity, insertInto: context)
        
        statsObject.setValue(statistics.totalHabitations, forKey: "totalHabitations")
        statsObject.setValue(statistics.totalReservations, forKey: "totalReservations")
        statsObject.setValue(statistics.totalPayments, forKey: "totalPayments")
        statsObject.setValue(statistics.totalEarnings, forKey: "totalEarnings")
        statsObject.setValue(statistics.activeReservations, forKey: "activeReservations")
        statsObject.setValue(statistics.completedReservations, forKey: "completedReservations")
        statsObject.setValue(statistics.availableHabitations, forKey: "availableHabitations")
        statsObject.setValue(statistics.reservedHabitations, forKey: "reservedHabitations")
        statsObject.setValue(ISO8601DateFormatter().string(from: Date()), forKey: "lastUpdated")
    }
    
    private func saveUser(_ user: EnhancedUserData, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardUser", in: context)!
        let userObject = NSManagedObject(entity: entity, insertInto: context)
        
        userObject.setValue(user.id, forKey: "id")
        userObject.setValue(user.firstName, forKey: "firstName")
        userObject.setValue(user.lastName, forKey: "lastName")
        userObject.setValue("", forKey: "bio")
        userObject.setValue(user.phoneNumber, forKey: "phoneNumber")
        userObject.setValue("", forKey: "addressNo")
        userObject.setValue("", forKey: "addressLine1")
        userObject.setValue("", forKey: "addressLine2")
        userObject.setValue("", forKey: "city")
        userObject.setValue("", forKey: "district")
    }
    
    private func saveHabitation(_ habitation: DashboardHabitation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardHabitation", in: context)!
        let habitationObject = NSManagedObject(entity: entity, insertInto: context)
        
        habitationObject.setValue(habitation.id, forKey: "id")
        habitationObject.setValue(habitation.name, forKey: "name")
        habitationObject.setValue(habitation.description, forKey: "descriptionText")
        habitationObject.setValue(habitation.type, forKey: "type")
        habitationObject.setValue(habitation.isReserved, forKey: "isReserved")
        habitationObject.setValue(habitation.price, forKey: "price")
        habitationObject.setValue(habitation.createdAt, forKey: "createdAt")
        habitationObject.setValue(habitation.updatedAt, forKey: "updatedAt")
        habitationObject.setValue(habitation.totalEarnings, forKey: "totalEarnings")
        habitationObject.setValue(habitation.reservationCount, forKey: "reservationCount")
        habitationObject.setValue(habitation.paymentCount, forKey: "paymentCount")
        habitationObject.setValue(habitation.mainPictureUrl, forKey: "mainPictureUrl")
        
        // Set user relationship
        if let user = habitation.user {
            let userRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardUser")
            userRequest.predicate = NSPredicate(format: "id == %@", user.id)
            if let userObject = try? context.fetch(userRequest).first {
                habitationObject.setValue(userObject, forKey: "user")
            }
        }
        
        // Save pictures
        if let pictures = habitation.pictures {
            for picture in pictures {
                savePicture(picture, habitationObject: habitationObject, context: context)
            }
        }
        
        // Save reservations
        for reservation in habitation.reservationHistory {
            saveReservation(reservation, habitationObject: habitationObject, context: context)
        }
        
        // Save payments
        for payment in habitation.payments {
            savePayment(payment, habitationObject: habitationObject, context: context)
        }
    }
    
    private func savePicture(_ picture: HabitationPicture, habitationObject: NSManagedObject, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardPicture", in: context)!
        let pictureObject = NSManagedObject(entity: entity, insertInto: context)
        
        pictureObject.setValue(picture.id, forKey: "id")
        pictureObject.setValue(picture.pictureUrl, forKey: "pictureUrl")
        pictureObject.setValue(Date(), forKey: "createdAt")
        pictureObject.setValue(habitationObject, forKey: "habitation")
    }
    
    private func saveReservation(_ reservation: DashboardReservation, habitationObject: NSManagedObject, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardReservation", in: context)!
        let reservationObject = NSManagedObject(entity: entity, insertInto: context)
        
        reservationObject.setValue(reservation.id, forKey: "id")
        reservationObject.setValue(reservation.reservedDateTime, forKey: "reservedDateTime")
        reservationObject.setValue(reservation.reservationEndDateTime, forKey: "reservationEndDateTime")
        reservationObject.setValue(reservation.status, forKey: "status")
        reservationObject.setValue(reservation.paymentDeadline, forKey: "paymentDeadline")
        reservationObject.setValue(reservation.isPaymentCompleted, forKey: "isPaymentCompleted")
        reservationObject.setValue(reservation.createdAt, forKey: "createdAt")
        reservationObject.setValue(reservation.updatedAt, forKey: "updatedAt")
        reservationObject.setValue(habitationObject, forKey: "habitation")
        
        // Set user relationship
        if let user = reservation.user {
            let userRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardUser")
            userRequest.predicate = NSPredicate(format: "id == %@", user.id)
            if let userObject = try? context.fetch(userRequest).first {
                reservationObject.setValue(userObject, forKey: "user")
            }
        }
    }
    
    private func savePayment(_ payment: DashboardPayment, habitationObject: NSManagedObject, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DashboardPayment", in: context)!
        let paymentObject = NSManagedObject(entity: entity, insertInto: context)
        
        paymentObject.setValue(payment.id, forKey: "id")
        paymentObject.setValue(payment.habitationOwnerId, forKey: "habitationOwnerId")
        paymentObject.setValue(payment.amount, forKey: "amount")
        paymentObject.setValue(payment.currencyType, forKey: "currencyType")
        paymentObject.setValue(payment.amountType, forKey: "amountType")
        paymentObject.setValue(payment.discount, forKey: "discount")
        paymentObject.setValue(payment.totalAmount, forKey: "totalAmount")
        paymentObject.setValue(payment.createdAt, forKey: "createdAt")
        paymentObject.setValue(payment.updatedAt, forKey: "updatedAt")
        paymentObject.setValue(habitationObject, forKey: "habitation")
    }
    
    private func saveRecentActivity(_ activity: RecentActivity, context: NSManagedObjectContext) {
        // Recent activity is derived from the habitations, reservations, and payments
        // No separate storage needed as it's computed from existing data
    }
    
    // MARK: - Fetch Operations
    
    private func fetchStatistics(context: NSManagedObjectContext) -> DashboardStatistics? {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardStatistics")
        
        do {
            let results = try context.fetch(request)
            if let statsObject = results.first {
                return DashboardStatistics(
                    totalHabitations: statsObject.value(forKey: "totalHabitations") as? Int ?? 0,
                    totalReservations: statsObject.value(forKey: "totalReservations") as? Int ?? 0,
                    totalPayments: statsObject.value(forKey: "totalPayments") as? Int ?? 0,
                    totalEarnings: statsObject.value(forKey: "totalEarnings") as? Double ?? 0.0,
                    activeReservations: statsObject.value(forKey: "activeReservations") as? Int ?? 0,
                    completedReservations: statsObject.value(forKey: "completedReservations") as? Int ?? 0,
                    availableHabitations: statsObject.value(forKey: "availableHabitations") as? Int ?? 0,
                    reservedHabitations: statsObject.value(forKey: "reservedHabitations") as? Int ?? 0
                )
            }
        } catch {
            print("❌ Failed to fetch statistics: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func fetchHabitations(context: NSManagedObjectContext) -> [DashboardHabitation] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardHabitation")
        request.relationshipKeyPathsForPrefetching = ["user", "pictures", "reservations", "payments"]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { object in
                convertToDashboardHabitation(object)
            }
        } catch {
            print("❌ Failed to fetch habitations: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchRecentActivity(context: NSManagedObjectContext) -> RecentActivity {
        // Fetch recent reservations
        let reservationRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardReservation")
        reservationRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        reservationRequest.fetchLimit = 5
        
        let recentReservations: [DashboardReservation] = {
            do {
                let results = try context.fetch(reservationRequest)
                return results.compactMap { convertToDashboardReservation($0) }
            } catch {
                print("❌ Failed to fetch recent reservations: \(error.localizedDescription)")
                return []
            }
        }()
        
        // Fetch recent payments
        let paymentRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardPayment")
        paymentRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        paymentRequest.fetchLimit = 5
        
        let recentPayments: [DashboardPayment] = {
            do {
                let results = try context.fetch(paymentRequest)
                return results.compactMap { convertToDashboardPayment($0) }
            } catch {
                print("❌ Failed to fetch recent payments: \(error.localizedDescription)")
                return []
            }
        }()
        
        return RecentActivity(
            recentReservations: recentReservations,
            recentPayments: recentPayments
        )
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToDashboardHabitation(_ object: NSManagedObject) -> DashboardHabitation? {
        guard let id = object.value(forKey: "id") as? String,
              let name = object.value(forKey: "name") as? String,
              let description = object.value(forKey: "descriptionText") as? String,
              let type = object.value(forKey: "type") as? String else {
            return nil
        }
        
        let isReserved = object.value(forKey: "isReserved") as? Bool ?? false
        let price = object.value(forKey: "price") as? Int ?? 0
        let createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
        let totalEarnings = object.value(forKey: "totalEarnings") as? Double ?? 0.0
        let reservationCount = object.value(forKey: "reservationCount") as? Int16 ?? 0
        let paymentCount = object.value(forKey: "paymentCount") as? Int16 ?? 0
        let mainPictureUrl = object.value(forKey: "mainPictureUrl") as? String
        
        // Convert user
        let user: EnhancedUserData? = {
            if let userObject = object.value(forKey: "user") as? NSManagedObject {
                return convertToEnhancedUserData(userObject)
            }
            return nil
        }()
        
        // Convert pictures
        let pictures: [HabitationPicture]? = {
            if let picturesSet = object.value(forKey: "pictures") as? Set<NSManagedObject> {
                return picturesSet.compactMap { convertToHabitationPicture($0) }
            }
            return nil
        }()
        
        // Convert reservations
        let reservations: [DashboardReservation] = {
            if let reservationsSet = object.value(forKey: "reservations") as? Set<NSManagedObject> {
                return reservationsSet.compactMap { convertToDashboardReservation($0) }
            }
            return []
        }()
        
        // Convert payments
        let payments: [DashboardPayment] = {
            if let paymentsSet = object.value(forKey: "payments") as? Set<NSManagedObject> {
                return paymentsSet.compactMap { convertToDashboardPayment($0) }
            }
            return []
        }()
        
        return DashboardHabitation(
            id: id,
            user: user,
            name: name,
            description: description,
            type: type,
            isReserved: isReserved,
            createdAt: ISO8601DateFormatter().string(from: createdAt),
            updatedAt: ISO8601DateFormatter().string(from: updatedAt),
            v: 0,
            price: price,
            pictures: pictures,
            reservationHistory: reservations,
            payments: payments,
            activeReservation: reservations.first { $0.status == "confirmed" || $0.status == "pending" },
            reservedUser: reservations.first { $0.status == "confirmed" || $0.status == "pending" }?.user,
            totalEarnings: totalEarnings,
            reservationCount: Int(reservationCount),
            paymentCount: Int(paymentCount)
        )
    }
    
    private func convertToEnhancedUserData(_ object: NSManagedObject) -> EnhancedUserData? {
        guard let id = object.value(forKey: "id") as? String,
              let firstName = object.value(forKey: "firstName") as? String,
              let lastName = object.value(forKey: "lastName") as? String,
              let bio = object.value(forKey: "bio") as? String,
              let phoneNumber = object.value(forKey: "phoneNumber") as? String,
              let addressNo = object.value(forKey: "addressNo") as? String,
              let addressLine1 = object.value(forKey: "addressLine1") as? String,
              let city = object.value(forKey: "city") as? String,
              let district = object.value(forKey: "district") as? String else {
            return nil
        }
        
        let addressLine2 = object.value(forKey: "addressLine2") as? String ?? ""
        
        return EnhancedUserData(
            id: id,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber
        )
    }
    
    private func convertToHabitationPicture(_ object: NSManagedObject) -> HabitationPicture? {
        guard let id = object.value(forKey: "id") as? String,
              let pictureUrl = object.value(forKey: "pictureUrl") as? String else {
            return nil
        }
        
        return HabitationPicture(
            id: id,
            habitation: "",
            pictureUrl: pictureUrl
        )
    }
    
    private func convertToDashboardReservation(_ object: NSManagedObject) -> DashboardReservation? {
        guard let id = object.value(forKey: "id") as? String,
              let reservedDateTime = object.value(forKey: "reservedDateTime") as? Date,
              let reservationEndDateTime = object.value(forKey: "reservationEndDateTime") as? Date,
              let status = object.value(forKey: "status") as? String,
              let isPaymentCompleted = object.value(forKey: "isPaymentCompleted") as? Bool,
              let createdAt = object.value(forKey: "createdAt") as? Date,
              let updatedAt = object.value(forKey: "updatedAt") as? Date else {
            return nil
        }
        
        let paymentDeadline = object.value(forKey: "paymentDeadline") as? Date
        
        // Convert user
        let user: EnhancedUserData? = {
            if let userObject = object.value(forKey: "user") as? NSManagedObject {
                return convertToEnhancedUserData(userObject)
            }
            return nil
        }()
        
        // Convert habitation
        let habitation: DashboardHabitationBasic? = {
            if let habitationObject = object.value(forKey: "habitation") as? NSManagedObject,
               let habitationId = habitationObject.value(forKey: "id") as? String,
               let habitationName = habitationObject.value(forKey: "name") as? String,
               let habitationType = habitationObject.value(forKey: "type") as? String,
               let habitationPrice = habitationObject.value(forKey: "price") as? Int {
                return DashboardHabitationBasic(
                    id: habitationId,
                    name: habitationName,
                    type: habitationType,
                    price: habitationPrice,
                    user: nil,
                    isReserved: nil
                )
            }
            return nil
        }()
        
        return DashboardReservation(
            id: id,
            user: user,
            habitation: habitation,
            reservedDateTime: ISO8601DateFormatter().string(from: reservedDateTime),
            reservationEndDateTime: ISO8601DateFormatter().string(from: reservationEndDateTime),
            status: status,
            paymentDeadline: paymentDeadline.map { ISO8601DateFormatter().string(from: $0) },
            isPaymentCompleted: isPaymentCompleted,
            createdAt: ISO8601DateFormatter().string(from: createdAt),
            updatedAt: ISO8601DateFormatter().string(from: updatedAt),
            v: 0
        )
    }
    
    private func convertToDashboardPayment(_ object: NSManagedObject) -> DashboardPayment? {
        guard let id = object.value(forKey: "id") as? String,
              let habitationOwnerId = object.value(forKey: "habitationOwnerId") as? String,
              let amount = object.value(forKey: "amount") as? Double,
              let currencyType = object.value(forKey: "currencyType") as? String,
              let amountType = object.value(forKey: "amountType") as? String,
              let discount = object.value(forKey: "discount") as? Double,
              let totalAmount = object.value(forKey: "totalAmount") as? Double,
              let createdAt = object.value(forKey: "createdAt") as? Date,
              let updatedAt = object.value(forKey: "updatedAt") as? Date else {
            return nil
        }
        
        return DashboardPayment(
            id: id,
            habitationOwnerId: habitationOwnerId,
            reservation: nil, // This would need to be set if needed
            amount: amount,
            currencyType: currencyType,
            amountType: amountType,
            discount: discount,
            totalAmount: totalAmount,
            createdAt: ISO8601DateFormatter().string(from: createdAt),
            updatedAt: ISO8601DateFormatter().string(from: updatedAt),
            v: 0
        )
    }
    
    // MARK: - Clear Operations
    
    private func clearAllDashboardData(context: NSManagedObjectContext) {
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
    }
    
    // MARK: - Utility Methods
    
    func hasCachedData() -> Bool {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardStatistics")
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    func getLastUpdateTime() -> Date? {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardStatistics")
        
        do {
            let results = try viewContext.fetch(request)
            if let lastUpdatedString = results.first?.value(forKey: "lastUpdated") as? String {
                let formatter = ISO8601DateFormatter()
                return formatter.date(from: lastUpdatedString)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    // MARK: - Debug and Verification Methods
    
    func debugCoreDataStatus() {
        print("🔍 === Core Data Debug Status ===")
        
        // Check if we have any cached data
        let hasData = hasCachedData()
        print("📊 Has Cached Data: \(hasData)")
        
        if hasData {
            let lastUpdate = getLastUpdateTime()
            print("⏰ Last Update: \(lastUpdate?.description ?? "Unknown")")
            
            // Count entities
            let entities = ["DashboardStatistics", "DashboardUser", "DashboardPicture", "DashboardReservation", "DashboardPayment", "DashboardHabitation"]
            
            for entityName in entities {
                let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: entityName)
                do {
                    let count = try viewContext.count(for: request)
                    print("📦 \(entityName): \(count) records")
                } catch {
                    print("❌ Error counting \(entityName): \(error.localizedDescription)")
                }
            }
        }
        
        print("🔍 === End Core Data Debug ===")
    }
    
    func verifyDataIntegrity() -> Bool {
        print("🔍 === Verifying Core Data Integrity ===")
        
        do {
            // Check if we can fetch dashboard data
            if let cachedData = fetchDashboardData() {
                print("✅ Successfully fetched cached dashboard data")
                print("📊 Habitations count: \(cachedData.habitations.count)")
                print("📊 Statistics: \(cachedData.statistics)")
                
                // Verify data structure
                for habitation in cachedData.habitations {
                    print("🏠 Habitation: \(habitation.name) - Reserved: \(habitation.isReserved)")
                    if let user = habitation.user {
                        print("👤 User: \(user.firstName) \(user.lastName)")
                    }
                }
                
                print("✅ Data integrity verification passed")
                return true
            } else {
                print("❌ No cached data found")
                return false
            }
        } catch {
            print("❌ Data integrity verification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func testCoreDataOperations() {
        print("🧪 === Testing Core Data Operations ===")
        
        // Test 1: Save a test object
        print("🧪 Test 1: Saving test data...")
        let testData = DashboardData(
            user: DashboardUser(id: "test-user"),
            habitations: [],
            statistics: DashboardStatistics(
                totalHabitations: 1,
                totalReservations: 0,
                totalPayments: 0,
                totalEarnings: 0.0,
                activeReservations: 0,
                completedReservations: 0,
                availableHabitations: 1,
                reservedHabitations: 0
            ),
            recentActivity: RecentActivity(recentReservations: [], recentPayments: [])
        )
        
        saveDashboardData(testData)
        print("✅ Test data saved")
        
        // Test 2: Fetch the test data
        print("🧪 Test 2: Fetching test data...")
        if let fetchedData = fetchDashboardData() {
            print("✅ Test data fetched successfully")
            print("📊 Test statistics: \(fetchedData.statistics)")
        } else {
            print("❌ Failed to fetch test data")
        }
        
        // Test 3: Clear and verify
        print("🧪 Test 3: Clearing test data...")
        performBackgroundTask { context in
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
                print("✅ Test data cleared successfully")
            } catch {
                print("❌ Failed to save after clearing test data: \(error.localizedDescription)")
            }
        }
        
        if !hasCachedData() {
            print("✅ Test data cleared successfully")
        } else {
            print("❌ Test data still exists after clearing")
        }
        
        print("🧪 === Core Data Operations Test Complete ===")
    }
}
