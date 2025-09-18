import Foundation
import SwiftUI

/**
 * AccessibilityViewModel - Comprehensive Accessibility Settings Manager
 *
 * Manages user accessibility preferences and synchronizes them with the backend server.
 * Provides real-time application of accessibility settings across the entire app.
 *
 * Key Responsibilities:
 * - Fetch and update accessibility settings from/to server
 * - Apply accessibility settings system-wide through GlobalAccessibilityManager
 * - Provide debounced saving to prevent excessive API calls
 * - Handle local persistence for offline functionality
 * - Manage individual accessibility feature toggles
 * - Provide comprehensive error handling and user feedback
 */
@MainActor
class AccessibilityViewModel: ObservableObject {
    
    /**
     * Core accessibility settings with automatic application and debounced saving.
     * Changes trigger immediate UI updates and delayed server synchronization.
     */
    @Published var accessibilitySettings = AccessibilitySettings() {
        didSet {
            applyAccessibilitySettings()
            debouncedSave()
        }
    }
    
    /// Loading state for UI feedback during API operations
    @Published var isLoading = false
    
    /// Current error message for user display
    @Published var errorMessage: String?
    
    /// Flag indicating if there's an active error
    @Published var hasError = false
    
    /// Success message for save operations
    @Published var saveSuccessMessage: String?
    
    /// Flag indicating if success message should be shown
    @Published var showSaveSuccess = false
    
    /// Network manager for API communication
    private let networkManager = NetworkManager.shared
    
    /// Work item for debounced save operations to prevent excessive API calls
    private var saveWorkItem: DispatchWorkItem?
    
    /// Flag to prevent infinite loops when updating from API responses
    private var isUpdatingFromAPI = false
    
