import Foundation
import CoreData

final class HabitationCacheRepository {
    static let shared = HabitationCacheRepository()
    private let stack = HomeCoreDataStack.shared

    private init() {}

    // MARK: - Public API
    func saveAll(_ habitations: [EnhancedHabitationData]) {
        guard !habitations.isEmpty else { return }
        stack.performBackgroundTask { context in
            let ids = habitations.map { $0.id }
            self.deleteNotIn(ids: ids, context: context)
            habitations.forEach { _ = self.upsert($0, in: context) }
            do { try context.save() } catch { print("❌ Failed to save habitations cache: \(error)") }
        }
    }

    func fetchAll() -> [EnhancedHabitationData] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedHabitation")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        do {
            let objs = try stack.viewContext.fetch(request)
            return objs.compactMap { mapToEnhanced(from: $0) }
        } catch {
            print("❌ Failed to fetch cached habitations: \(error)")
            return []
        }
    }

    // MARK: - Private
    @discardableResult
    private func upsert(_ h: EnhancedHabitationData, in context: NSManagedObjectContext) -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedHabitation")
        request.predicate = NSPredicate(format: "id == %@", h.id)
        request.fetchLimit = 1
        let entity = NSEntityDescription.entity(forEntityName: "CachedHabitation", in: context)!

        let obj = (try? context.fetch(request).first) ?? NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(h.id, forKey: "id")
        obj.setValue(h.name, forKey: "name")
        obj.setValue(h.description, forKey: "desc")
        obj.setValue(h.type, forKey: "type")
        obj.setValue(h.isReserved, forKey: "isReserved")
        obj.setValue(NSNumber(value: h.price), forKey: "price")
        obj.setValue(h.updatedAt, forKey: "updatedAt")
        obj.setValue(Date(), forKey: "lastSyncedAt")

        // Owner summary
        obj.setValue(h.user?.id, forKey: "userId")
        obj.setValue(h.user?.fullName, forKey: "userFullName")
        obj.setValue(h.user?.phoneNumber, forKey: "userPhone")

        // Pictures summary
        obj.setValue(NSNumber(value: h.pictures?.count ?? 0), forKey: "pictureCount")
        return obj
    }

    private func deleteNotIn(ids: [String], context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedHabitation")
        request.predicate = NSPredicate(format: "NOT (id IN %@)", ids)
        if let objs = try? context.fetch(request) {
            objs.forEach { context.delete($0) }
        }
    }

    private func mapToEnhanced(from obj: NSManagedObject) -> EnhancedHabitationData? {
        guard let id = obj.value(forKey: "id") as? String,
              let name = obj.value(forKey: "name") as? String,
              let desc = obj.value(forKey: "desc") as? String,
              let type = obj.value(forKey: "type") as? String
        else { return nil }
        let isReserved = obj.value(forKey: "isReserved") as? Bool ?? false
        let price = (obj.value(forKey: "price") as? NSNumber)?.intValue ?? 0
        let updatedAt = obj.value(forKey: "updatedAt") as? String ?? ""
        let createdAt = "" // not stored in cache

        // Build minimal user JSON if available
        var userJson: [String: Any]? = nil
        if let userId = obj.value(forKey: "userId") as? String, !userId.isEmpty {
            let fullName = (obj.value(forKey: "userFullName") as? String) ?? ""
            let comps = fullName.split(separator: " ")
            let first = comps.first.map(String.init) ?? ""
            let last = comps.dropFirst().joined(separator: " ")
            let phone = (obj.value(forKey: "userPhone") as? String) ?? ""
            userJson = [
                "_id": userId,
                "firstName": first,
                "lastName": last,
                "phoneNumber": phone
            ]
        }

        // Pictures omitted to keep cache small
        let payload: [String: Any] = [
            "_id": id,
            "user": userJson as Any,
            "name": name,
            "description": desc,
            "type": type,
            "isReserved": isReserved,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "__v": 0,
            "price": price,
            "pictures": NSNull() // nil
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            let decoded = try JSONDecoder().decode(EnhancedHabitationData.self, from: data)
            return decoded
        } catch {
            print("❌ Failed to decode EnhancedHabitationData from cache: \(error)")
            return nil
        }
    }
}
