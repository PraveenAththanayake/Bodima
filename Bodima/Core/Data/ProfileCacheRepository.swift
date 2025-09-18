import Foundation
import CoreData

final class ProfileCacheRepository {
    static let shared = ProfileCacheRepository()
    private let stack = ProfileCoreDataStack.shared

    private init() {}

    // MARK: - Public API
    func save(profile: ProfileData) {
        stack.performBackgroundTask { context in
            _ = self.upsert(profile: profile, in: context)
            do { try context.save() } catch { print("❌ Failed to save profile cache: \(error)") }
        }
    }

    func fetch(userId: String) -> ProfileData? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.predicate = NSPredicate(format: "id == %@", userId)
        request.fetchLimit = 1
        do {
            if let obj = try stack.viewContext.fetch(request).first {
                return mapToProfileData(from: obj)
            }
        } catch {
            print("❌ Failed to fetch cached profile: \(error)")
        }
        return nil
    }

    func updateAccessibility(userId: String, settings: AccessibilitySettings) {
        stack.performBackgroundTask { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
            request.predicate = NSPredicate(format: "id == %@", userId)
            request.fetchLimit = 1
            if let obj = try? context.fetch(request).first {
                obj.setValue(settings.largeText, forKey: "largeText")
                obj.setValue(settings.highContrast, forKey: "highContrast")
                obj.setValue(settings.voiceOver, forKey: "voiceOver")
                obj.setValue(settings.reduceMotion, forKey: "reduceMotion")
                obj.setValue(settings.screenReader, forKey: "screenReader")
                obj.setValue(settings.colorBlindAssist, forKey: "colorBlindAssist")
                obj.setValue(settings.hapticFeedback, forKey: "hapticFeedback")
                obj.setValue(Date(), forKey: "lastSyncedAt")
                try? context.save()
            }
        }
    }

    // MARK: - Private helpers
    @discardableResult
    private func upsert(profile: ProfileData, in context: NSManagedObjectContext) -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.predicate = NSPredicate(format: "id == %@", profile.id)
        request.fetchLimit = 1
        let entity = NSEntityDescription.entity(forEntityName: "UserProfile", in: context)!

        let obj = (try? context.fetch(request).first) ?? NSManagedObject(entity: entity, insertInto: context)

        obj.setValue(profile.id, forKey: "id")
        obj.setValue(profile.auth.id, forKey: "authId")
        obj.setValue(profile.auth.email, forKey: "email")
        obj.setValue(profile.auth.username, forKey: "username")
        obj.setValue(profile.firstName, forKey: "firstName")
        obj.setValue(profile.lastName, forKey: "lastName")
        obj.setValue(profile.bio, forKey: "bio")
        obj.setValue(profile.phoneNumber, forKey: "phoneNumber")
        obj.setValue(profile.addressNo, forKey: "addressNo")
        obj.setValue(profile.addressLine1, forKey: "addressLine1")
        obj.setValue(profile.addressLine2, forKey: "addressLine2")
        obj.setValue(profile.city, forKey: "city")
        obj.setValue(profile.district, forKey: "district")
        // Prefer correct field name from API. Support both as a fallback.
        let pic = profile.profileImageURL ?? profile.profileImageUrl
        obj.setValue(pic, forKey: "profileImageURL")
        obj.setValue(profile.createdAt, forKey: "createdAt")
        obj.setValue(profile.updatedAt, forKey: "updatedAt")
        obj.setValue(Date(), forKey: "lastSyncedAt")

        // Accessibility
        let acc = profile.accessibilitySettings ?? AccessibilitySettings()
        obj.setValue(acc.largeText, forKey: "largeText")
        obj.setValue(acc.highContrast, forKey: "highContrast")
        obj.setValue(acc.voiceOver, forKey: "voiceOver")
        obj.setValue(acc.reduceMotion, forKey: "reduceMotion")
        obj.setValue(acc.screenReader, forKey: "screenReader")
        obj.setValue(acc.colorBlindAssist, forKey: "colorBlindAssist")
        obj.setValue(acc.hapticFeedback, forKey: "hapticFeedback")

        return obj
    }

    private func mapToProfileData(from obj: NSManagedObject) -> ProfileData? {
        guard let id = obj.value(forKey: "id") as? String,
              let email = obj.value(forKey: "email") as? String,
              let username = obj.value(forKey: "username") as? String,
              let authId = obj.value(forKey: "authId") as? String else {
            return nil
        }

        let auth = AuthData(id: authId, email: email, username: username, createdAt: obj.value(forKey: "createdAt") as? String ?? "", updatedAt: obj.value(forKey: "updatedAt") as? String ?? "")

        let acc = AccessibilitySettings(
            largeText: obj.value(forKey: "largeText") as? Bool ?? false,
            highContrast: obj.value(forKey: "highContrast") as? Bool ?? false,
            voiceOver: obj.value(forKey: "voiceOver") as? Bool ?? false,
            reduceMotion: obj.value(forKey: "reduceMotion") as? Bool ?? false,
            screenReader: obj.value(forKey: "screenReader") as? Bool ?? false,
            colorBlindAssist: obj.value(forKey: "colorBlindAssist") as? Bool ?? false,
            hapticFeedback: obj.value(forKey: "hapticFeedback") as? Bool ?? true
        )

        return ProfileData(
            id: id,
            auth: auth,
            firstName: obj.value(forKey: "firstName") as? String,
            lastName: obj.value(forKey: "lastName") as? String,
            bio: obj.value(forKey: "bio") as? String,
            phoneNumber: obj.value(forKey: "phoneNumber") as? String,
            addressNo: obj.value(forKey: "addressNo") as? String,
            addressLine1: obj.value(forKey: "addressLine1") as? String,
            addressLine2: obj.value(forKey: "addressLine2") as? String,
            city: obj.value(forKey: "city") as? String,
            district: obj.value(forKey: "district") as? String,
            profileImageURL: obj.value(forKey: "profileImageURL") as? String,
            createdAt: obj.value(forKey: "createdAt") as? String,
            updatedAt: obj.value(forKey: "updatedAt") as? String,
            profileImageUrl: obj.value(forKey: "profileImageURL") as? String,
            accessibilitySettings: acc
        )
    }
}
