import Foundation

/**
 * HabitationViewModel - Comprehensive habitation management for the Bodima application.
 * 
 * This ViewModel provides complete CRUD operations for habitation properties, including both
 * original and enhanced data models with user details and pictures. It manages state for
 * creation, retrieval, updating, and deletion of habitations with proper authentication,
 * validation, and error handling.
 * 
 * Features:
 * - Dual model support (HabitationData and EnhancedHabitationData)
 * - Complete CRUD operations with network integration
 * - Advanced filtering and search capabilities
 * - User-specific habitation management
 * - Real-time state management with reactive UI updates
 * - Comprehensive error handling and validation
 * - Authentication token management
 * - Debug logging for development support
 * 
 * @MainActor ensures all UI updates occur on the main thread for SwiftUI compatibility.
 */
@MainActor
class HabitationViewModel: ObservableObject {
    // MARK: - Published Properties for Original Models
    
    /// Array of basic habitation data without user details
    @Published var habitations: [HabitationData] = []
    
    /// Currently selected basic habitation for detail operations
    @Published var selectedHabitation: HabitationData?
    
    /// General loading state for basic habitation operations
    @Published var isLoading = false
    
    /// General error message for display to users
    @Published var errorMessage: String?
    
    /// Boolean flag indicating presence of errors
    @Published var hasError = false
    
    /// Loading state specific to habitation creation operations
    @Published var isCreatingHabitation = false
    
    /// Success flag for habitation creation operations
    @Published var habitationCreationSuccess = false
    
    /// Success/error message for habitation creation feedback
    @Published var habitationCreationMessage: String?
    
    /// Newly created habitation data for immediate access
    @Published var createdHabitation: HabitationData?
    
    /// Loading state for fetching multiple habitations
    @Published var isFetchingHabitations = false
    
    /// Error message specific to habitation fetching operations
    @Published var fetchHabitationsError: String?
    
    /// Loading state for fetching single habitation by ID
    @Published var isFetchingSingleHabitation = false
    
    /// Error message specific to single habitation fetch operations
    @Published var fetchSingleHabitationError: String?
    
    // MARK: - Published Properties for Enhanced Models
    
    /// Array of enhanced habitation data with user details and pictures
    @Published var enhancedHabitations: [EnhancedHabitationData] = []
    
    /// Currently selected enhanced habitation for detail operations
    @Published var selectedEnhancedHabitation: EnhancedHabitationData?
    
    /// Loading state for fetching enhanced habitations with full details
    @Published var isFetchingEnhancedHabitations = false
    
    /// Loading state for fetching single enhanced habitation
    @Published var isFetchingEnhancedSingleHabitation = false
    
    // MARK: - Dependencies
    
    /// Shared network manager instance for all API communications
    private let networkManager = NetworkManager.shared
    private let homeCache = HabitationCacheRepository.shared
    
    // MARK: - CRUD Operations
    
    // MARK: - Update Operations
    
    /**
     * Updates an existing habitation with new property details.
     * 
     * Validates all input parameters, authenticates the request, and updates the habitation
     * on the backend. Updates local state upon successful completion.
     * 
     * @param habitationId Unique identifier of the habitation to update
     * @param name Updated name for the habitation property
     * @param description Updated description of the habitation
     * @param type Updated habitation type (room, apartment, etc.)
     * @param isReserved Updated reservation status
     * @param price Updated price per period
     */
    func updateHabitation(
        habitationId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false,
        price: Int
    ) {
        // Validate input parameters
        guard validateHabitationId(habitationId) else { return }
        guard validateHabitationName(name) else { return }
        guard validateHabitationDescription(description) else { return }
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare update operation
        prepareUpdateOperation()
        
        // Get current user ID for the update request
        let userId = getCurrentUserId()
        
        // Build update request
        let updateRequest = buildUpdateHabitationRequest(
            userId: userId,
            name: name,
            description: description,
            type: type,
            isReserved: isReserved,
            price: price
        )
        
        // Execute update request
        processUpdateHabitationRequest(
            habitationId: habitationId,
            request: updateRequest,
            token: token
        )
    }
    
