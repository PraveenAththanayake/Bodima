import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = [
        NotificationItem(
            id: 1,
            userInitials: "KY",
            message: "Kyle posted a new story today",
            timeAgo: "2h ago",
            isRead: false
        ),
        NotificationItem(
            id: 2,
            userInitials: "KY",
            message: "Kyle posted a new room today. Visit now!",
            timeAgo: "2h ago",
            isRead: false
        )
    ]
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    
                    // Today Section
                    todaySection
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("You have \(unreadCount) new notifications today")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.foreground)
                    .frame(width: 44, height: 44)
                    .background(AppColors.input)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        Button(action: {}) {
            HStack(alignment: .center, spacing: 12) {
                // User Avatar
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(notification.userInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    
                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? AppColors.input.opacity(0.3) : AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.message)
    }
}

struct NotificationItem: Identifiable {
    let id: Int
    let userInitials: String
    let message: String
    let timeAgo: String
    var isRead: Bool
}

#Preview {
    NotificationsView()
}
