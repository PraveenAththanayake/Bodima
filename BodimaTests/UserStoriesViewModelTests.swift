import Foundation
import Testing
@testable import Bodima

struct UserStoriesViewModelTests {
    private func isoString(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func makeStory(id: String, createdAt: Date) -> UserStoryData {
        // Minimal valid user for testing display helpers
        let user = UserStoryUser(
            id: "user_\(id)",
            auth: nil,
            firstName: "John",
            lastName: "Doe",
            bio: nil,
            phoneNumber: nil,
            addressNo: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: "Colombo",
            district: "Western"
        )
        return UserStoryData(
            id: id,
            user: user,
            storyImageUrl: "https://example.com/image.jpg",
            description: "desc",
            createdAt: isoString(for: createdAt),
            updatedAt: isoString(for: createdAt),
            version: 0
        )
    }

    @Test func testSortedStoriesFiltersExpiredAndSortsDescending() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let s1 = makeStory(id: "recent1", createdAt: now.addingTimeInterval(-3600))      // 1h ago
        let s2 = makeStory(id: "expired", createdAt: now.addingTimeInterval(-(25*3600)))  // 25h ago
        let s3 = makeStory(id: "recent2", createdAt: now.addingTimeInterval(-(2*3600)))   // 2h ago

        await MainActor.run { vm.userStories = [s3, s2, s1] }

        let sorted = await MainActor.run { vm.sortedStories }
        #expect(sorted.count == 2)
        #expect(sorted.first?.id == "recent1")
        #expect(sorted.last?.id == "recent2")
    }

    @Test func testIsStoryWithin24Hours() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let within = makeStory(id: "within", createdAt: now.addingTimeInterval(-10_000)) // < 24h
        let outside = makeStory(id: "outside", createdAt: now.addingTimeInterval(-(26*3600)))

        let r1 = await MainActor.run { vm.isStoryWithin24Hours(within) }
        let r2 = await MainActor.run { vm.isStoryWithin24Hours(outside) }
        #expect(r1 == true)
        #expect(r2 == false)
    }

    @Test func testGetRemainingHours() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let story = makeStory(id: "rem", createdAt: now.addingTimeInterval(-(5*3600 + 30))) // 5h 30s ago
        let remaining = await MainActor.run { vm.getRemainingHours(for: story) }
        // Should floor to 18 or 19 depending on the exact seconds elapsed; use range check
        #expect((18...19).contains(remaining))
    }

    @Test func testRelativeTimeStrings() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let justNow = isoString(for: now.addingTimeInterval(-30))
        let fiveMin = isoString(for: now.addingTimeInterval(-(5*60)))
        let threeHours = isoString(for: now.addingTimeInterval(-(3*3600)))
        let twoDays = isoString(for: now.addingTimeInterval(-(2*86400)))

        let rNow = await MainActor.run { vm.getRelativeTimeString(from: justNow) }
        let r5m = await MainActor.run { vm.getRelativeTimeString(from: fiveMin) }
        let r3h = await MainActor.run { vm.getRelativeTimeString(from: threeHours) }
        let r2d = await MainActor.run { vm.getRelativeTimeString(from: twoDays) }

        #expect(rNow == "Just now")
        #expect(r5m.hasPrefix("5m"))
        #expect(r3h.hasPrefix("3h"))
        #expect(r2d.hasPrefix("2d"))
    }

    @Test func testWhatsAppStyleTime() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let justNow = isoString(for: now.addingTimeInterval(-20))
        let fiveMin = isoString(for: now.addingTimeInterval(-(5*60)))
        let threeHours = isoString(for: now.addingTimeInterval(-(3*3600)))
        let twoDays = isoString(for: now.addingTimeInterval(-(2*86400)))

        let tNow = await MainActor.run { vm.getWhatsAppStyleTime(from: justNow) }
        let t5m = await MainActor.run { vm.getWhatsAppStyleTime(from: fiveMin) }
        let t3h = await MainActor.run { vm.getWhatsAppStyleTime(from: threeHours) }
        let t2d = await MainActor.run { vm.getWhatsAppStyleTime(from: twoDays) }

        #expect(tNow == "now")
        #expect(t5m == "5m")
        #expect(t3h == "3h")
        #expect(t2d == "2d")
    }

    @Test func testUserDisplayNameAndLocation() async throws {
        let vm = await UserStoriesViewModel()
        let userFull = UserStoryUser(
            id: "u1", auth: nil, firstName: "Jane", lastName: "Smith", bio: nil,
            phoneNumber: nil, addressNo: nil, addressLine1: nil, addressLine2: nil,
            city: "Kandy", district: "Central"
        )
        let userFirstOnly = UserStoryUser(
            id: "u2", auth: nil, firstName: "Solo", lastName: nil, bio: nil,
            phoneNumber: nil, addressNo: nil, addressLine1: nil, addressLine2: nil,
            city: nil, district: nil
        )
        let userUnknown = UserStoryUser(
            id: "u3", auth: nil, firstName: nil, lastName: nil, bio: nil,
            phoneNumber: nil, addressNo: nil, addressLine1: nil, addressLine2: nil,
            city: nil, district: nil
        )

        let nameFull = await MainActor.run { vm.getUserDisplayName(from: userFull) }
        let locFull = await MainActor.run { vm.getUserLocation(from: userFull) }
        let nameFirst = await MainActor.run { vm.getUserDisplayName(from: userFirstOnly) }
        let locUnknown = await MainActor.run { vm.getUserLocation(from: userFirstOnly) }
        let nameUnknown = await MainActor.run { vm.getUserDisplayName(from: userUnknown) }

        #expect(nameFull == "Jane Smith")
        #expect(locFull == "Kandy, Central")
        #expect(nameFirst == "Solo")
        #expect(locUnknown == "Unknown Location")
        #expect(nameUnknown == "Unknown User")
    }

    @Test func testFormatDateProducesUserFriendlyString() async throws {
        let vm = await UserStoriesViewModel()
        let now = Date()
        let iso = isoString(for: now)
        let display = await MainActor.run { vm.formatDate(iso) }
        // Should not return the exact ISO string when parsing succeeds
        #expect(display != iso)
        #expect(display.isEmpty == false)
    }
}
