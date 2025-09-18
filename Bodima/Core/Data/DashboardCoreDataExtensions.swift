import Foundation
import CoreData

// MARK: - Core Data Extensions for Dashboard Models

extension DashboardData {
    init(from coreData: NSManagedObject) {
        // This would be used if we had a single Core Data entity for the entire dashboard
        // For now, we'll construct it from individual entities
        fatalError("Use individual entity constructors instead")
    }
}

extension DashboardHabitation {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.name = coreData.value(forKey: "name") as? String ?? ""
        self.description = coreData.value(forKey: "descriptionText") as? String ?? ""
        self.type = coreData.value(forKey: "type") as? String ?? ""
        self.isReserved = coreData.value(forKey: "isReserved") as? Bool ?? false
        self.price = coreData.value(forKey: "price") as? Int ?? 0
        self.totalEarnings = coreData.value(forKey: "totalEarnings") as? Double ?? 0.0
        self.reservationCount = Int(coreData.value(forKey: "reservationCount") as? Int16 ?? 0)
        self.paymentCount = Int(coreData.value(forKey: "paymentCount") as? Int16 ?? 0)
        // mainPictureUrl is computed from pictures, so we don't set it here
        
        // Convert dates (now stored as strings)
        self.createdAt = coreData.value(forKey: "createdAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.updatedAt = coreData.value(forKey: "updatedAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.v = 0
        
        // Convert user
        if let userObject = coreData.value(forKey: "user") as? NSManagedObject {
            self.user = EnhancedUserData(from: userObject)
        } else {
            self.user = nil
        }
        
        // Convert pictures
        if let picturesSet = coreData.value(forKey: "pictures") as? Set<NSManagedObject> {
            self.pictures = picturesSet.compactMap { HabitationPicture(from: $0) }
        } else {
            self.pictures = nil
        }
        
        // Convert reservations
        if let reservationsSet = coreData.value(forKey: "reservations") as? Set<NSManagedObject> {
            let reservations = reservationsSet.compactMap { DashboardReservation(from: $0) }
            self.reservationHistory = reservations
            self.activeReservation = reservations.first { $0.status == "confirmed" || $0.status == "pending" }
            self.reservedUser = self.activeReservation?.user
        } else {
            self.reservationHistory = []
            self.activeReservation = nil
            self.reservedUser = nil
        }
        
        // Convert payments
        if let paymentsSet = coreData.value(forKey: "payments") as? Set<NSManagedObject> {
            self.payments = paymentsSet.compactMap { DashboardPayment(from: $0) }
        } else {
            self.payments = []
        }
    }
}

extension EnhancedUserData {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.firstName = coreData.value(forKey: "firstName") as? String ?? ""
        self.lastName = coreData.value(forKey: "lastName") as? String ?? ""
        self.phoneNumber = coreData.value(forKey: "phoneNumber") as? String ?? ""
    }
}

extension HabitationPicture {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.habitation = "" // Not needed for display
        self.pictureUrl = coreData.value(forKey: "pictureUrl") as? String ?? ""
    }
}

extension DashboardReservation {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.status = coreData.value(forKey: "status") as? String ?? ""
        self.isPaymentCompleted = coreData.value(forKey: "isPaymentCompleted") as? Bool ?? false
        
        // Convert dates (now stored as strings)
        self.reservedDateTime = coreData.value(forKey: "reservedDateTime") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.reservationEndDateTime = coreData.value(forKey: "reservationEndDateTime") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.createdAt = coreData.value(forKey: "createdAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.updatedAt = coreData.value(forKey: "updatedAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.v = 0
        
        // Convert optional payment deadline (now stored as string)
        self.paymentDeadline = coreData.value(forKey: "paymentDeadline") as? String
        
        // Convert user
        if let userObject = coreData.value(forKey: "user") as? NSManagedObject {
            self.user = EnhancedUserData(from: userObject)
        } else {
            self.user = nil
        }
        
        // Convert habitation
        if let habitationObject = coreData.value(forKey: "habitation") as? NSManagedObject {
            self.habitation = DashboardHabitationBasic(from: habitationObject)
        } else {
            self.habitation = nil
        }
    }
}

