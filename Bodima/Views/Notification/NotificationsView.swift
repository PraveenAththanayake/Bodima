import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.primary)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("No notifications yet")
                            .font(.title3.bold())
                            .foregroundColor(AppColors.foreground)
                        
                        Text("You'll see notifications about new habitations and other updates here.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Section
                            headerView
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.background)
                            
                            // Notifications by section
                            ForEach(Array(viewModel.groupedNotifications.keys.sorted(by: { sortSections($0, $1) })), id: \.self) { section in
                                if let sectionNotifications = viewModel.groupedNotifications[section] {
                                    notificationSection(title: section, notifications: sectionNotifications)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchNotifications()
            }
            .refreshable {
                viewModel.fetchNotifications()
            }
            .overlay(
                // Error Alert
                Group {
                    if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                        VStack {
                            AlertBanner(message: AlertMessage.error(errorMessage)) {
                                viewModel.hasError = false
                                viewModel.errorMessage = nil
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                    }
                }
            )
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("You have \(viewModel.unreadCount) new notifications")
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
    
    private func notificationSection(title: String, notifications: [NotificationModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification) {
                        // Mark as read when tapped
                        viewModel.markNotificationAsRead(notificationId: notification.id)
                    }
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
    
    // Helper function to sort sections in the correct order
    private func sortSections(_ lhs: String, _ rhs: String) -> Bool {
        let order = ["Today", "Yesterday", "Earlier"]
        let lhsIndex = order.firstIndex(of: lhs) ?? order.count
        let rhsIndex = order.firstIndex(of: rhs) ?? order.count
        return lhsIndex < rhsIndex
    }
}

struct NotificationRow: View {
    let notification: NotificationModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                // Notification Icon
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColors.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.description)
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
                if !notification.isTouched {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isTouched ? AppColors.input.opacity(0.3) : AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(notification.description)
    }
}

#Preview {
    NotificationsView()
}