    /**
     * Deletes an existing habitation from the system.
     * 
     * Validates the habitation ID, authenticates the request, and removes the habitation
     * from both local state and backend storage upon successful completion.
     * 
     * @param habitationId Unique identifier of the habitation to delete
     */
    func deleteHabitation(habitationId: String) {
        // Validate input parameters
        guard validateHabitationId(habitationId) else { return }
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare delete operation
        prepareDeleteOperation()
        
        // Execute delete request
        processDeleteHabitationRequest(habitationId: habitationId, token: token)
    }
    
    /**
     * Creates a new habitation property in the system.
     * 
     * Validates all input parameters, authenticates the request, and creates a new habitation
     * on the backend. Updates local state and triggers notifications upon successful completion.
     * 
     * @param profileUserId User ID of the habitation owner
     * @param name Name of the habitation property
     * @param description Detailed description of the habitation
     * @param type Type of habitation (room, apartment, etc.)
     * @param isReserved Initial reservation status (defaults to false)
     * @param price Price per period for the habitation
     */
    func createHabitation(
        profileUserId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false,
        price: Int
    ) {
        // Validate input parameters
        guard validateUserId(profileUserId) else { return }
        guard validateHabitationName(name) else { return }
        guard validateHabitationDescription(description) else { return }
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare creation operation
        prepareCreationOperation()
        
        // Build creation request
        let createRequest = buildCreateHabitationRequest(
            userId: profileUserId,
            name: name,
            description: description,
            type: type,
            isReserved: isReserved,
            price: price
        )
        
        // Execute creation request
        processCreateHabitationRequest(request: createRequest, token: token)
    }
    
    /**
     * Fetches all basic habitation data from the backend.
     * 
     * Retrieves all habitations without user details or pictures. Updates the local
     * habitations array with the fetched data and manages loading states.
     */
    func fetchAllHabitations() {
        // Validate authentication
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare fetch operation
        prepareFetchHabitationsOperation()
        
        // Build authentication headers
        let headers = buildAuthenticationHeaders(token: token)
        
        // Execute fetch request
        processFetchHabitationsRequest(headers: headers)
    }
    
    /**
     * Fetches a specific habitation by its unique identifier.
     * 
     * Retrieves detailed information for a single habitation and updates the
     * selectedHabitation property with the fetched data.
     * 
     * @param habitationId Unique identifier of the habitation to fetch
     */
    func fetchHabitationById(habitationId: String) {
        // Validate input parameters
        guard validateHabitationId(habitationId) else { return }
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare single fetch operation
        prepareFetchSingleHabitationOperation()
        
        // Execute single fetch request
        processFetchSingleHabitationRequest(habitationId: habitationId, token: token)
    }
    
    /**
     * Fetches all enhanced habitation data with user details and pictures.
     * 
     * Retrieves comprehensive habitation information including owner details and
     * associated pictures. Updates the enhancedHabitations array with fetched data.
     */
    func fetchAllEnhancedHabitations() {
        // Validate authentication
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare enhanced fetch operation
        prepareFetchEnhancedHabitationsOperation()
        // Prefill from cache for offline/instant UI
        let cached = homeCache.fetchAll()
        if !cached.isEmpty {
            enhancedHabitations = cached
        }
        
        // Execute enhanced fetch request
        processFetchEnhancedHabitationsRequest(token: token)
    }
    