extension DashboardHabitationBasic {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.name = coreData.value(forKey: "name") as? String ?? ""
        self.type = coreData.value(forKey: "type") as? String ?? ""
        self.price = coreData.value(forKey: "price") as? Int ?? 0
        self.user = coreData.value(forKey: "user") as? String
        self.isReserved = coreData.value(forKey: "isReserved") as? Bool
    }
}

extension DashboardPayment {
    init(from coreData: NSManagedObject) {
        self.id = coreData.value(forKey: "id") as? String ?? ""
        self.habitationOwnerId = coreData.value(forKey: "habitationOwnerId") as? String ?? ""
        self.amount = coreData.value(forKey: "amount") as? Double ?? 0.0
        self.currencyType = coreData.value(forKey: "currencyType") as? String ?? ""
        self.amountType = coreData.value(forKey: "amountType") as? String ?? ""
        self.discount = coreData.value(forKey: "discount") as? Double ?? 0.0
        self.totalAmount = coreData.value(forKey: "totalAmount") as? Double ?? 0.0
        
        // Convert dates (now stored as strings)
        self.createdAt = coreData.value(forKey: "createdAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.updatedAt = coreData.value(forKey: "updatedAt") as? String ?? ISO8601DateFormatter().string(from: Date())
        self.v = 0
        
        // Reservation is not stored as a relationship in this simplified model
        self.reservation = nil
    }
}

extension DashboardStatistics {
    init(from coreData: NSManagedObject) {
        self.totalHabitations = Int(coreData.value(forKey: "totalHabitations") as? Int16 ?? 0)
        self.totalReservations = Int(coreData.value(forKey: "totalReservations") as? Int16 ?? 0)
        self.totalPayments = Int(coreData.value(forKey: "totalPayments") as? Int16 ?? 0)
        self.totalEarnings = coreData.value(forKey: "totalEarnings") as? Double ?? 0.0
        self.activeReservations = Int(coreData.value(forKey: "activeReservations") as? Int16 ?? 0)
        self.completedReservations = Int(coreData.value(forKey: "completedReservations") as? Int16 ?? 0)
        self.availableHabitations = Int(coreData.value(forKey: "availableHabitations") as? Int16 ?? 0)
        self.reservedHabitations = Int(coreData.value(forKey: "reservedHabitations") as? Int16 ?? 0)
    }
}

// MARK: - Core Data Query Helpers

extension CoreDataManager {
    
    func fetchHabitationsWithFilters(
        isReserved: Bool? = nil,
        type: String? = nil,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [DashboardHabitation] {
        let context = context ?? viewContext
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardHabitation")
        request.relationshipKeyPathsForPrefetching = ["user", "pictures", "reservations", "payments"]
        
        var predicates: [NSPredicate] = []
        
        if let isReserved = isReserved {
            predicates.append(NSPredicate(format: "isReserved == %@", NSNumber(value: isReserved)))
        }
        
        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type))
        }
        
        if let minPrice = minPrice {
            predicates.append(NSPredicate(format: "price >= %d", minPrice))
        }
        
        if let maxPrice = maxPrice {
            predicates.append(NSPredicate(format: "price <= %d", maxPrice))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { DashboardHabitation(from: $0) }
        } catch {
            print("❌ Failed to fetch filtered habitations: \(error.localizedDescription)")
            return []
        }
    }
    
    func searchHabitations(query: String, context: NSManagedObjectContext? = nil) -> [DashboardHabitation] {
        let context = context ?? viewContext
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardHabitation")
        request.relationshipKeyPathsForPrefetching = ["user", "pictures", "reservations", "payments"]
        
        let searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@ OR descriptionText CONTAINS[cd] %@ OR type CONTAINS[cd] %@", query, query, query)
        request.predicate = searchPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { DashboardHabitation(from: $0) }
        } catch {
            print("❌ Failed to search habitations: \(error.localizedDescription)")
            return []
        }
    }
    
    func getStatistics(context: NSManagedObjectContext? = nil) -> DashboardStatistics? {
        let context = context ?? viewContext
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DashboardStatistics")
        
        do {
            let results = try context.fetch(request)
            if let statsObject = results.first {
                return DashboardStatistics(from: statsObject)
            }
        } catch {
            print("❌ Failed to fetch statistics: \(error.localizedDescription)")
        }
        
        return nil
    }
}
