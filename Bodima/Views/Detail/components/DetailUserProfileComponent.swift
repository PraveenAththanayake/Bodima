import SwiftUI

// User profile section with follow functionality and social interaction
// Handles user avatar, metadata display, and follow state management
struct DetailUserProfileComponent: View {
    let habitation: EnhancedHabitationData
    @Binding var isFollowing: Bool
    
    // Computed properties for user data transformation
    private var userInitials: String {
        if let user = habitation.user {
            return String(user.firstName.prefix(1)) + String(user.lastName.prefix(1))
        } else {
            return "?"
        }
    }
    
    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: habitation.createdAt) else { return "now" }
        
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // User avatar with fallback initials display
            Circle()
                .fill(AppColors.input)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(userInitials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.foreground)
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
            
            // User metadata with hierarchical information layout
            VStack(alignment: .leading, spacing: 4) {
                Text(habitation.userFullName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                if let user = habitation.user {
                    Text("@\(user.fullName) • \(formattedTime)")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                } else {
                    Text("• \(formattedTime)")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            // Follow button with state-based styling and animation
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFollowing.toggle()
                }
            }) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.subheadline.bold())
                    .foregroundStyle(isFollowing ? AppColors.foreground : .white)
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
            .buttonStyle(.plain)
            .accessibilityLabel(isFollowing ? "Unfollow" : "Follow")
            
            // More options menu trigger
            Button(action: {
                // TODO: Implement options menu
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.mutedForeground)
                    .rotationEffect(.degrees(90))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
    }
}
