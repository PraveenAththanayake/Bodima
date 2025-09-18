import SwiftUI

// MARK: - Stories Section Components
struct StoriesSection: View {
    let stories: [UserStoryData]
    let isLoading: Bool
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    var body: some View {
        // Only show stories section if there are active stories or if loading
        if isLoading || !stories.isEmpty {
            VStack(spacing: 16) {
                StoriesHeader(storiesCount: stories.count)
                StoriesScrollView(
                    stories: stories,
                    isLoading: isLoading,
                    onStoryTap: onStoryTap,
                    onCreateStoryTap: onCreateStoryTap,
                    storiesViewModel: storiesViewModel
                )
            }
            .padding(.bottom, 24)
        } else {
            // When no stories, show only the create story button
            VStack(spacing: 16) {
                HStack {
                    Text("Stories")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        CreateStoryButton(onTap: onCreateStoryTap)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct StoriesHeader: View {
    let storiesCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                if storiesCount > 0 {
                    Text("\(storiesCount) active • disappear in 24h")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Text("Stories disappear after 24 hours")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            if storiesCount > 0 {
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct StoriesScrollView: View {
    let stories: [UserStoryData]
    let isLoading: Bool
    let onStoryTap: (UserStoryData) -> Void
    let onCreateStoryTap: () -> Void
    let storiesViewModel: UserStoriesViewModel
    
    // Group stories by user ID and filter to only include 24-hour stories
    private var activeStoriesByUser: [String: [UserStoryData]] {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // First filter stories to only include those within 24 hours
        let activeStories = stories.filter { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
        
        // Then group by user ID
        return Dictionary(grouping: activeStories) { $0.user.id }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                CreateStoryButton(onTap: onCreateStoryTap)
                
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        StoryPlaceholderView()
                    }
                } else {
                    // Display one circle per user with their active stories
                    ForEach(Array(activeStoriesByUser.keys), id: \.self) { userId in
                        if let userStories = activeStoriesByUser[userId], !userStories.isEmpty {
                            UserStoriesView(
                                userStories: userStories.sorted { story1, story2 in
                                    let formatter = ISO8601DateFormatter()
                                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                    
                                    guard let date1 = formatter.date(from: story1.createdAt),
                                          let date2 = formatter.date(from: story2.createdAt) else {
                                        return false
                                    }
                                    
                                    return date1 > date2 // Most recent first
                                },
                                onStoryTap: onStoryTap
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Story Components
struct UserStoriesView: View {
    let userStories: [UserStoryData]
    let onStoryTap: (UserStoryData) -> Void
    @State private var currentStoryIndex = 0
    
    private var user: UserStoryUser {
        userStories.first?.user ?? UserStoryUser(id: "", auth: nil, firstName: nil, lastName: nil, bio: nil, phoneNumber: nil, addressNo: nil, addressLine1: nil, addressLine2: nil, city: nil, district: nil)
    }
    
    // Filter stories to only include those within 24 hours
    private var activeStories: [UserStoryData] {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        return userStories.filter { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
    }
    
    var body: some View {
        // Only show if there are active stories
        if !activeStories.isEmpty {
            Button(action: {
                let validIndex = min(currentStoryIndex, activeStories.count - 1)
                onStoryTap(activeStories[validIndex])
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        // Display the current story image
                        AsyncImage(url: URL(string: activeStories[min(currentStoryIndex, activeStories.count - 1)].storyImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 66, height: 66)
                                .clipped()
                        } placeholder: {
                            Circle()
                                .fill(AppColors.input)
                                .frame(width: 66, height: 66)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .clipShape(Circle())
                        
                        // Story segments indicator with time-based styling
                        StorySegmentsIndicator(
                            totalSegments: activeStories.count, 
                            currentSegment: currentStoryIndex,
                            stories: activeStories
                        )
                    }
                    
                    Text(getUserDisplayName(from: user))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                        .frame(width: 76)
                        .truncationMode(.tail)
                }
            }
            .frame(width: 76)
            .onAppear {
                // Reset to first story when view appears
                currentStoryIndex = 0
            }
        }
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty {
            if let lastName = user.lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return "User"
    }
}

struct StorySegmentsIndicator: View {
    let totalSegments: Int
    let currentSegment: Int
    let stories: [UserStoryData]
    
    var body: some View {
        Circle()
            .stroke(
                getStoryBorderGradient(),
                lineWidth: 3
            )
            .frame(width: 66, height: 66)
            .overlay(
                ZStack {
                    // Create segment indicators
                    ForEach(0..<totalSegments, id: \.self) { index in
                        SegmentArc(
                            index: index,
                            total: totalSegments,
                            isActive: index <= currentSegment,
                            storyAge: getStoryAge(at: index)
                        )
                    }
                }
            )
    }
    
    private func getStoryBorderGradient() -> LinearGradient {
        // Check if any story is close to expiring (less than 3 hours left)
        let hasExpiringStory = stories.contains { story in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: story.createdAt) else {
                return false
            }
            
            let now = Date()
            let hoursLeft = (24 * 60 * 60 - now.timeIntervalSince(storyDate)) / 3600
            return hoursLeft <= 3 && hoursLeft > 0
        }
        
        if hasExpiringStory {
            return LinearGradient(
                colors: [Color.orange, Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func getStoryAge(at index: Int) -> TimeInterval {
        guard index < stories.count else { return 0 }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let storyDate = formatter.date(from: stories[index].createdAt) else {
            return 0
        }
        
        return Date().timeIntervalSince(storyDate)
    }
}

struct SegmentArc: View {
    let index: Int
    let total: Int
    let isActive: Bool
    let storyAge: TimeInterval
    
    var body: some View {
        let angleSize = 360.0 / Double(total)
        let startAngle = Double(index) * angleSize - 90
        let endAngle = startAngle + angleSize
        
        Path { path in
            path.addArc(
                center: CGPoint(x: 33, y: 33),
                radius: 33,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle - 4), // Gap between segments
                clockwise: false
            )
        }
        .stroke(getSegmentColor(), lineWidth: 3)
    }
    
    private func getSegmentColor() -> Color {
        if !isActive {
            return AppColors.mutedForeground
        }
        
        // Color based on story age
        let hoursOld = storyAge / 3600
        
        if hoursOld > 20 {
            return Color.red.opacity(0.8) // Very close to expiring
        } else if hoursOld > 12 {
            return Color.orange.opacity(0.9) // Getting old
        } else {
            return AppColors.primary // Fresh story
        }
    }
}

struct CreateStoryButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
                Text("Your Story")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                    .frame(width: 76)
            }
        }
        .frame(width: 76)
    }
}

struct StoryView: View {
    let story: UserStoryData
    let onTap: (UserStoryData) -> Void
    
    var body: some View {
        Button(action: {
            onTap(story)
        }) {
            VStack(spacing: 8) {
                ZStack {
                    AsyncImage(url: URL(string: story.storyImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 66)
                            .clipped()
                    } placeholder: {
                        Circle()
                            .fill(AppColors.input)
                            .frame(width: 66, height: 66)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                }
                
                Text(getUserDisplayName(from: story.user))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                    .frame(width: 76)
                    .truncationMode(.tail)
            }
        }
        .frame(width: 76)
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        return "User"
    }
}

struct StoryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppColors.input)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 2)
                )
                .redacted(reason: .placeholder)
            
            Text("Loading...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .redacted(reason: .placeholder)
        }
        .frame(width: 76)
    }
}

struct EmptyStoriesView: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppColors.input)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 2)
                )
                .overlay(
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(AppColors.foreground)
                    }
                )
            
            Text("No Recent Stories")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("Stories disappear after 24h")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppColors.mutedForeground.opacity(0.7))
        }
        .frame(width: 76)
    }
}
