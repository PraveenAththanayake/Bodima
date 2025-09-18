import SwiftUI

struct MyHabitationsView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @State private var selectedTab = 0
    @State private var showingReservationHistory = false
    @State private var selectedHabitation: DashboardHabitation?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if dashboardViewModel.isLoading {
                        loadingView
                    } else if dashboardViewModel.habitations.isEmpty {
                        emptyStateView
                    } else {
                        dashboardContent
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadDashboardData()
            }
            .refreshable {
                loadDashboardData()
            }
        .contextMenu {
            Button(action: {
                dashboardViewModel.refreshDashboard()
            }) {
                Label("Refresh Data", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                dashboardViewModel.loadCachedData()
            }) {
                Label("Load Cached Data", systemImage: "internaldrive")
            }
            
            if dashboardViewModel.hasCachedData() {
                Button(action: {
                    dashboardViewModel.clearCache()
                }) {
                    Label("Clear Cache", systemImage: "trash")
                }
            }
            
            if dashboardViewModel.isOfflineMode {
                Button(action: {
                    dashboardViewModel.disableOfflineMode()
                }) {
                    Label("Go Online", systemImage: "wifi")
                }
            } else {
                Button(action: {
                    dashboardViewModel.enableOfflineMode()
                }) {
                    Label("Go Offline", systemImage: "wifi.slash")
                }
            }
            
            Divider()
            
            Button(action: {
                dashboardViewModel.debugCoreDataStatus()
            }) {
                Label("Debug Core Data", systemImage: "ladybug")
            }
            
            Button(action: {
                let isValid = dashboardViewModel.verifyCoreDataIntegrity()
                print("🔍 Core Data Integrity: \(isValid ? "✅ Valid" : "❌ Invalid")")
            }) {
                Label("Verify Data Integrity", systemImage: "checkmark.shield")
            }
            
            Button(action: {
                dashboardViewModel.testCoreDataOperations()
            }) {
                Label("Test Core Data", systemImage: "testtube.2")
            }
            
            Button(action: {
                CoreDataTestHelper.shared.runAllTests()
            }) {
                Label("Run All Tests", systemImage: "play.circle")
            }
            
            Button(action: {
                let summary = CoreDataTestHelper.shared.getStatusSummary()
                print("📊 \(summary)")
            }) {
                Label("Status Summary", systemImage: "info.circle")
            }
            
            Divider()
            
            Button(action: {
                CoreDataConfiguration.shared.resetCoreDataStore()
            }) {
                Label("Reset Core Data Store", systemImage: "arrow.clockwise.circle")
            }
            
            Button(action: {
                CoreDataConfiguration.shared.completelyResetCoreData()
            }) {
                Label("Complete Reset", systemImage: "trash.circle")
            }
            
            Button(action: {
                CoreDataConfiguration.shared.deleteCoreDataFiles()
            }) {
                Label("Delete Core Data Files", systemImage: "externaldrive.badge.minus")
            }
            
            Button(action: {
                dashboardViewModel.forceResetCoreData()
            }) {
                Label("Force Reset Dashboard", systemImage: "arrow.clockwise.circle.fill")
            }
            
            Button(action: {
                CoreDataConfiguration.shared.nuclearResetCoreData()
            }) {
                Label("☢️ NUCLEAR RESET", systemImage: "exclamationmark.triangle.fill")
            }
            
            Button(action: {
                CoreDataConfiguration.shared.completeCoreDataReinitialization()
            }) {
                Label("🏗️ COMPLETE REINIT", systemImage: "hammer.fill")
            }
            
            Divider()
            
            Button(action: {
                dashboardViewModel.enableCoreDataBypassMode()
            }) {
                Label("Enable Bypass Mode", systemImage: "wifi.slash")
            }
            
            Button(action: {
                dashboardViewModel.disableCoreDataBypassMode()
            }) {
                Label("Disable Bypass Mode", systemImage: "wifi")
            }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    HStack(spacing: 8) {
                        Text("Manage your properties & earnings")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                        
                        if dashboardViewModel.isOfflineMode {
                            HStack(spacing: 4) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 10))
                                Text("Offline")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                        }
                        
                            if let lastSync = dashboardViewModel.lastSyncTime {
                                Text("Updated \(formatLastSync(lastSync))")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.mutedForeground)
                            }
                            
                            // Core Data status indicator
                            if dashboardViewModel.hasCachedData() {
                                HStack(spacing: 4) {
                                    Image(systemName: "internaldrive")
                                        .font(.system(size: 10))
                                    Text("Cached")
                                        .font(.caption2)
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            }
                            
                            // Bypass mode indicator
                            if UserDefaults.standard.bool(forKey: "core_data_bypass_mode") {
                                HStack(spacing: 4) {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 10))
                                    Text("Bypass")
                                        .font(.caption2)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                            }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Sync button
                    Button(action: {
                        dashboardViewModel.refreshDashboard()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.primary)
                    }
                    .disabled(dashboardViewModel.isLoading)
                    
                    // Add property button
                NavigationLink(destination: PostPlaceView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(AppColors.background)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if dashboardViewModel.isOfflineMode {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Offline Mode")
                        .font(.headline)
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Showing cached data. Pull to refresh when online.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.primary)
                
                Text("Loading dashboard...")
                .font(.subheadline)
                .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
    }
    
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Statistics Cards
                statisticsSection
                
                // Tab Selector
                tabSelector
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        habitationsSection
                    case 1:
                        reservationsSection
                    case 2:
                        paymentsSection
                    default:
                        habitationsSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "house.circle")
                .font(.system(size: 70))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("No habitations yet")
                .font(.title3.bold())
                .foregroundColor(AppColors.foreground)
            
            Text("You haven't posted any habitations yet. Tap the + button to create your first listing.")
                .font(.subheadline)
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            NavigationLink(destination: PostPlaceView()) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add New Habitation")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Earnings",
                    value: dashboardViewModel.formatCurrency(dashboardViewModel.totalEarnings),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Properties",
                    value: "\(dashboardViewModel.totalHabitations)",
                    icon: "house.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Reservations",
                    value: "\(dashboardViewModel.totalReservations)",
                    icon: "calendar.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Payments",
                    value: "\(dashboardViewModel.totalPayments)",
                    icon: "creditcard.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Properties",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "Reservations",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                title: "Payments",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.input)
        )
    }
    
    // MARK: - Habitations Section
    
    private var habitationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Properties")
                    .font(.headline)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Text("\(dashboardViewModel.availableHabitations) available, \(dashboardViewModel.reservedHabitations) reserved")
                    .font(.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.habitations) { habitation in
                    DashboardHabitationCard(
                        habitation: habitation,
                        onTapReservationHistory: {
                            selectedHabitation = habitation
                            showingReservationHistory = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Reservations Section
    
    private var reservationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Reservations")
                    .font(.headline)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Text("\(dashboardViewModel.activeReservations) active")
                    .font(.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.getRecentReservations()) { reservation in
                    ReservationCard(reservation: reservation)
                }
            }
        }
    }
    
    // MARK: - Payments Section
    
    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Payments")
                    .font(.headline)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Text("Total: \(dashboardViewModel.formatCurrency(dashboardViewModel.totalEarnings))")
                    .font(.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.getRecentPayments()) { payment in
                    DashboardPaymentCard(payment: payment)
                }
            }
        }
    }
    
    private func loadDashboardData() {
        // Try to load cached data first
        if dashboardViewModel.hasCachedData() {
            dashboardViewModel.loadCachedData()
        }
        
        // Then fetch fresh data
        dashboardViewModel.fetchDashboardForCurrentUser()
    }
    
    private func formatLastSync(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Dashboard Card Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(AppColors.foreground)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
            .background(
            RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .overlay(
                    RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )
        }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? AppColors.foreground : AppColors.mutedForeground)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppColors.primary : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DashboardHabitationCard: View {
    let habitation: DashboardHabitation
    let onTapReservationHistory: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with image and status
        ZStack(alignment: .topTrailing) {
                if let mainPictureUrl = habitation.mainPictureUrl {
                    CachedImage(url: mainPictureUrl, contentMode: .fill) {
                        placeholderImage
                    }
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                } else {
                    placeholderImage
                        .frame(height: 120)
            }
            
            // Status badge
                Text(habitation.statusText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(habitation.isReserved ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    .cornerRadius(8)
                    .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habitation.name)
                        .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                
                Spacer()
                
                Text(habitation.type)
                        .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(8)
            }
            
            Text("Rs. \(habitation.price) / month")
                    .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
                // Stats row
                HStack(spacing: 16) {
                    statItem(icon: "calendar", value: "\(habitation.reservationCount) reservations")
                    statItem(icon: "creditcard", value: "\(habitation.paymentCount) payments")
                    statItem(icon: "dollarsign", value: "Rs. \(String(format: "%.0f", habitation.totalEarnings))")
                }
                
                // Reserved user info
                if let reservedUser = habitation.reservedUser {
                HStack {
                        Image(systemName: "person.circle")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                    
                        Text("Reserved by: \(reservedUser.firstName) \(reservedUser.lastName)")
                            .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onTapReservationHistory) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
    
    private var placeholderImage: some View {
        ZStack {
            Rectangle()
                .fill(AppColors.input)
            
            Image(systemName: "photo")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppColors.mutedForeground)
        }
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }
    
    private func statItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(AppColors.mutedForeground)
            
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

struct ReservationCard: View {
    let reservation: DashboardReservation
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reservation.userFullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text(reservation.habitation?.name ?? "Unknown Property")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("Status: \(reservation.statusText)")
                    .font(.system(size: 11))
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(reservation.reservedDateTime))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.mutedForeground)
                
                if reservation.isPaymentCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.input)
        )
    }
    
    private var statusColor: Color {
        switch reservation.status {
        case "pending":
            return .orange
        case "confirmed":
            return .green
        case "expired":
            return .red
        case "cancelled":
            return .gray
        default:
            return .blue
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct DashboardPaymentCard: View {
    let payment: DashboardPayment
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.formattedAmount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text(payment.amountType.capitalized)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                if payment.discount > 0 {
                    Text("Discount: \(payment.currencyType) \(String(format: "%.2f", payment.discount))")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(payment.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text(payment.currencyType)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.input)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}