import Foundation

/**
 * ViewModel for managing habitation image operations in the Bodima application.
 * Handles image addition, retrieval, and management for habitation properties.
 * 
 * This ViewModel provides:
 * - Image addition with validation and error handling
 * - Image retrieval for specific habitations
 * - State management for UI updates
 * - Integration with NetworkManager for API communication
 * - Comprehensive error handling and user feedback
 */

@MainActor
class HabitationImageViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of all habitation images loaded in the application
    @Published var habitationImages: [HabitationImageData] = []
    
    /// Array of images for the currently selected habitation
    @Published var selectedHabitationImages: [HabitationImageData] = []
    
    /// General loading state indicator
    @Published var isLoading = false
    
    /// General error message for display
    @Published var errorMessage: String?
    
    /// Boolean flag indicating if there's an active error
    @Published var hasError = false
    
    /// Loading state specifically for image addition operations
    @Published var isAddingImage = false
    
    /// Success state for image addition operations
    @Published var imageAdditionSuccess = false
    
    /// Message related to image addition operations
    @Published var imageAdditionMessage: String?
    
    /// The most recently added image data
    @Published var addedImage: HabitationImageData?
    
    /// Loading state specifically for image fetching operations
    @Published var isFetchingImages = false
    
    /// Error message specifically for image fetching operations
    @Published var fetchImagesError: String?
    
    // MARK: - Private Properties
    
    /// Shared network manager instance for API communication
    private let networkManager = NetworkManager.shared
    
    // MARK: - Public Methods
    
    /**
     * Adds a new image to a habitation property.
     * Validates input parameters, authenticates the request, and handles the response.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param pictureUrl The URL of the image to add
     * 
     * @throws HabitationImageError.invalidHabitationId if habitationId is empty
     * @throws HabitationImageError.invalidImageUrl if pictureUrl is empty
     * @throws NetworkError.unauthorized if authentication token is missing
     */
    func addHabitationImage(
        habitationId: String,
        pictureUrl: String
    ) {
        guard validateImageAdditionParameters(habitationId: habitationId, pictureUrl: pictureUrl) else {
            return
        }
        
        guard let token = validateAuthenticationToken() else {
            showImageAdditionError("Authentication token not found. Please login again.")
            return
        }
        
        prepareImageAdditionRequest()
        
        let addImageRequest = buildImageAdditionRequest(
            habitationId: habitationId,
            pictureUrl: pictureUrl
        )
        
        let headers = buildAuthenticationHeaders(token: token)
        
        processImageAdditionRequest(
            request: addImageRequest,
            headers: headers,
            habitationId: habitationId
        )
    }
    
    /**
     * Fetches all images associated with a specific habitation.
     * Validates the habitation ID, authenticates the request, and updates the UI state.
     * 
     * @param habitationId The unique identifier of the habitation
     * 
     * @throws HabitationImageError.invalidHabitationId if habitationId is empty
     * @throws NetworkError.unauthorized if authentication token is missing
     */
    func fetchImagesForHabitation(habitationId: String) {
        guard validateHabitationId(habitationId) else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = validateAuthenticationToken() else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        prepareImageFetchRequest()
        
        let headers = buildAuthenticationHeaders(token: token)
        
        processImageFetchRequest(
            habitationId: habitationId,
            headers: headers
        )
    }
    
    // MARK: - Public Utility Methods
    
    /**
     * Retrieves all images associated with a specific habitation.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return Array of HabitationImageData for the specified habitation
     */
    func getImagesForHabitation(habitationId: String) -> [HabitationImageData] {
        return habitationImages.filter { $0.habitation == habitationId }
    }
    
    /**
     * Gets the count of images for a specific habitation.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return The number of images associated with the habitation
     */
    func getImageCount(for habitationId: String) -> Int {
        return getImagesForHabitation(habitationId: habitationId).count
    }
    
    /**
     * Gets the URL of the first image for a specific habitation.
     * Useful for displaying a primary image or thumbnail.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return The URL of the first image, or nil if no images exist
     */
    func getFirstImageUrl(for habitationId: String) -> String? {
        return getImagesForHabitation(habitationId: habitationId).first?.pictureUrl
    }
    
    /**
     * Removes an image from both the main list and selected images list.
     * 
     * @param imageId The unique identifier of the image to remove
     */
    func removeImageFromList(imageId: String) {
        habitationImages.removeAll { $0.id == imageId }
        selectedHabitationImages.removeAll { $0.id == imageId }
    }
    
    // MARK: - Private Helper Methods
    
    /**
     * Validates parameters for image addition operations.
     * 
     * @param habitationId The habitation ID to validate
     * @param pictureUrl The picture URL to validate
     * @return True if parameters are valid, false otherwise
     */
    private func validateImageAdditionParameters(habitationId: String, pictureUrl: String) -> Bool {
        guard !habitationId.isEmpty else {
            showImageAdditionError("Habitation ID is required")
            return false
        }
        
        guard !pictureUrl.isEmpty else {
            showImageAdditionError("Picture URL is required")
            return false
        }
        
        return true
    }
    
    /**
     * Validates habitation ID for operations.
     * 
     * @param habitationId The habitation ID to validate
     * @return True if valid, false otherwise
     */
    private func validateHabitationId(_ habitationId: String) -> Bool {
        return !habitationId.isEmpty
    }
    
    /**
     * Validates and retrieves authentication token from UserDefaults.
     * 
     * @return Authentication token if valid, nil otherwise
     */
    private func validateAuthenticationToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    /**
     * Prepares the UI state for image addition request.
     */
    private func prepareImageAdditionRequest() {
        isAddingImage = true
        clearImageAdditionError()
    }
    
    /**
     * Prepares the UI state for image fetch request.
     */
    private func prepareImageFetchRequest() {
        isFetchingImages = true
        clearError()
    }
    
    /**
     * Builds the request object for image addition.
     * 
     * @param habitationId The habitation ID
     * @param pictureUrl The picture URL
     * @return Configured AddHabitationImageRequest object
     */
    private func buildImageAdditionRequest(
        habitationId: String,
        pictureUrl: String
    ) -> AddHabitationImageRequest {
        return AddHabitationImageRequest(
            habitation: habitationId,
            pictureUrl: pictureUrl
        )
    }
    
    /**
     * Builds authentication headers for API requests.
     * 
     * @param token The authentication token
     * @return Dictionary of HTTP headers
     */
    private func buildAuthenticationHeaders(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    /**
     * Processes the image addition network request.
     * 
     * @param request The image addition request
     * @param headers The HTTP headers
     * @param habitationId The habitation ID for response handling
     */
    private func processImageAdditionRequest(
        request: AddHabitationImageRequest,
        headers: [String: String],
        habitationId: String
    ) {
        networkManager.requestWithHeaders(
            endpoint: .addHabitaionImage(habitationId: habitationId),
            body: request,
            headers: headers,
            responseType: AddHabitationImageResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleImageAdditionResponse(result, habitationId: habitationId)
            }
        }
    }
    
    /**
     * Processes the image fetch network request.
     * 
     * @param habitationId The habitation ID
     * @param headers The HTTP headers
     */
    private func processImageFetchRequest(
        habitationId: String,
        headers: [String: String]
    ) {
        networkManager.requestWithHeaders(
            endpoint: .getHabitationById(habitationId: habitationId),
            headers: headers,
            responseType: GetHabitationImagesResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleImageFetchResponse(result)
            }
        }
    }
    
    /**
     * Handles the response from image addition API call.
     * 
     * @param result The network result
     * @param habitationId The habitation ID for local state updates
     */
    private func handleImageAdditionResponse(
        _ result: Result<AddHabitationImageResponse, Error>,
        habitationId: String
    ) {
        isAddingImage = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - AddHabitationImage success: \(response.success)")
            print("🔍 DEBUG - AddHabitationImage message: \(response.message)")
            print("🔍 DEBUG - AddHabitationImage data: \(String(describing: response.data))")
            
            if response.success {
                handleSuccessfulImageAddition(response, habitationId: habitationId)
            } else {
                showImageAdditionError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Add habitation image error: \(error)")
            handleImageAdditionError(error)
        }
    }
    
    /**
     * Handles the response from image fetch API call.
     * 
     * @param result The network result
     */
    private func handleImageFetchResponse(
        _ result: Result<GetHabitationImagesResponse, Error>
    ) {
        isFetchingImages = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetHabitationImages success: \(response.success)")
            print("🔍 DEBUG - GetHabitationImages data count: \(response.data?.count ?? 0)")
            
            if response.success {
                selectedHabitationImages = response.data ?? []
                print("✅ Habitation images fetched successfully: \(selectedHabitationImages.count) items")
            } else {
                showError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch habitation images error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles successful image addition by updating local state.
     * 
     * @param response The successful API response
     * @param habitationId The habitation ID
     */
    private func handleSuccessfulImageAddition(
        _ response: AddHabitationImageResponse,
        habitationId: String
    ) {
        imageAdditionSuccess = true
        imageAdditionMessage = response.message
        addedImage = response.data
        print("✅ Habitation image added successfully")
        
        // Add the new image to the list
        if let newImage = response.data {
            habitationImages.append(newImage)
            
            // If this is for the currently selected habitation, add to selected images
            if newImage.habitation == habitationId {
                selectedHabitationImages.append(newImage)
            }
        }
    }
    
    // MARK: - Error Handling Methods
    
    /**
     * Handles network errors with appropriate user messaging and token cleanup.
     * 
     * @param error The network error to handle
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
     * Handles image addition specific errors with appropriate messaging.
     * 
     * @param error The error that occurred during image addition
     */
    private func handleImageAdditionError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showImageAdditionError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showImageAdditionError(message)
                
            case .serverError(let message):
                showImageAdditionError("Server error: \(message)")
                
            default:
                showImageAdditionError(networkError.localizedDescription)
            }
        } else {
            showImageAdditionError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Displays a general error message and updates error state.
     * 
     * @param message The error message to display
     */
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Habitation Image Error: \(message)")
    }
    
    /**
     * Clears the general error state and message.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Displays an image addition specific error message.
     * 
     * @param message The error message to display
     */
    func showImageAdditionError(_ message: String) {
        imageAdditionMessage = message
        imageAdditionSuccess = false
        print("❌ Habitation Image Addition Error: \(message)")
    }
    
    /**
     * Clears the image addition error state and message.
     */
    private func clearImageAdditionError() {
        imageAdditionMessage = nil
        imageAdditionSuccess = false
    }
    
    // MARK: - Computed Properties
    
    /**
     * Total count of all habitation images in the application.
     * 
     * @return The total number of images across all habitations
     */
    var totalImageCount: Int {
        return habitationImages.count
    }
    
    /**
     * Count of images for the currently selected habitation.
     * 
     * @return The number of images for the selected habitation
     */
    var selectedHabitationImageCount: Int {
        return selectedHabitationImages.count
    }
    
    // MARK: - Utility Methods
    
    /**
     * Formats an ISO8601 date string for user-friendly display.
     * 
     * @param dateString The ISO8601 formatted date string
     * @return Formatted date string for display, or original string if parsing fails
     */
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // MARK: - Data Management Methods
    
    /**
     * Clears all image data and resets error states.
     * Useful for logout or data refresh scenarios.
     */
    func clearAllImages() {
        habitationImages.removeAll()
        selectedHabitationImages.removeAll()
        clearError()
        clearImageAdditionError()
    }
    
    /**
     * Clears only the selected habitation images.
     * Used when switching between different habitations.
     */
    func clearSelectedHabitationImages() {
        selectedHabitationImages.removeAll()
    }
    
    /**
     * Resets all image addition related states to their initial values.
     * Useful for preparing for new image addition operations.
     */
    func resetImageAdditionState() {
        isAddingImage = false
        imageAdditionSuccess = false
        imageAdditionMessage = nil
        addedImage = nil
    }
}

