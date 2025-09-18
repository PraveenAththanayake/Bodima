import SwiftUI

// MARK: - Header Section Components
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var selectedHabitationType: HabitationType?
    @Binding var showFilterMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TopBarView()
            SearchBarView(searchText: $searchText)
            FilterBarView(
                selectedHabitationType: $selectedHabitationType,
                showFilterMenu: $showFilterMenu
            )
        }
        .background(AppColors.background)
    }
}

// MARK: - Top Bar Components
struct TopBarView: View {
    var body: some View {
        HStack {
            TitleSection()
            Spacer()
            HStack(spacing: 16) {
                NavigationLink(destination: ReservationHistoryView()) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.foreground)
                }
                NotificationButton()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

struct TitleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bodima")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Stories • Feed")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

struct NotificationButton: View {
    @StateObject private var notificationViewModel = NotificationViewModel()
    
    var body: some View {
        NavigationLink(destination: NotificationsView()) {
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
                
                // Notification badge
                if notificationViewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 18, height: 18)
                        
                        Text("\(min(notificationViewModel.unreadCount, 9))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 12, y: -12)
                }
            }
        }
        .onAppear {
            notificationViewModel.fetchNotifications()
        }
    }
}

// MARK: - Search Bar Components
struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            SearchIcon()
            SearchTextField(searchText: $searchText)
            ClearButton(searchText: $searchText)
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
}

struct SearchIcon: View {
    var body: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(AppColors.mutedForeground)
            .font(.system(size: 16, weight: .medium))
    }
}

struct SearchTextField: View {
    @Binding var searchText: String
    
    var body: some View {
        TextField("Search posts, users...", text: $searchText)
            .font(.system(size: 16))
            .foregroundColor(AppColors.foreground)
    }
}

struct ClearButton: View {
    @Binding var searchText: String
    
    var body: some View {
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
}

// MARK: - Filter Bar Components
struct FilterBarView: View {
    @Binding var selectedHabitationType: HabitationType?
    @Binding var showFilterMenu: Bool
    
    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All filter button
                    FilterChip(
                        title: "All",
                        isSelected: selectedHabitationType == nil,
                        action: {
                            selectedHabitationType = nil
                        }
                    )
                    
                    // Individual type filter buttons
                    ForEach(HabitationType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: selectedHabitationType == type,
                            action: {
                                selectedHabitationType = type
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : AppColors.foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.primary : AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
