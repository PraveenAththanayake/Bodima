import Foundation
import SwiftUI
import UserNotifications

@MainActor
class NotificationViewModel: ObservableObject {    
    // MARK: - Notification Observer
    
    func setupNotificationObserver() {
        // Set up notification observer for app-wide refresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotifications),
            name: NSNotification.Name("RefreshNotifications"),
            object: nil
        )
        
        // Initialize when the view model is created
        fetchNotifications()
    }
    
    @objc private func refreshNotifications() {
        fetchNotifications()
    }
    
    deinit {
        // Remove observer when view model is deallocated
        NotificationCenter.default.removeObserver(self)
    }
    @Published var notifications: [NotificationModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    private let networkManager = NetworkManager.shared
    
    init() {
        setupNotificationObserver()
    }
    
    // MARK: - Fetch Notifications
    func fetchNotifications() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please sign in again.")
            return
        }
        
        isLoading = true
        
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getNotifications,
            headers: headers,
            responseType: NotificationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self?.notifications = response.data
                        print("✅ Notifications fetched successfully")
                    } else {
                        self?.showError("Failed to fetch notifications")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch notifications error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Mark Notification as Read
    func markNotificationAsRead(notificationId: String) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please sign in again.")
            return
        }
        
        // Update local state first for immediate UI feedback
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            var updatedNotification = notifications[index]
            updatedNotification.isTouched = true
            notifications[index] = updatedNotification
        }
        
        // Make API call to update the server
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        // Empty body since we're just marking as read
        struct EmptyBody: Codable {}
        
        networkManager.requestWithHeaders(
            endpoint: .markNotificationAsRead(notificationId: notificationId),
            body: EmptyBody(),
            headers: headers,
            responseType: NotificationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        print("✅ Notification marked as read successfully")
                    } else {
                        print("⚠️ Failed to mark notification as read: \(response.data)")
                        // Revert the local state if the server update failed
                        self?.fetchNotifications()
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Mark notification as read error: \(error)")
                    // Revert the local state if the server update failed
                    self?.fetchNotifications()
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
    }
    
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showError(message)
                
            case .serverError(let message):
                showError("Server error: \(message)")
                
            default:
                showError(networkError.localizedDescription)
            }
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    var unreadCount: Int {
        notifications.filter { !$0.isTouched }.count
    }
    
    // Group notifications by date sections
    var groupedNotifications: [String: [NotificationModel]] {
        let grouped = Dictionary(grouping: notifications) { notification -> String in
            if notification.isToday {
                return "Today"
            } else if notification.isYesterday {
                return "Yesterday"
            } else {
                return "Earlier"
            }
        }
        return grouped
    }
}
