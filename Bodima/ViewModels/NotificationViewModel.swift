import Foundation
import SwiftUI
import UserNotifications

/**
 * NotificationViewModel manages the notification system for the Bodima application.
 * Handles fetching, displaying, and managing user notifications with real-time updates
 * and proper state management for UI components.
 * 
 * Features:
 * - Real-time notification fetching and updates
 * - Mark notifications as read with optimistic UI updates
 * - Automatic notification observer setup for app-wide refresh
 * - Comprehensive error handling with user-friendly messages
 * - Grouped notification display by date sections
 * - Unread notification count tracking
 */
@MainActor
class NotificationViewModel: ObservableObject {
    
    /**
     * Published properties for reactive UI updates and state management.
     */
    @Published var notifications: [NotificationModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    /**
     * Network manager instance for API communication.
     */
    private let networkManager = NetworkManager.shared
    
    /**
     * Initializes the NotificationViewModel and sets up notification observers.
     * Automatically begins fetching notifications upon initialization.
     */
    init() {
        setupNotificationObserver()
    }
    
    /**
     * Cleanup method called when the view model is deallocated.
     * Removes all notification observers to prevent memory leaks.
     */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     * Notification observer management for real-time updates across the application.
     */
    
    /**
     * Sets up notification observer for app-wide refresh functionality.
     * Registers for "RefreshNotifications" broadcast and initializes data fetching.
     */
    func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshNotifications),
            name: NSNotification.Name("RefreshNotifications"),
            object: nil
        )
        
        fetchNotifications()
    }
    
    /**
     * Objective-C compatible method for handling notification refresh broadcasts.
     * Called automatically when "RefreshNotifications" notification is posted.
     */
    @objc private func refreshNotifications() {
        fetchNotifications()
    }
    
    /**
     * Core notification data management methods.
     */
    
    /**
     * Fetches all notifications for the current authenticated user.
     * Implements proper authentication validation and comprehensive error handling.
     * Updates UI state throughout the request lifecycle.
     */
    func fetchNotifications() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please sign in again.")
            return
        }
        
        isLoading = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getNotifications,
            headers: headers,
            responseType: NotificationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchNotificationsResponse(result)
            }
        }
    }
    
    /**
     * Marks a specific notification as read with optimistic UI updates.
     * Implements immediate local state update for responsive UI, followed by server synchronization.
     * Automatically reverts local changes if server update fails.
     * 
     * @param notificationId The unique identifier of the notification to mark as read
     */
    func markNotificationAsRead(notificationId: String) {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please sign in again.")
            return
        }
        
        updateLocalNotificationState(notificationId: notificationId)
        syncNotificationReadState(notificationId: notificationId, token: token)
    }
    
    /**
     * Private helper methods for internal notification management operations.
     */
    
    /**
     * Handles the response from notification fetch API calls.
     * Processes successful responses and delegates error handling appropriately.
     * 
     * @param result The result from the network request containing either success or failure
     */
    private func handleFetchNotificationsResponse(_ result: Result<NotificationResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            if response.success {
                notifications = response.data
                print("✅ Notifications fetched successfully")
            } else {
                showError("Failed to fetch notifications")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch notifications error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Updates the local notification state for immediate UI feedback.
     * Marks the specified notification as read in the local notifications array.
     * 
     * @param notificationId The unique identifier of the notification to update
     */
    private func updateLocalNotificationState(notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            var updatedNotification = notifications[index]
            updatedNotification.isTouched = true
            notifications[index] = updatedNotification
        }
    }
    
    /**
     * Synchronizes the notification read state with the server.
     * Reverts local changes if server update fails to maintain data consistency.
     * 
     * @param notificationId The unique identifier of the notification to sync
     * @param token The authentication token for API authorization
     */
    private func syncNotificationReadState(notificationId: String, token: String) {
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        struct EmptyBody: Codable {}
        
        networkManager.requestWithHeaders(
            endpoint: .markNotificationAsRead(notificationId: notificationId),
            body: EmptyBody(),
            headers: headers,
            responseType: NotificationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleMarkAsReadResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from mark notification as read API calls.
     * Reverts local state if server update fails to maintain consistency.
     * 
     * @param result The result from the mark as read network request
     */
    private func handleMarkAsReadResponse(_ result: Result<NotificationResponse, Error>) {
        switch result {
        case .success(let response):
            if response.success {
                print("✅ Notification marked as read successfully")
            } else {
                print("⚠️ Failed to mark notification as read: \(response.data)")
                fetchNotifications() // Revert local state
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Mark notification as read error: \(error)")
            fetchNotifications() // Revert local state
        }
    }
    
    /**
     * Error handling and user feedback methods.
     */
    
    /**
     * Displays an error message to the user and sets error state.
     * 
     * @param message The error message to display to the user
     */
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
    }
    
    /**
     * Clears the current error state and message.
     * Used when starting new operations or recovering from errors.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Handles network errors with appropriate user feedback and authentication cleanup.
     * Provides specific error messages based on error type and handles token cleanup for unauthorized errors.
     * 
     * @param error The network error to handle and present to the user
     */
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
    
    /**
     * Computed properties for notification analysis and UI presentation.
     */
    
    /**
     * Calculates the total number of unread notifications.
     * Used for badge display and notification indicators in the UI.
     * 
     * @return The count of notifications that have not been marked as read
     */
    var unreadCount: Int {
        notifications.filter { !$0.isTouched }.count
    }
    
    /**
     * Groups notifications by date sections for organized display.
     * Creates logical groupings (Today, Yesterday, Earlier) for better user experience.
     * 
     * @return Dictionary mapping date section names to arrays of notifications
     */
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
    
    /**
     * Utility methods for notification management.
     */
    
    /**
     * Marks all notifications as read in batch operation.
     * Provides convenient way to clear all unread notifications at once.
     */
    func markAllNotificationsAsRead() {
        let unreadNotifications = notifications.filter { !$0.isTouched }
        
        for notification in unreadNotifications {
            markNotificationAsRead(notificationId: notification.id)
        }
    }
    
    /**
     * Refreshes notification data by clearing current state and fetching fresh data.
     * Used for pull-to-refresh functionality and manual refresh operations.
     */
    func refreshNotificationData() {
        clearError()
        fetchNotifications()
    }
}