    /**
     * Fetches user accessibility settings from the server.
     * Validates user authentication and updates local settings with server data.
     * 
     * @param userId The unique identifier for the user whose settings to fetch
     */
    func fetchAccessibilitySettings(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isLoading = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getAccessibilitySettings(userId: userId),
            headers: headers,
            responseType: AccessibilityResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from fetching accessibility settings.
     * Updates local settings on success or displays appropriate error messages.
     */
    private func handleFetchResponse(_ result: Result<AccessibilityResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            if response.success {
                isUpdatingFromAPI = true
                accessibilitySettings = response.data ?? AccessibilitySettings()
                isUpdatingFromAPI = false
                print("✅ Accessibility settings fetched successfully")
            } else {
                showError(response.message ?? "Failed to fetch accessibility settings")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Network error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Updates user accessibility settings on the server.
     * Validates authentication and sends current settings to backend for persistence.
     * 
     * @param userId The unique identifier for the user whose settings to update
     */
    func updateAccessibilitySettings(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isLoading = true
        clearError()
        clearSaveSuccess()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .updateAccessibilitySettings(userId: userId),
            body: accessibilitySettings,
            headers: headers,
            responseType: AccessibilityResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpdateResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from updating accessibility settings.
     * Shows success message on successful update or displays error information.
     */
    private func handleUpdateResponse(_ result: Result<AccessibilityResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            if response.success {
                showSaveSuccess("Accessibility settings saved successfully")
            } else {
                showError(response.message ?? "Failed to update accessibility settings")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Network error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Applies accessibility settings system-wide through GlobalAccessibilityManager.
     * Prevents infinite loops by checking if update is from API response.
     * Also persists settings locally for offline functionality.
     */
    private func applyAccessibilitySettings() {
        guard !isUpdatingFromAPI else { return }
        
        GlobalAccessibilityManager.shared.updateSettings(accessibilitySettings)
        
        logSettingsApplication()
        storeSettingsLocally()
    }
    
    /**
     * Logs the current accessibility settings for debugging purposes.
     * Provides visibility into which settings are currently active.
     */
    private func logSettingsApplication() {
        print("📱 Applied accessibility settings system-wide:")
        print("  - Large text: \(accessibilitySettings.largeText)")
        print("  - High contrast: \(accessibilitySettings.highContrast)")
        print("  - Reduce motion: \(accessibilitySettings.reduceMotion)")
        print("  - VoiceOver: \(accessibilitySettings.voiceOver)")
        print("  - Screen reader: \(accessibilitySettings.screenReader)")
        print("  - Color blind assist: \(accessibilitySettings.colorBlindAssist)")
        print("  - Haptic feedback: \(accessibilitySettings.hapticFeedback)")
    }
    
    /**
     * Implements debounced saving to prevent excessive API calls during rapid setting changes.
     * Cancels previous save operations and schedules a new one with a 1-second delay.
     * Only executes if not currently updating from API to prevent infinite loops.
     */
    private func debouncedSave() {
        guard !isUpdatingFromAPI else { return }
        
        saveWorkItem?.cancel()
        
        saveWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if let userId = UserDefaults.standard.string(forKey: "user_id") {
                self.updateAccessibilitySettings(userId: userId)
            }
        }
        
        if let workItem = saveWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        }
    }
    
    /**
     * Stores accessibility settings locally using UserDefaults for offline persistence.
     * Encodes settings as JSON data to maintain structure and type safety.
     */
    private func storeSettingsLocally() {
        if let encoded = try? JSONEncoder().encode(accessibilitySettings) {
            UserDefaults.standard.set(encoded, forKey: "accessibility_settings")
        }
    }
    
    /**
     * Loads previously stored accessibility settings from local storage.
     * Prevents triggering save operations by setting API update flag during load.
     * Used for offline functionality and app launch restoration.
     */
    func loadLocalSettings() {
        if let data = UserDefaults.standard.data(forKey: "accessibility_settings"),
           let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            isUpdatingFromAPI = true
            accessibilitySettings = settings
            isUpdatingFromAPI = false
        }
    }
    
    /**
     * Toggles the large text accessibility setting.
     * Automatically triggers system-wide application and server synchronization.
     */
    func toggleLargeText() {
        accessibilitySettings.largeText.toggle()
    }
    
    /**
     * Toggles the high contrast accessibility setting.
     * Enhances visual accessibility for users with vision impairments.
     */
    func toggleHighContrast() {
        accessibilitySettings.highContrast.toggle()
    }
    
    /**
     * Toggles the VoiceOver accessibility setting.
     * Enables or disables screen reading functionality.
     */
    func toggleVoiceOver() {
        accessibilitySettings.voiceOver.toggle()
    }
    
    /**
     * Toggles the reduce motion accessibility setting.
     * Minimizes animations for users sensitive to motion.
     */
    func toggleReduceMotion() {
        accessibilitySettings.reduceMotion.toggle()
    }
    
    /**
     * Toggles the screen reader accessibility setting.
     * Enables compatibility with external screen reading software.
     */
    func toggleScreenReader() {
        accessibilitySettings.screenReader.toggle()
    }
    
    /**
     * Toggles the color blind assist accessibility setting.
     * Provides enhanced color differentiation for color vision deficiencies.
     */
    func toggleColorBlindAssist() {
        accessibilitySettings.colorBlindAssist.toggle()
    }
    
    /**
     * Toggles the haptic feedback accessibility setting.
     * Controls tactile feedback for enhanced user interaction.
     */
    func toggleHapticFeedback() {
        accessibilitySettings.hapticFeedback.toggle()
    }
    
    /**
     * Handles network errors with appropriate user feedback and error recovery.
     * Provides specific handling for different error types including authentication failures.
     */
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            handleTypedNetworkError(networkError)
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Handles specific NetworkError types with tailored responses.
     * Includes automatic token cleanup for unauthorized errors.
     */
    private func handleTypedNetworkError(_ networkError: NetworkError) {
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
    }
    
    /**
     * Displays error message to user and logs for debugging.
     * Sets error flags for UI state management.
     */
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Accessibility Error: \(message)")
    }
    
    /**
     * Clears current error state and message.
     * Used when starting new operations or on successful completion.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Displays success message with automatic dismissal after 3 seconds.
     * Provides positive feedback for successful save operations.
     */
    private func showSaveSuccess(_ message: String) {
        saveSuccessMessage = message
        showSaveSuccess = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.clearSaveSuccess()
        }
    }
    
    /**
     * Clears success message and related UI state.
     * Called automatically after timeout or manually when needed.
     */
    private func clearSaveSuccess() {
        saveSuccessMessage = nil
        showSaveSuccess = false
    }
    
    /**
     * Resets all accessibility settings to their default values.
     * Triggers automatic application and server synchronization.
     */
    func resetToDefaults() {
        accessibilitySettings = AccessibilitySettings()
    }
}

/**
 * Response model for accessibility settings API calls.
 * Provides structured response handling with success status, message, and data payload.
 */
struct AccessibilityResponse: Codable {
    let success: Bool
    let message: String?
    let data: AccessibilitySettings?
}