    /**
     * Processes the enhanced habitations fetch network request.
     * @param token Authentication token for the request
     */
    private func processFetchEnhancedHabitationsRequest(token: String) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitations,
            headers: headers,
            responseType: GetEnhancedHabitationsResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchEnhancedHabitationsResponse(result)
            }
        }
    }
    
    /**
     * Fetches enhanced habitations for the currently authenticated user.
     * 
     * Retrieves the current user's profile and fetches their habitations with
     * enhanced data including user details and pictures.
     */
    func fetchEnhancedHabitationsForCurrentUser() {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.fetchEnhancedHabitationsByUserId(userId: userId)
        }
    }
    
    /**
     * Fetches enhanced habitations for a specific user by their ID.
     * 
     * Retrieves all habitations owned by the specified user with enhanced data
     * including user details and pictures.
     * 
     * @param userId Unique identifier of the user whose habitations to fetch
     */
    func fetchEnhancedHabitationsByUserId(userId: String) {
        // Validate input parameters
        guard validateUserId(userId) else { return }
        guard let token = validateAuthenticationToken() else { return }
        
        // Prepare enhanced fetch by user operation
        prepareFetchEnhancedHabitationsOperation()
        
        // Execute enhanced fetch by user request
        processFetchEnhancedHabitationsByUserRequest(userId: userId, token: token)
    }
    
    func fetchEnhancedHabitationById(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingEnhancedSingleHabitation = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitationById(habitationId: habitationId),
            headers: headers,
            responseType: GetEnhancedHabitationByIdResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingEnhancedSingleHabitation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetEnhancedHabitationById success: \(response.success)")
                    print("🔍 DEBUG - GetEnhancedHabitationById data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.selectedEnhancedHabitation = response.data
                        print("✅ Enhanced Habitation fetched successfully by ID")
                        
                        if let habitation = response.data {
                            print("📍 Selected Enhanced Habitation: \(habitation.name)")
                            print("   User: \(habitation.userFullName)")
                            if let user = habitation.user {
                                print("   Phone: \(user.phoneNumber)")
                            } else {
                                print("   City: Unknown, District: Unknown")
                            }
                            print("   Pictures: \(habitation.pictures?.count ?? 0)")
                        }
                    } else {
                        self?.showError(response.message ?? "Failed to fetch enhanced habitation")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch enhanced habitation by ID error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Original Filter Methods (UNCHANGED)
    
    func filterHabitationsByType(_ type: HabitationType) -> [HabitationData] {
        return habitations.filter { $0.type == type.rawValue }
    }
    
    func filterAvailableHabitations() -> [HabitationData] {
        return habitations.filter { !$0.isReserved }
    }
    
    func filterReservedHabitations() -> [HabitationData] {
        return habitations.filter { $0.isReserved }
    }
    
    // MARK: - Enhanced Filter Methods
    
    func filterEnhancedHabitationsByType(_ type: HabitationType) -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { $0.type == type.rawValue }
    }
    
    func filterEnhancedAvailableHabitations() -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { !$0.isReserved }
    }
    
    func filterEnhancedReservedHabitations() -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { $0.isReserved }
    }
    
    func filterEnhancedHabitationsByUser(userId: String) -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { $0.user?.id == userId }
    }
    
    func filterEnhancedHabitationsByCity(_ city: String) -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { habitation in
            // City filtering not available with current user data structure
            return false
        }
    }
    
    func filterEnhancedHabitationsByDistrict(_ district: String) -> [EnhancedHabitationData] {
        // District filtering not available with current user data structure
        return []
    }

