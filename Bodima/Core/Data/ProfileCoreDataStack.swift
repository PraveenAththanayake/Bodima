import Foundation
import CoreData

final class ProfileCoreDataStack {
    static let shared = ProfileCoreDataStack()

    let container: NSPersistentContainer

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "ProfileDataModel", managedObjectModel: model)

        let storeURL: URL = {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("ProfileData", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent("ProfileDataModel.sqlite")
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
                print("❌ ProfileCoreDataStack load error: \(error.localizedDescription)")
            } else {
                print("✅ ProfileCoreDataStack loaded")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // UserProfile entity
        let entity = NSEntityDescription()
        entity.name = "UserProfile"
        entity.managedObjectClassName = "UserProfile"

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = optional
            return a
        }

        entity.properties = [
            attr("id", .stringAttributeType, optional: false),
            attr("authId", .stringAttributeType),
            attr("email", .stringAttributeType),
            attr("username", .stringAttributeType),
            attr("firstName", .stringAttributeType),
            attr("lastName", .stringAttributeType),
            attr("bio", .stringAttributeType),
            attr("phoneNumber", .stringAttributeType),
            attr("addressNo", .stringAttributeType),
            attr("addressLine1", .stringAttributeType),
            attr("addressLine2", .stringAttributeType),
            attr("city", .stringAttributeType),
            attr("district", .stringAttributeType),
            attr("profileImageURL", .stringAttributeType),
            attr("createdAt", .stringAttributeType),
            attr("updatedAt", .stringAttributeType),
            attr("lastSyncedAt", .dateAttributeType, optional: false),
            // Accessibility settings
            attr("largeText", .booleanAttributeType, optional: false),
            attr("highContrast", .booleanAttributeType, optional: false),
            attr("voiceOver", .booleanAttributeType, optional: false),
            attr("reduceMotion", .booleanAttributeType, optional: false),
            attr("screenReader", .booleanAttributeType, optional: false),
            attr("colorBlindAssist", .booleanAttributeType, optional: false),
            attr("hapticFeedback", .booleanAttributeType, optional: false)
        ]

        model.entities = [entity]
        return model
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
