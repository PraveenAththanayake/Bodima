//
//  HomeView.swift
//  Bodima
//
//  Created by Praveen Aththanayake on 2025-07-13.
//

//
//  HomeView.swift
//  Bodima
//
//  Created by Praveen Aththanayake on 2025-07-13.
//

import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @State private var posts = samplePosts
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 0) {
                    // Logo and Title
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bodima")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                            
                            Text("Stories • Feed")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        
                        Spacer()
                        
                        // Notification bell icon
                        Button(action: {
                            // Add notification action here
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.input)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                
                                Image(systemName: "bell")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.mutedForeground)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search posts, users...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.foreground)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.mutedForeground)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(AppColors.background)
                
                // Stories Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Stories")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Spacer()
                        
                        Button(action: {
                            // Add view all stories action
                        }) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Stories Scroll View
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Add Story Button
                            AddStoryView()
                            
                            ForEach(sampleStories) { story in
                                StoryView(story: story)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
                
                // Feed Section
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Add Story View
struct AddStoryView: View {
    var body: some View {
        Button(action: {
            // Add story action
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                    
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text("Your Story")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
            }
            .frame(width: 76)
        }
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var isFollowing: Bool
    
    init(post: Post) {
        self.post = post
        self._likesCount = State(initialValue: post.likesCount)
        self._isFollowing = State(initialValue: post.isFollowing)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                // User Avatar
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .overlay(
                        Text(String(post.user.firstName?.prefix(1) ?? "") + String(post.user.lastName?.prefix(1) ?? ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(post.user.firstName ?? "Unknown") \(post.user.lastName ?? "")")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("@\(post.user.username) • \(formatTime(post.createdAt))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Follow/Following Button
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
                
                // Menu Button
                Button(action: {
                    // Add menu action here
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.mutedForeground)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding(.bottom, 16)
            
            // Post Image
            if post.imageURL != nil {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(height: 280)
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
            
            // Action Buttons
            HStack(spacing: 20) {
                // Like Button
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
                
                // Share Button
                Button(action: {
                    // Add share action here
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Bookmark Button
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
            .padding(.bottom, 16)
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.content)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            .padding(.bottom, 20)
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
    
    private func formatTime(_ date: Date) -> String {
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

// MARK: - Story View
struct StoryView: View {
    let story: Story
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 66, height: 66)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [AppColors.primary, AppColors.primary.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 3)
                            .frame(width: 70, height: 70)
                    )
                    .overlay(
                        Text(String(story.user.firstName?.prefix(1) ?? ""))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                    )
            }
            
            Text(story.user.firstName ?? "Unknown")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.foreground)
                .lineLimit(1)
        }
        .frame(width: 76)
    }
}

// MARK: - Data Models
struct Post: Identifiable {
    let id = UUID()
    let user: User
    let content: String
    let imageURL: String?
    let createdAt: Date
    let likesCount: Int
    let isFollowing: Bool
}

struct Story: Identifiable {
    let id = UUID()
    let user: User
    let imageURL: String?
    let createdAt: Date
}

// MARK: - Sample Data
let sampleUsers = [
    User(email: "john@example.com", username: "johndoe", firstName: "John", lastName: "Doe"),
    User(email: "jane@example.com", username: "janesmith", firstName: "Jane", lastName: "Smith"),
    User(email: "mike@example.com", username: "mikej", firstName: "Mike", lastName: "Johnson"),
    User(email: "sarah@example.com", username: "sarahw", firstName: "Sarah", lastName: "Wilson"),
    User(email: "david@example.com", username: "davidb", firstName: "David", lastName: "Brown"),
    User(email: "emily@example.com", username: "emilyd", firstName: "Emily", lastName: "Davis"),
    User(email: "alex@example.com", username: "alext", firstName: "Alex", lastName: "Taylor"),
    User(email: "lisa@example.com", username: "lisaa", firstName: "Lisa", lastName: "Anderson")
]

let samplePosts = [
    Post(
        user: sampleUsers[0],
        content: "Just moved into my new room! The view is amazing and the location is perfect for university. Really excited to start this new chapter! 🏠✨",
        imageURL: "post1",
        createdAt: Date(),
        likesCount: 24,
        isFollowing: false
    ),
    Post(
        user: sampleUsers[1],
        content: "Looking for a roommate to share this beautiful 2BR apartment near campus. Fully furnished with all amenities. DM me if interested! 🏡",
        imageURL: "post2",
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        likesCount: 15,
        isFollowing: true
    ),
    Post(
        user: sampleUsers[2],
        content: "Great study session at the library today! This place has such a peaceful atmosphere. Perfect for those late night study sessions 📚",
        imageURL: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        likesCount: 8,
        isFollowing: false
    ),
    Post(
        user: sampleUsers[3],
        content: "Found this amazing coffee shop near my accommodation. The Wi-Fi is fast and the coffee is incredible. New favorite study spot! ☕️",
        imageURL: "post3",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        likesCount: 32,
        isFollowing: true
    ),
    Post(
        user: sampleUsers[4],
        content: "Hosting a small get-together this weekend at my place. All neighbors are welcome! Let's build a great community together 🎉",
        imageURL: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
        likesCount: 19,
        isFollowing: false
    ),
    Post(
        user: sampleUsers[5],
        content: "The sunset view from my balcony is absolutely breathtaking! Living here has been such a wonderful experience so far 🌅",
        imageURL: "post4",
        createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
        likesCount: 41,
        isFollowing: true
    )
]

let sampleStories = [
    Story(user: sampleUsers[0], imageURL: "story1", createdAt: Date()),
    Story(user: sampleUsers[1], imageURL: "story2", createdAt: Date()),
    Story(user: sampleUsers[2], imageURL: "story3", createdAt: Date()),
    Story(user: sampleUsers[3], imageURL: "story4", createdAt: Date()),
    Story(user: sampleUsers[4], imageURL: "story5", createdAt: Date()),
    Story(user: sampleUsers[5], imageURL: "story6", createdAt: Date()),
    Story(user: sampleUsers[6], imageURL: "story7", createdAt: Date()),
    Story(user: sampleUsers[7], imageURL: "story8", createdAt: Date())
]

#Preview {
    HomeView()
}