// ...
    
    func searchEnhancedHabitations(query: String) -> [EnhancedHabitationData] {
        guard !query.isEmpty else { return enhancedHabitations }
        
        let lowercasedQuery = query.lowercased()
        return enhancedHabitations.filter { habitation in
            // Basic properties that don't depend on user
            let basicMatch = habitation.name.lowercased().contains(lowercasedQuery) ||
                           habitation.description.lowercased().contains(lowercasedQuery) ||
                           habitation.type.lowercased().contains(lowercasedQuery) ||
                           habitation.userFullName.lowercased().contains(lowercasedQuery)
            
            // User-dependent properties
            let userMatch = habitation.user?.fullName.lowercased().contains(lowercasedQuery) == true ||
                          habitation.user?.phoneNumber.contains(lowercasedQuery) == true
            
            return basicMatch || userMatch
        }
    }
    
    func getEnhancedHabitationsByLocation(city: String? = nil, district: String? = nil) -> [EnhancedHabitationData] {
        var filteredHabitations = enhancedHabitations
        
        // Location filtering not available with current user data structure
        // City and district fields are not included in the backend response
        
        return filteredHabitations
    }
    
    func getEnhancedHabitationsWithPictures() -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { ($0.pictures?.count ?? 0) > 0 }
    }
    
    func getEnhancedHabitationsWithoutPictures() -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { ($0.pictures?.count ?? 0) == 0 }
    }
    
    // MARK: - Computed Properties
    
    var habitationCount: Int {
        return habitations.count
    }
    
    var availableHabitationCount: Int {
        return filterAvailableHabitations().count
    }
    
    var reservedHabitationCount: Int {
        return filterReservedHabitations().count
    }
    
    var enhancedHabitationCount: Int {
        return enhancedHabitations.count
    }
    
    var enhancedAvailableHabitationCount: Int {
        return filterEnhancedAvailableHabitations().count
    }
    
    var enhancedReservedHabitationCount: Int {
        return filterEnhancedReservedHabitations().count
    }
    
    var uniqueCities: [String] {
        // City data not available in current user structure
        return []
    }
    
    func getAvailableDistricts() -> [String] {
        // District data not available in current user structure
        return []
    }
    
    var habitationTypes: [String] {
        let types = Set(enhancedHabitations.map { $0.type })
        return Array(types).sorted()
    }
    
    // MARK: - Helper Methods
    
    func showSuccess(message: String) {
        self.habitationCreationSuccess = true
        self.habitationCreationMessage = message
    }
    
    func getUserIdFromProfile(completion: @escaping (String?) -> Void) {
        guard let userId = AuthViewModel.shared.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            completion(nil)
            return
        }
        
        let profileViewModel = ProfileViewModel()
        
        func checkProfile() {
            if let profileId = profileViewModel.userProfile?.id {
                completion(profileId)
            } else if !profileViewModel.isLoading && profileViewModel.hasError {
                completion(nil)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    checkProfile()
                }
            }
        }
        
        profileViewModel.fetchUserProfile(userId: userId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkProfile()
        }
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
    
    private func handleHabitationCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showHabitationCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showHabitationCreationError(message)
                
            case .serverError(let message):
                showHabitationCreationError("Server error: \(message)")
                
            default:
                showHabitationCreationError(networkError.localizedDescription)
            }
        } else {
            showHabitationCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Habitation Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    func showHabitationCreationError(_ message: String) {
        habitationCreationMessage = message
        habitationCreationSuccess = false
        print("❌ Habitation Creation Error: \(message)")
    }
    
    private func clearHabitationCreationError() {
        habitationCreationMessage = nil
        habitationCreationSuccess = false
    }
    
    // MARK: - Utility Methods
    
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
    
    func clearHabitations() {
        habitations.removeAll()
        enhancedHabitations.removeAll()
        selectedHabitation = nil
        selectedEnhancedHabitation = nil
        clearError()
        clearHabitationCreationError()
    }
    
    func resetHabitationCreationState() {
        isCreatingHabitation = false
        habitationCreationSuccess = false
        habitationCreationMessage = nil
        createdHabitation = nil
    }
    
    func resetSelectedHabitation() {
        selectedHabitation = nil
        selectedEnhancedHabitation = nil
    }
    
    func refreshHabitations() {
        fetchAllHabitations()
        fetchAllEnhancedHabitations()
    }
    
    func refreshEnhancedHabitations() {
        fetchAllEnhancedHabitations()
    }
}

// MARK: - Extensions

extension HabitationViewModel {
    
