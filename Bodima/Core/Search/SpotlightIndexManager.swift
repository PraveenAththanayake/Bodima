import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

/// Indexes habitations into Core Spotlight for system-wide search
final class SpotlightIndexManager {
    static let shared = SpotlightIndexManager()
    private init() {}
    
    /// Index a list of habitations
    func indexHabitations(_ habitations: [EnhancedHabitationData]) {
        let items: [CSSearchableItem] = habitations.map { habitation in
            let attrSet = CSSearchableItemAttributeSet(contentType: .text)
            attrSet.title = habitation.name
            attrSet.contentDescription = habitation.description
            attrSet.keywords = buildKeywords(for: habitation)
            
            if let firstImage = habitation.pictures?.first?.pictureUrl,
               let url = URL(string: firstImage) {
                attrSet.thumbnailURL = url
            }
            
            let uniqueIdentifier = "habitation_\(habitation.id)"
            let domainIdentifier = "com.bodima.habitations"
            return CSSearchableItem(uniqueIdentifier: uniqueIdentifier,
                                    domainIdentifier: domainIdentifier,
                                    attributeSet: attrSet)
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("❌ Spotlight indexing failed: \(error.localizedDescription)")
            } else {
                print("🔎 Spotlight indexed \(items.count) habitations")
            }
        }
    }
    
    /// Remove all habitation items from the index
    func removeAllHabitations() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.bodima.habitations"]) { error in
            if let error = error {
                print("❌ Spotlight delete failed: \(error.localizedDescription)")
            } else {
                print("🧹 Spotlight cleared habitation items")
            }
        }
    }
    
    private func buildKeywords(for habitation: EnhancedHabitationData) -> [String] {
        var keys: [String] = []
        keys.append(habitation.name)
        keys.append(habitation.type)
        keys.append(habitation.userFullName)
        if let user = habitation.user {
            keys.append(user.fullName)
            keys.append(user.phoneNumber)
        }
        return Array(Set(keys.compactMap { $0.isEmpty ? nil : $0.lowercased() }))
    }
}
