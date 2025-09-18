import SwiftUI

// MARK: - Story Overlay Components
struct StoryOverlayView: View {
    let story: UserStoryData
    @Binding var isPresented: Bool
    let storiesViewModel: UserStoriesViewModel
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var currentStoryIndex: Int = 0
    @State private var userStories: [UserStoryData] = []
    
    private let storyDuration: Double = 5.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Left tap area for previous story
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: UIScreen.main.bounds.width * 0.3)
                    .onTapGesture {
                        showPreviousStory()
                    }
                
                Spacer()
                
                // Right tap area for next story
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: UIScreen.main.bounds.width * 0.3)
                    .onTapGesture {
                        showNextStory()
                    }
            }
            
            VStack(spacing: 0) {
                // Progress bars for all stories from this user
                HStack(spacing: 4) {
                    ForEach(0..<userStories.count, id: \.self) { index in
                        StoryProgressBar(
                            progress: index == currentStoryIndex ? progress : (index < currentStoryIndex ? 1.0 : 0.0)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                StoryHeader(
                    user: getCurrentStory().user,
                    createdAt: getCurrentStory().createdAt,
                    onClose: dismissStory
                )
                
                Spacer()
                
                StoryImageView(imageUrl: getCurrentStory().storyImageUrl)
                
                Spacer()
                
                if !getCurrentStory().description.isEmpty {
                    StoryDescriptionView(description: getCurrentStory().description)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadUserStories()
            startStoryTimer()
        }
        .onDisappear {
            stopStoryTimer()
        }
    }
    
    // Load all stories from the same user
    private func loadUserStories() {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // Find all active stories from the same user (within 24 hours)
        let allStories = storiesViewModel.userStories
        let userActiveStories = allStories.filter { userStory in
            // Same user check
            guard userStory.user.id == story.user.id else { return false }
            
            // 24-hour check
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let storyDate = formatter.date(from: userStory.createdAt) else {
                return false
            }
            
            return storyDate >= twentyFourHoursAgo
        }
        
        userStories = userActiveStories.sorted { story1, story2 in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date1 = formatter.date(from: story1.createdAt),
                  let date2 = formatter.date(from: story2.createdAt) else {
                return false
            }
            
            return date1 > date2 // Most recent first
        }
        
        // If no active stories found, just use the current story if it's still active
        if userStories.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let storyDate = formatter.date(from: story.createdAt),
               storyDate >= twentyFourHoursAgo {
                userStories = [story]
            } else {
                // Story has expired, close the overlay
                dismissStory()
                return
            }
        }
        
        // Find the index of the current story
        if let index = userStories.firstIndex(where: { $0.id == story.id }) {
            currentStoryIndex = index
        } else {
            currentStoryIndex = 0
        }
    }
    
    // Get the current story being displayed
    private func getCurrentStory() -> UserStoryData {
        if userStories.isEmpty {
            return story
        }
        return userStories[currentStoryIndex]
    }
    
    // Show the previous story
    private func showPreviousStory() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            resetStoryTimer()
        }
    }
    
    // Show the next story
    private func showNextStory() {
        if currentStoryIndex < userStories.count - 1 {
            currentStoryIndex += 1
            resetStoryTimer()
        } else {
            // If we're at the last story, dismiss
            dismissStory()
        }
    }
    
    private func resetStoryTimer() {
        stopStoryTimer()
        progress = 0
        startStoryTimer()
    }
    
    private func startStoryTimer() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                progress += 0.1 / storyDuration
                if progress >= 1.0 {
                    // Auto-advance to next story when timer completes
                    if currentStoryIndex < userStories.count - 1 {
                        currentStoryIndex += 1
                        progress = 0
                    } else {
                        dismissStory()
                    }
                }
            }
        }
    }
    
    private func stopStoryTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func dismissStory() {
        stopStoryTimer()
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

struct StoryProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress, height: 3)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct StoryHeader: View {
    let user: UserStoryUser
    let createdAt: String
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getInitials(from: user))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(getUserDisplayName(from: user))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(getRelativeTime(from: createdAt))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty,
           let lastName = user.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        
        return "User"
    }
    
    private func getInitials(from user: UserStoryUser) -> String {
        let firstName = user.firstName ?? ""
        let lastName = user.lastName ?? ""
        
        let firstInitial = firstName.isEmpty ? "" : String(firstName.prefix(1))
        let lastInitial = lastName.isEmpty ? "" : String(lastName.prefix(1))
        
        if firstInitial.isEmpty && lastInitial.isEmpty {
            return "U"
        }
        
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func getRelativeTime(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "now"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        let hoursLeft = max(0, (24 * 60 * 60 - timeInterval) / 3600)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            let remaining = Int(hoursLeft)
            if remaining <= 3 {
                return "\(hours)h • \(remaining)h left"
            } else {
                return "\(hours)h"
            }
        } else {
            return "expired"
        }
    }
}

struct StoryImageView: View {
    let imageUrl: String
    
    var body: some View {
        CachedImage(url: imageUrl, contentMode: .fit) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(height: 300)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct StoryDescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
            .padding(.horizontal, 16)
    }
}