    func createHabitationWithCurrentUser(
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false,
        price: Int
    ) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showHabitationCreationError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.createHabitation(
                profileUserId: userId,
                name: name,
                description: description,
                type: type,
                isReserved: isReserved,
                price: price
            )
        }
    }
    
    // MARK: - Notification Handling
    
    /// Triggers a notification when a new habitation is created
    func triggerHabitationCreatedNotification(habitationName: String) {
        print("🔔 Triggering notification for new habitation: \(habitationName)")
        
        // In a real implementation, this would be handled by the backend
        // The notification would be created on the server and then fetched by the client
        // This is just a placeholder to show where the notification would be triggered
        
        // Refresh notifications in the NotificationViewModel if it's active
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshNotifications"),
                object: nil
            )
        }
    }
    
    func getHabitationsForCurrentUser(completion: @escaping ([HabitationData]) -> Void) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId, let self = self else {
                completion([])
                return
            }
            
            let userHabitations = self.habitations.filter { $0.user == userId }
            completion(userHabitations)
        }
    }
    
    func getEnhancedHabitationsForCurrentUser(completion: @escaping ([EnhancedHabitationData]) -> Void) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId, let self = self else {
                completion([])
                return
            }
            
            let userHabitations = self.filterEnhancedHabitationsByUser(userId: userId)
            completion(userHabitations)
        }
    }
    
    // MARK: - Validation Methods
    
    /**
     * Validates habitation ID parameter.
     * @param habitationId The habitation ID to validate
     * @return True if valid, false otherwise
     */
    private func validateHabitationId(_ habitationId: String) -> Bool {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return false
        }
        return true
    }
    
    /**
     * Validates habitation name parameter.
     * @param name The habitation name to validate
     * @return True if valid, false otherwise
     */
    private func validateHabitationName(_ name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Habitation name is required")
            return false
        }
        return true
    }
    
    /**
     * Validates habitation description parameter.
     * @param description The habitation description to validate
     * @return True if valid, false otherwise
     */
    private func validateHabitationDescription(_ description: String) -> Bool {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Description is required")
            return false
        }
        return true
    }
    
    /**
     * Validates authentication token from UserDefaults.
     * @return Authentication token if valid, nil otherwise
     */
    private func validateAuthenticationToken() -> String? {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return nil
        }
        return token
    }
    
    // MARK: - State Management Methods
    
    /**
     * Prepares the ViewModel state for update operations.
     */
    private func prepareUpdateOperation() {
        isLoading = true
        clearError()
        print("🔍 DEBUG - Preparing habitation update operation")
    }
    
    /**
     * Prepares the ViewModel state for delete operations.
     */
    private func prepareDeleteOperation() {
        isLoading = true
        clearError()
        print("🔍 DEBUG - Preparing habitation delete operation")
    }
    
    /**
     * Gets the current user ID from available sources.
     * @return User ID string, empty if not found
     */
    private func getCurrentUserId() -> String {
        return AuthViewModel.shared.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") ?? ""
    }
    
    // MARK: - Request Building Methods
    
    /**
     * Builds update habitation request payload.
     */
    private func buildUpdateHabitationRequest(
        userId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool,
        price: Int
    ) -> CreateHabitationRequest {
        return CreateHabitationRequest(
            user: userId,
            name: name,
            description: description,
            type: type.rawValue,
            isReserved: isReserved,
            price: price
        )
    }
    
    /**
     * Builds authentication headers for API requests.
     * @param token Authentication token
     * @return Dictionary of headers
     */
    private func buildAuthenticationHeaders(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    // MARK: - Network Request Processing Methods
    
    /**
     * Processes update habitation network request.
     */
    private func processUpdateHabitationRequest(
        habitationId: String,
        request: CreateHabitationRequest,
        token: String
    ) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .updateHabitation(habitationId: habitationId),
            body: request,
            headers: headers,
            responseType: CreateHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpdateHabitationResponse(result, habitationId: habitationId)
            }
        }
    }
    
    /**
     * Processes delete habitation network request.
     */
    private func processDeleteHabitationRequest(habitationId: String, token: String) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .deleteHabitation(habitationId: habitationId),
            headers: headers,
            responseType: DeleteHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDeleteHabitationResponse(result, habitationId: habitationId)
            }
        }
    }
    
    // MARK: - Response Handling Methods
    
    /**
     * Handles update habitation API response.
     */
    private func handleUpdateHabitationResponse(
        _ result: Result<CreateHabitationResponse, Error>,
        habitationId: String
    ) {
        isLoading = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - UpdateHabitation success: \(response.success)")
            print("🔍 DEBUG - UpdateHabitation message: \(response.message)")
            
            if response.success {
                handleSuccessfulHabitationUpdate(response.data, habitationId: habitationId)
            } else {
                showError(response.message)
                print("❌ UpdateHabitation failed: \(response.message)")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Update habitation error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles delete habitation API response.
     */
    private func handleDeleteHabitationResponse(
        _ result: Result<DeleteHabitationResponse, Error>,
        habitationId: String
    ) {
        isLoading = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - DeleteHabitation success: \(response.success)")
            print("🔍 DEBUG - DeleteHabitation message: \(response.message)")
            
            if response.success {
                handleSuccessfulHabitationDeletion(habitationId: habitationId)
            } else {
                showError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Delete habitation error: \(error)")
            handleNetworkError(error)
        }
    }
    
    // MARK: - Success Handling Methods
    
    /**
     * Handles successful habitation update operations.
     */
    private func handleSuccessfulHabitationUpdate(_ updatedHabitation: HabitationData?, habitationId: String) {
        guard let updatedHabitation = updatedHabitation else { return }
        
        // Update the habitation in the local array
        if let index = habitations.firstIndex(where: { $0.id == habitationId }) {
            habitations[index] = updatedHabitation
        }
        
        // Update selected habitation if it matches
        if selectedHabitation?.id == habitationId {
            selectedHabitation = updatedHabitation
        }
        
        print("✅ Habitation updated successfully: \(updatedHabitation.name)")
    }
    
    /**
     * Handles successful habitation deletion operations.
     */
    private func handleSuccessfulHabitationDeletion(habitationId: String) {
        // Remove the habitation from the arrays
        habitations.removeAll { $0.id == habitationId }
        enhancedHabitations.removeAll { $0.id == habitationId }
        
        // Reset selected habitation if it's the one being deleted
        if selectedHabitation?.id == habitationId {
            selectedHabitation = nil
        }
        
        if selectedEnhancedHabitation?.id == habitationId {
            selectedEnhancedHabitation = nil
        }
        
        showSuccess(message: "Habitation deleted successfully")
        print("✅ Habitation deleted successfully")
    }
    
    // MARK: - Error Handling Methods
    
    /**
     * Validates user ID parameter.
     * @param userId The user ID to validate
     * @return True if valid, false otherwise
     */
    private func validateUserId(_ userId: String) -> Bool {
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showHabitationCreationError("User ID is required")
            return false
        }
        return true
    }
    
    /**
     * Prepares the ViewModel state for creation operations.
     */
    private func prepareCreationOperation() {
        isCreatingHabitation = true
        clearHabitationCreationError()
        print("🔍 DEBUG - Preparing habitation creation operation")
    }
    
    /**
     * Prepares the ViewModel state for fetching habitations.
     */
    private func prepareFetchHabitationsOperation() {
        isFetchingHabitations = true
        clearError()
        print("🔍 DEBUG - Preparing fetch habitations operation")
    }
    
    /**
     * Prepares the ViewModel state for fetching single habitation.
     */
    private func prepareFetchSingleHabitationOperation() {
        isFetchingSingleHabitation = true
        clearError()
        print("🔍 DEBUG - Preparing fetch single habitation operation")
    }
    
    /**
     * Prepares the ViewModel state for fetching enhanced habitations.
     */
    private func prepareFetchEnhancedHabitationsOperation() {
        isFetchingEnhancedHabitations = true
        clearError()
        print("🔍 DEBUG - Preparing fetch enhanced habitations operation")
    }
    
    /**
     * Builds create habitation request payload.
     */
    private func buildCreateHabitationRequest(
        userId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool,
        price: Int
    ) -> CreateHabitationRequest {
        return CreateHabitationRequest(
            user: userId,
            name: name,
            description: description,
            type: type.rawValue,
            isReserved: isReserved,
            price: price
        )
    }
    
    /**
     * Processes create habitation network request.
     */
    private func processCreateHabitationRequest(request: CreateHabitationRequest, token: String) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .createHabitation,
            body: request,
            headers: headers,
            responseType: CreateHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCreateHabitationResponse(result)
            }
        }
    }
    
    /**
     * Processes fetch habitations network request.
     */
    private func processFetchHabitationsRequest(headers: [String: String]) {
        networkManager.requestWithHeaders(
            endpoint: .getHabitations,
            headers: headers,
            responseType: GetHabitationsResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchHabitationsResponse(result)
            }
        }
    }
    
    /**
     * Processes fetch single habitation network request.
     */
    private func processFetchSingleHabitationRequest(habitationId: String, token: String) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitationById(habitationId: habitationId),
            headers: headers,
            responseType: GetHabitationByIdResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchSingleHabitationResponse(result)
            }
        }
    }
    
    /**
     * Processes fetch enhanced habitations by user network request.
     */
    private func processFetchEnhancedHabitationsByUserRequest(userId: String, token: String) {
        let headers = buildAuthenticationHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitationsByUserId(userId: userId),
            headers: headers,
            responseType: GetEnhancedHabitationsResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchEnhancedHabitationsByUserResponse(result)
            }
        }
    }
    
    /**
     * Handles create habitation API response.
     */
    private func handleCreateHabitationResponse(_ result: Result<CreateHabitationResponse, Error>) {
        isCreatingHabitation = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - CreateHabitation success: \(response.success)")
            print("🔍 DEBUG - CreateHabitation message: \(response.message)")
            
            if response.success {
                handleSuccessfulHabitationCreation(response)
            } else {
                showHabitationCreationError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Create habitation error: \(error)")
            handleHabitationCreationError(error)
        }
    }
    
    /**
     * Handles fetch habitations API response.
     */
    private func handleFetchHabitationsResponse(_ result: Result<GetHabitationsResponse, Error>) {
        isFetchingHabitations = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetHabitations success: \(response.success)")
            print("🔍 DEBUG - GetHabitations data count: \(response.data?.count ?? 0)")
            
            if response.success {
                habitations = response.data ?? []
                print("✅ Habitations fetched successfully: \(habitations.count) items")
            } else {
                showError(response.message ?? "Failed to fetch habitations")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch habitations error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles fetch single habitation API response.
     */
    private func handleFetchSingleHabitationResponse(_ result: Result<GetHabitationByIdResponse, Error>) {
        isFetchingSingleHabitation = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetHabitationById success: \(response.success)")
            
            if response.success {
                selectedHabitation = response.data
                print("✅ Habitation fetched successfully by ID")
            } else {
                showError(response.message ?? "Failed to fetch habitation")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch habitation by ID error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles fetch enhanced habitations API response.
     */
    private func handleFetchEnhancedHabitationsResponse(_ result: Result<GetEnhancedHabitationsResponse, Error>) {
        isFetchingEnhancedHabitations = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetEnhancedHabitations success: \(response.success)")
            
            if response.success {
                enhancedHabitations = response.data ?? []
                // Save to cache for offline use
                homeCache.saveAll(enhancedHabitations)
                print("✅ Enhanced Habitations fetched successfully: \(enhancedHabitations.count) items")
                // Index in Core Spotlight for system-wide search
                SpotlightIndexManager.shared.indexHabitations(enhancedHabitations)
            } else {
                showError(response.message ?? "Failed to fetch enhanced habitations")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch enhanced habitations error: \(error)")
            // Fallback to cache on error
            let cached = homeCache.fetchAll()
            if !cached.isEmpty {
                enhancedHabitations = cached
                clearError()
            } else {
                handleNetworkError(error)
            }
        }
    }
    
    /**
     * Handles fetch enhanced habitations by user API response.
     */
    private func handleFetchEnhancedHabitationsByUserResponse(_ result: Result<GetEnhancedHabitationsResponse, Error>) {
        isFetchingEnhancedHabitations = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetEnhancedHabitationsByUserId success: \(response.success)")
            
            if response.success {
                enhancedHabitations = response.data ?? []
                homeCache.saveAll(enhancedHabitations)
                print("✅ Enhanced Habitations by user fetched successfully: \(enhancedHabitations.count) items")
                // Index in Core Spotlight for system-wide search
                SpotlightIndexManager.shared.indexHabitations(enhancedHabitations)
            } else {
                showError(response.message ?? "Failed to fetch user habitations")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch enhanced habitations by user error: \(error)")
            let cached = homeCache.fetchAll()
            if !cached.isEmpty {
                enhancedHabitations = cached
                clearError()
            } else {
                handleNetworkError(error)
            }
        }
    }
    
    /**
     * Handles successful habitation creation operations.
     */
    private func handleSuccessfulHabitationCreation(_ response: CreateHabitationResponse) {
        habitationCreationSuccess = true
        habitationCreationMessage = response.message
        createdHabitation = response.data
        print("✅ Habitation created successfully")
        
        if let newHabitation = response.data {
            habitations.append(newHabitation)
            triggerHabitationCreatedNotification(habitationName: newHabitation.name)
        }
        
        // Refresh enhanced habitations after creating new one
        fetchAllEnhancedHabitations()
    }
    
}
