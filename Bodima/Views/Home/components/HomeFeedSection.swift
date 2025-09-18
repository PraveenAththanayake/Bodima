import SwiftUI

// MARK: - Main Content View
struct MainContentView: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let searchText: String
    let selectedHabitationType: HabitationType?
    let locationDataCache: [String: LocationData]
    let featureDataCache: [String: HabitationFeatureData]
    let userStories: [UserStoryData]
    let isStoriesLoading: Bool
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    var filteredHabitations: [EnhancedHabitationData] {
        var filtered = habitations
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { habitation in
                habitation.name.localizedCaseInsensitiveContains(searchText) ||
                habitation.description.localizedCaseInsensitiveContains(searchText) ||
                habitation.userFullName.localizedCaseInsensitiveContains(searchText) ||
                (habitation.user?.fullName.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (habitation.user?.phoneNumber.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by habitation type
        if let selectedType = selectedHabitationType {
            filtered = filtered.filter { habitation in
                habitation.type == selectedType.rawValue
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                StoriesSection(
                    stories: userStories,
                    isLoading: isStoriesLoading,
                    onStoryTap: onStoryTap,
                    onCreateStoryTap: onCreateStoryTap,
                    storiesViewModel: storiesViewModel
                )
                FeedSection(
                    habitations: filteredHabitations,
                    isLoading: isLoading,
                    locationDataCache: locationDataCache,
                    featureDataCache: featureDataCache,
                    onLocationFetch: onLocationFetch,
                    onFeatureFetch: onFeatureFetch
                )
            }
        }
    }
}

// MARK: - Feed Section
struct FeedSection: View {
    let habitations: [EnhancedHabitationData]
    let isLoading: Bool
    let locationDataCache: [String: LocationData]
    let featureDataCache: [String: HabitationFeatureData]
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    var body: some View {
        if isLoading {
            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
                Text("Loading habitations...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(.top, 40)
        } else if habitations.isEmpty {
            VStack {
                Image(systemName: "house.slash")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(.bottom, 16)
                Text("No habitations found")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                Text("Try adjusting your search or check back later")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(habitations, id: \.id) { habitation in
                    HabitationCardView(
                        habitation: habitation,
                        locationData: locationDataCache[habitation.id],
                        featureData: featureDataCache[habitation.id],
                        onLocationFetch: onLocationFetch,
                        onFeatureFetch: onFeatureFetch
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Habitation Card Components
struct HabitationCardView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    let onLocationFetch: (String) -> Void
    let onFeatureFetch: (String) -> Void
    
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likesCount = 0
    @State private var isFollowing = false
    @State private var hasTriedToFetchLocation = false
    @State private var hasTriedToFetchFeature = false
    
    var body: some View {
        NavigationLink(destination: DetailView(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )) {
            VStack(alignment: .leading, spacing: 0) {
                HabitationHeader(habitation: habitation, isFollowing: $isFollowing)
                HabitationImage(pictures: habitation.pictures)
                HabitationActions(isLiked: $isLiked, likesCount: $likesCount, isBookmarked: $isBookmarked)
                HabitationContent(habitation: habitation)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !hasTriedToFetchLocation {
                onLocationFetch(habitation.id)
                hasTriedToFetchLocation = true
            }
            
            if !hasTriedToFetchFeature {
                onFeatureFetch(habitation.id)
                hasTriedToFetchFeature = true
            }
        }
    }
}

struct HabitationHeader: View {
    let habitation: EnhancedHabitationData
    @Binding var isFollowing: Bool
    
    var body: some View {
        HStack {
            if let user = habitation.user {
                    UserAvatar(user: user)
                    UserInfo(user: user, createdAt: habitation.createdAt)
                } else {
                    // Fallback for missing user data
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("?")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                        )
                    
                    Text("Unknown User")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.foreground)
                }
            Spacer()
            FollowButton(isFollowing: $isFollowing)
            MenuButton()
        }
        .padding(.bottom, 16)
    }
}

struct UserAvatar: View {
    let user: EnhancedUserData
    
    var body: some View {
        Circle()
            .fill(AppColors.input)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .overlay(
                Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.foreground)
            )
    }
}

struct UserInfo: View {
    let user: EnhancedUserData
    let createdAt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(user.firstName) \(user.lastName)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("@\(user.fullName) • \(formatTime(createdAt))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else { return "now" }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else {
            return "now"
        }
    }
}

struct FollowButton: View {
    @Binding var isFollowing: Bool
    
    var body: some View {
        Button(action: {
            isFollowing.toggle()
        }) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isFollowing ? AppColors.foreground : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isFollowing ? AppColors.input : AppColors.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isFollowing ? AppColors.border : AppColors.primary, lineWidth: 1)
                        )
                )
        }
    }
}

struct MenuButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.mutedForeground)
                .rotationEffect(.degrees(90))
        }
    }
}

struct HabitationImage: View {
    let pictures: [HabitationPicture]?
    
    var body: some View {
        if let pictures = pictures, !pictures.isEmpty, let firstPicture = pictures.first {
            CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(width: 320, height: 280)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
            .frame(width: 320, height: 280)
            .clipped()
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .padding(.bottom, 16)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.input)
                .frame(width: 320, height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppColors.mutedForeground)
                )
                .padding(.bottom, 16)
        }
    }
}

struct HabitationActions: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    @Binding var isBookmarked: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            LikeButton(isLiked: $isLiked, likesCount: $likesCount)
            ShareButton()
            Spacer()
            BookmarkButton(isBookmarked: $isBookmarked)
        }
        .padding(.bottom, 16)
    }
}

struct LikeButton: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isLiked.toggle()
                likesCount += isLiked ? 1 : -1
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isLiked ? AppColors.primary : AppColors.mutedForeground)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
                
                if likesCount > 0 {
                    Text("\(likesCount)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                }
            }
        }
    }
}

struct ShareButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "paperplane")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

struct BookmarkButton: View {
    @Binding var isBookmarked: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isBookmarked.toggle()
            }
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isBookmarked ? AppColors.primary : AppColors.mutedForeground)
                .scaleEffect(isBookmarked ? 1.1 : 1.0)
        }
    }
}

struct HabitationContent: View {
    let habitation: EnhancedHabitationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(habitation.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Text(habitation.type)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text(habitation.description)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.foreground)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                if let user = habitation.user {
                    Text("\(user.phoneNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Text("Unknown location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                HabitationAvailabilityView(habitation: habitation)
            }
        }
        .padding(.bottom, 20)
    }
}