// MARK: - HabitationImageViewModel Integration Extension

/**
 * Extension providing integration methods for seamless cooperation with other ViewModels
 * and enhanced functionality for habitation image management workflows.
 */
extension HabitationImageViewModel {
    
    /**
     * Adds an image to a newly created habitation.
     * Convenience method for post-creation image addition workflow.
     * 
     * @param habitationData The habitation data object
     * @param pictureUrl The URL of the image to add
     */
    func addImageToNewHabitation(
        habitationData: HabitationData,
        pictureUrl: String
    ) {
        addHabitationImage(
            habitationId: habitationData.id,
            pictureUrl: pictureUrl
        )
    }
    
    /**
     * Adds multiple images to a habitation in sequence.
     * Useful for bulk image upload scenarios.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param pictureUrls Array of image URLs to add
     */
    func addMultipleImages(
        habitationId: String,
        pictureUrls: [String]
    ) {
        for url in pictureUrls {
            addHabitationImage(habitationId: habitationId, pictureUrl: url)
        }
    }
    
    /**
     * Checks if a habitation has any associated images.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return True if the habitation has images, false otherwise
     */
    func hasImages(for habitationId: String) -> Bool {
        return !getImagesForHabitation(habitationId: habitationId).isEmpty
    }
    
    /**
     * Retrieves all image URLs for a specific habitation.
     * Useful for creating image galleries or carousels.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return Array of image URLs for the habitation
     */
    func getImageUrls(for habitationId: String) -> [String] {
        return getImagesForHabitation(habitationId: habitationId).map { $0.pictureUrl }
    }
    
    /**
     * Gets the most recently added image for a habitation.
     * Useful for displaying the latest uploaded image.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return The most recent image data, or nil if no images exist
     */
    func getMostRecentImage(for habitationId: String) -> HabitationImageData? {
        return getImagesForHabitation(habitationId: habitationId)
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    /**
     * Validates if an image URL is already associated with a habitation.
     * Prevents duplicate image additions.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param pictureUrl The image URL to check
     * @return True if the image already exists, false otherwise
     */
    func imageExists(for habitationId: String, pictureUrl: String) -> Bool {
        return getImagesForHabitation(habitationId: habitationId)
            .contains { $0.pictureUrl == pictureUrl }
    }
}

