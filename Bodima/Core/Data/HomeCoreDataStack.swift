import Foundation
import CoreData

final class HomeCoreDataStack {
    static let shared = HomeCoreDataStack()

    let container: NSPersistentContainer

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "HomeDataModel", managedObjectModel: model)

        let storeURL: URL = {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("HomeData", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent("HomeDataModel.sqlite")
        }()

        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption([
            "journal_mode": "WAL",
            "synchronous": "NORMAL"
        ] as NSObject, forKey: NSSQLitePragmasOption)

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ HomeCoreDataStack load error: \(error.localizedDescription)")
            } else {
                print("✅ HomeCoreDataStack loaded")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // CachedHabitation entity (flattened EnhancedHabitationData for list screens)
        let habitation = NSEntityDescription()
        habitation.name = "CachedHabitation"
        habitation.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = optional
            return a
        }

        habitation.properties = [
            attr("id", .stringAttributeType, optional: false),
            attr("name", .stringAttributeType),
            attr("desc", .stringAttributeType),
            attr("type", .stringAttributeType),
            attr("isReserved", .booleanAttributeType, optional: false),
            attr("price", .integer64AttributeType, optional: false),
            // Owner summary
            attr("userId", .stringAttributeType),
            attr("userFullName", .stringAttributeType),
            attr("userPhone", .stringAttributeType),
            // Pictures summary
            attr("pictureCount", .integer64AttributeType, optional: false),
            // Timestamps
            attr("updatedAt", .stringAttributeType),
            attr("lastSyncedAt", .dateAttributeType, optional: false)
        ]

        model.entities = [habitation]
        return model
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
