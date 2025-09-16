import Foundation
import SwiftUI

@MainActor
class AccessibilityViewModel: ObservableObject {
    @Published var accessibilitySettings = AccessibilitySettings() {
        didSet {
            // Apply settings immediately for UI responsiveness
            applyAccessibilitySettings()
            // Debounce API calls to prevent infinite loops
            debouncedSave()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var saveSuccessMessage: String?
    @Published var showSaveSuccess = false
    
    private let networkManager = NetworkManager.shared
    private var saveWorkItem: DispatchWorkItem?
    private var isUpdatingFromAPI = false
    
    // MARK: - Fetch Accessibility Settings
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
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self?.isUpdatingFromAPI = true
                        self?.accessibilitySettings = response.data ?? AccessibilitySettings()
                        self?.isUpdatingFromAPI = false
                        print("✅ Accessibility settings fetched successfully")
                    } else {
                        self?.showError(response.message ?? "Failed to fetch accessibility settings")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Network error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Update Accessibility Settings
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
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self?.showSaveSuccess("Accessibility settings saved successfully")
                        // Don't call applyAccessibilitySettings here to prevent loops
                    } else {
                        self?.showError(response.message ?? "Failed to update accessibility settings")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Network error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Apply Accessibility Settings
    private func applyAccessibilitySettings() {
        // Only apply if not updating from API to prevent loops
        guard !isUpdatingFromAPI else { return }
        
        // Apply settings globally through the GlobalAccessibilityManager
        GlobalAccessibilityManager.shared.updateSettings(accessibilitySettings)
        
        print("📱 Applied accessibility settings system-wide:")
        print("  - Large text: \(accessibilitySettings.largeText)")
        print("  - High contrast: \(accessibilitySettings.highContrast)")
        print("  - Reduce motion: \(accessibilitySettings.reduceMotion)")
        print("  - VoiceOver: \(accessibilitySettings.voiceOver)")
        print("  - Screen reader: \(accessibilitySettings.screenReader)")
        print("  - Color blind assist: \(accessibilitySettings.colorBlindAssist)")
        print("  - Haptic feedback: \(accessibilitySettings.hapticFeedback)")
        
        // Store settings locally for persistence
        storeSettingsLocally()
    }
    
    // MARK: - Debounced Save
    private func debouncedSave() {
        // Only save if not updating from API
        guard !isUpdatingFromAPI else { return }
        
        // Cancel previous save work item
        saveWorkItem?.cancel()
        
        // Create new work item with delay
        saveWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if let userId = UserDefaults.standard.string(forKey: "user_id") {
                self.updateAccessibilitySettings(userId: userId)
            }
        }
        
        // Execute after 1 second delay to debounce rapid changes
        if let workItem = saveWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        }
    }
    
    // MARK: - Local Storage
    private func storeSettingsLocally() {
        if let encoded = try? JSONEncoder().encode(accessibilitySettings) {
            UserDefaults.standard.set(encoded, forKey: "accessibility_settings")
        }
    }
    
    func loadLocalSettings() {
        if let data = UserDefaults.standard.data(forKey: "accessibility_settings"),
           let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            isUpdatingFromAPI = true
            accessibilitySettings = settings
            isUpdatingFromAPI = false
        }
    }
    
    // MARK: - Individual Setting Updates
    func toggleLargeText() {
        accessibilitySettings.largeText.toggle()
    }
    
    func toggleHighContrast() {
        accessibilitySettings.highContrast.toggle()
    }
    
    func toggleVoiceOver() {
        accessibilitySettings.voiceOver.toggle()
    }
    
    func toggleReduceMotion() {
        accessibilitySettings.reduceMotion.toggle()
    }
    
    func toggleScreenReader() {
        accessibilitySettings.screenReader.toggle()
    }
    
    func toggleColorBlindAssist() {
        accessibilitySettings.colorBlindAssist.toggle()
    }
    
    func toggleHapticFeedback() {
        accessibilitySettings.hapticFeedback.toggle()
    }
    
    // MARK: - Error Handling
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
    
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Accessibility Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    private func showSaveSuccess(_ message: String) {
        saveSuccessMessage = message
        showSaveSuccess = true
        
        // Auto-hide success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.clearSaveSuccess()
        }
    }
    
    private func clearSaveSuccess() {
        saveSuccessMessage = nil
        showSaveSuccess = false
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        accessibilitySettings = AccessibilitySettings()
    }
}

// MARK: - Response Models
struct AccessibilityResponse: Codable {
    let success: Bool
    let message: String?
    let data: AccessibilitySettings?
}
