import Foundation

/**
 * HabitationFeatureViewModel - Professional MVVM implementation for habitation feature management.
 * 
 * This ViewModel manages the complete lifecycle of habitation features including creation,
 * retrieval, validation, and utility calculations. It provides a comprehensive interface
 * for managing physical characteristics and amenities of habitation properties.
 * 
 * Key Features:
 * - Feature creation with comprehensive validation
 * - Multiple response format handling (single/array/direct)
 * - Real-time state management with reactive properties
 * - Professional error handling with user-friendly messages
 * - Utility calculations for furniture and amenities
 * - Integration with HabitationViewModel for seamless workflow
 * 
 * Architecture: MVVM-compliant with reactive @Published properties
 * Thread Safety: @MainActor ensures all UI updates occur on main thread
 * Dependencies: NetworkManager for API communication
 */
@MainActor
class HabitationFeatureViewModel: ObservableObject {
    
    /**
     * Published properties for reactive UI updates and state management.
     */
    
    /// Collection of all loaded habitation features
    @Published var features: [HabitationFeatureData] = []
    
    /// Currently selected feature for detailed operations
    @Published var selectedFeature: HabitationFeatureData?
    
    /// General loading state for UI feedback
    @Published var isLoading = false
    
    /// General error message for user display
    @Published var errorMessage: String?
    
    /// Flag indicating if there's an active error state
    @Published var hasError = false
    
    /**
     * Feature creation specific state properties.
     */
    
    /// Loading state specifically for feature creation operations
    @Published var isCreatingFeature = false
    
    /// Success flag for feature creation operations
    @Published var featureCreationSuccess = false
    
    /// Success/error message for feature creation operations
    @Published var featureCreationMessage: String?
    
    /// Reference to the newly created feature data
    @Published var createdFeature: HabitationFeatureData?
    
    /**
     * Feature fetching specific state properties.
     */
    
    /// Loading state specifically for feature fetching operations
    @Published var isFetchingFeature = false
    
    /// Error message specifically for feature fetching operations
    @Published var fetchFeatureError: String?
    
    /**
     * Dependencies and services.
     */
    
    /// Shared network manager instance for API communication
    private let networkManager = NetworkManager.shared
    
    /**
     * Core feature management operations.
     */
    
    /**
     * Creates a new habitation feature with comprehensive validation and error handling.
     * 
     * This method validates all input parameters, constructs the appropriate request,
     * and handles the complete creation workflow including success/error states.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param sqft Square footage of the habitation (must be > 0)
     * @param familyType Type of family accommodation structure
     * @param windowsCount Number of windows (must be >= 0)
     * @param smallBedCount Number of small beds (must be >= 0)
     * @param largeBedCount Number of large beds (must be >= 0)
     * @param chairCount Number of chairs (must be >= 0)
     * @param tableCount Number of tables (must be >= 0)
     * @param isElectricityAvailable Whether electricity is available
     * @param isWachineMachineAvailable Whether washing machine is available
     * @param isWaterAvailable Whether water supply is available
     */
    func createHabitationFeature(
        habitationId: String,
        sqft: Int,
        familyType: FamilyType,
        windowsCount: Int,
        smallBedCount: Int,
        largeBedCount: Int,
        chairCount: Int,
        tableCount: Int,
        isElectricityAvailable: Bool,
        isWachineMachineAvailable: Bool,
        isWaterAvailable: Bool
    ) {
        // Validate input parameters
        guard validateHabitationId(habitationId) else { return }
        guard validateFeatureParameters(sqft: sqft, windowsCount: windowsCount, 
                                       smallBedCount: smallBedCount, largeBedCount: largeBedCount,
                                       chairCount: chairCount, tableCount: tableCount) else { return }
        guard let token = validateAuthToken() else { return }
        
        // Prepare request state and data
        prepareFeatureCreationRequest()
        let createFeatureRequest = buildFeatureCreationRequest(
            habitationId: habitationId, sqft: sqft, familyType: familyType,
            windowsCount: windowsCount, smallBedCount: smallBedCount, largeBedCount: largeBedCount,
            chairCount: chairCount, tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWachineMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
        let headers = buildAuthHeaders(token: token)
        
        // Execute network request
        executeFeatureCreationRequest(habitationId: habitationId, 
                                    request: createFeatureRequest, 
                                    headers: headers)
    }
    
    /**
     * Feature retrieval operations with multiple response format support.
     */
    
    /**
     * Fetches habitation features by habitation ID with automatic format detection.
     * 
     * This method attempts to fetch features using the standard response format first,
     * then falls back to direct data format if needed. Handles various API response
     * structures gracefully.
     * 
     * @param habitationId The unique identifier of the habitation
     */
    func fetchFeaturesByHabitationId(habitationId: String) {
        // Validate parameters and prepare request
        guard validateHabitationId(habitationId) else { return }
        guard let token = validateAuthToken() else { return }
        
        prepareFetchRequest()
        let headers = buildAuthHeaders(token: token)
        
        // Attempt standard format fetch with fallback to direct format
        executeFetchRequest(habitationId: habitationId, headers: headers)
    }
    
    /**
     * Fetches features using direct data format as fallback.
     * 
     * This private method handles the alternative API response format where
     * feature data is returned directly without standard wrapper structure.
     * 
     * @param habitationId The habitation identifier
     * @param headers Authentication headers for the request
     */
    private func fetchFeaturesByHabitationIdDirectFormat(habitationId: String, headers: [String: String]) {
        isFetchingFeature = true
        
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: DirectHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDirectFormatFetchResponse(result)
            }
        }
    }
    
    /**
     * Fetches all features for a habitation when API returns array format.
     * 
     * This method handles cases where the API returns multiple features
     * as an array rather than a single feature object.
     * 
     * @param habitationId The unique identifier of the habitation
     */
    func fetchAllFeaturesByHabitationId(habitationId: String) {
        // Validate parameters and prepare request
        guard validateHabitationId(habitationId) else { return }
        guard let token = validateAuthToken() else { return }
        
        prepareFetchRequest()
        let headers = buildAuthHeaders(token: token)
        
        // Execute array format fetch request
        executeArrayFetchRequest(habitationId: habitationId, headers: headers)
    }
    
    /**
     * Generic fetch method that handles both single and array response formats.
     * 
     * This convenience method automatically selects the appropriate fetch strategy
     * based on the expected response format.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param expectArray Whether to expect array format response (default: false)
     */
    func fetchHabitationFeatures(habitationId: String, expectArray: Bool = false) {
        if expectArray {
            fetchAllFeaturesByHabitationId(habitationId: habitationId)
        } else {
            fetchFeaturesByHabitationId(habitationId: habitationId)
        }
    }
    
    /**
     * Creates features for an existing habitation object.
     * 
     * This convenience method extracts the habitation ID from a HabitationData
     * object and creates features using the standard creation workflow.
     * 
     * @param habitation The habitation object to create features for
     * @param sqft Square footage of the habitation
     * @param familyType Type of family accommodation
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param chairCount Number of chairs
     * @param tableCount Number of tables
     * @param isElectricityAvailable Electricity availability
     * @param isWachineMachineAvailable Washing machine availability
     * @param isWaterAvailable Water supply availability
     */
    func createFeatureForHabitation(
        habitation: HabitationData,
        sqft: Int,
        familyType: FamilyType,
        windowsCount: Int,
        smallBedCount: Int,
        largeBedCount: Int,
        chairCount: Int,
        tableCount: Int,
        isElectricityAvailable: Bool,
        isWachineMachineAvailable: Bool,
        isWaterAvailable: Bool
    ) {
        createHabitationFeature(
            habitationId: habitation.id,
            sqft: sqft,
            familyType: familyType,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: chairCount,
            tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWachineMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
    }
    
    /**
     * Private helper methods for request preparation and execution.
     */
    
    /**
     * Validates habitation ID parameter.
     * 
     * @param habitationId The habitation ID to validate
     * @return True if valid, false otherwise (shows error)
     */
    private func validateHabitationId(_ habitationId: String) -> Bool {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return false
        }
        return true
    }
    
    /**
     * Validates authentication token from UserDefaults.
     * 
     * @return Valid token string or nil if not found (shows error)
     */
    private func validateAuthToken() -> String? {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return nil
        }
        return token
    }
    
    /**
     * Validates feature creation parameters.
     * 
     * @param sqft Square footage value
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param chairCount Number of chairs
     * @param tableCount Number of tables
     * @return True if all parameters are valid, false otherwise
     */
    private func validateFeatureParameters(sqft: Int, windowsCount: Int, smallBedCount: Int, 
                                         largeBedCount: Int, chairCount: Int, tableCount: Int) -> Bool {
        guard sqft > 0 else {
            showFeatureCreationError("Square footage must be greater than 0")
            return false
        }
        
        guard windowsCount >= 0, smallBedCount >= 0, largeBedCount >= 0,
              chairCount >= 0, tableCount >= 0 else {
            showFeatureCreationError("Count values must be non-negative")
            return false
        }
        
        return true
    }
    
    /**
     * Prepares the UI state for feature creation request.
     */
    private func prepareFeatureCreationRequest() {
        isCreatingFeature = true
        clearFeatureCreationError()
    }
    
    /**
     * Prepares the UI state for feature fetch request.
     */
    private func prepareFetchRequest() {
        isFetchingFeature = true
        clearError()
    }
    
    /**
     * Builds authentication headers for API requests.
     * 
     * @param token The authentication token
     * @return Dictionary of headers
     */
    private func buildAuthHeaders(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    /**
     * Builds feature creation request object.
     * 
     * @param habitationId The habitation identifier
     * @param sqft Square footage
     * @param familyType Family accommodation type
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param chairCount Number of chairs
     * @param tableCount Number of tables
     * @param isElectricityAvailable Electricity availability
     * @param isWachineMachineAvailable Washing machine availability
     * @param isWaterAvailable Water availability
     * @return Configured request object
     */
    private func buildFeatureCreationRequest(
        habitationId: String, sqft: Int, familyType: FamilyType,
        windowsCount: Int, smallBedCount: Int, largeBedCount: Int,
        chairCount: Int, tableCount: Int,
        isElectricityAvailable: Bool, isWachineMachineAvailable: Bool, isWaterAvailable: Bool
    ) -> CreateHabitationFeatureRequest {
        return CreateHabitationFeatureRequest(
            habitation: habitationId,
            sqft: sqft,
            familyType: familyType.rawValue,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: chairCount,
            tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWachineMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
    }
    
    /**
     * Executes the feature creation network request.
     * 
     * @param habitationId The habitation identifier
     * @param request The feature creation request
     * @param headers Authentication headers
     */
    private func executeFeatureCreationRequest(habitationId: String, 
                                             request: CreateHabitationFeatureRequest, 
                                             headers: [String: String]) {
        networkManager.requestWithHeaders(
            endpoint: .createHabitationFeature(habitationId: habitationId),
            body: request,
            headers: headers,
            responseType: CreateHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFeatureCreationResponse(result)
            }
        }
    }
    
    /**
     * Executes the standard format fetch request.
     * 
     * @param habitationId The habitation identifier
     * @param headers Authentication headers
     */
    private func executeFetchRequest(habitationId: String, headers: [String: String]) {
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: GetHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleStandardFetchResponse(result, habitationId: habitationId, headers: headers)
            }
        }
    }
    
    /**
     * Executes the array format fetch request.
     * 
     * @param habitationId The habitation identifier
     * @param headers Authentication headers
     */
    private func executeArrayFetchRequest(habitationId: String, headers: [String: String]) {
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: HabitationFeaturesArrayResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleArrayFetchResponse(result)
            }
        }
    }
    
    /**
     * Response handling methods for different request types.
     */
    
    /**
     * Handles feature creation response.
     * 
     * @param result The network result containing response or error
     */
    private func handleFeatureCreationResponse(_ result: Result<CreateHabitationFeatureResponse, Error>) {
        isCreatingFeature = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - CreateHabitationFeature success: \(response.success)")
            print("🔍 DEBUG - CreateHabitationFeature message: \(response.message)")
            print("🔍 DEBUG - CreateHabitationFeature data: \(String(describing: response.data))")
            
            if response.success {
                featureCreationSuccess = true
                featureCreationMessage = response.message
                createdFeature = response.data
                print("✅ Habitation feature created successfully")
                
                // Add the new feature to the list
                if let newFeature = response.data {
                    features.append(newFeature)
                }
            } else {
                showFeatureCreationError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Create habitation feature error: \(error)")
            handleFeatureCreationError(error)
        }
    }
    
    /**
     * Handles standard format fetch response.
     * 
     * @param result The network result
     * @param habitationId The habitation identifier for fallback
     * @param headers Authentication headers for fallback
     */
    private func handleStandardFetchResponse(_ result: Result<GetHabitationFeatureResponse, Error>, 
                                           habitationId: String, headers: [String: String]) {
        isFetchingFeature = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetFeaturesByHabitationId success: \(response.success)")
            print("🔍 DEBUG - GetFeaturesByHabitationId data: \(String(describing: response.data))")
            
            if response.success {
                selectedFeature = response.data
                print("✅ Habitation features fetched successfully")
            } else {
                showError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Standard format failed, trying direct data format")
            // If standard format fails, try direct data format
            fetchFeaturesByHabitationIdDirectFormat(habitationId: habitationId, headers: headers)
        }
    }
    
    /**
     * Handles direct format fetch response.
     * 
     * @param result The network result containing direct response
     */
    private func handleDirectFormatFetchResponse(_ result: Result<DirectHabitationFeatureResponse, Error>) {
        isFetchingFeature = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Direct format GetFeaturesByHabitationId success: \(response.success)")
            print("🔍 DEBUG - Direct format GetFeaturesByHabitationId data: \(response.data)")
            
            if response.success {
                selectedFeature = response.data
                
                // Update the features array if this feature isn't already in it
                if let index = features.firstIndex(where: { $0.id == response.data.id }) {
                    features[index] = response.data
                } else {
                    features.append(response.data)
                }
                
                print("✅ Habitation features fetched successfully (direct format)")
            } else {
                showError("Failed to fetch features")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Direct format fetch habitation features error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles array format fetch response.
     * 
     * @param result The network result containing array response
     */
    private func handleArrayFetchResponse(_ result: Result<HabitationFeaturesArrayResponse, Error>) {
        isFetchingFeature = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - GetAllFeaturesByHabitationId success: \(response.success)")
            print("🔍 DEBUG - GetAllFeaturesByHabitationId data count: \(response.data.count)")
            
            if response.success {
                features = response.data
                
                // Set the first feature as selected if available
                if let firstFeature = response.data.first {
                    selectedFeature = firstFeature
                }
                
                print("✅ All habitation features fetched successfully")
            } else {
                showError(response.message ?? "Failed to fetch features")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Fetch all habitation features error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Utility methods for feature analysis and display formatting.
     */
    /**
     * Retrieves feature data for a specific habitation.
     * 
     * @param habitationId The habitation identifier to search for
     * @return Feature data if found, nil otherwise
     */
    func getFeatureForHabitation(habitationId: String) -> HabitationFeatureData? {
        return features.first { $0.habitation == habitationId }
    }
    
    /**
     * Calculates total bedroom count from feature data.
     * 
     * @param feature The feature data to analyze
     * @return Total number of bedrooms (small + large)
     */
    func getTotalBedrooms(from feature: HabitationFeatureData) -> Int {
        return feature.smallBedCount + feature.largeBedCount
    }
    
    /**
     * Calculates total furniture count from feature data.
     * 
     * @param feature The feature data to analyze
     * @return Total number of furniture pieces (chairs + tables)
     */
    func getTotalFurniture(from feature: HabitationFeatureData) -> Int {
        return feature.chairCount + feature.tableCount
    }
    
    /**
     * Generates list of available utilities from feature data.
     * 
     * @param feature The feature data to analyze
     * @return Array of available utility names
     */
    func getAvailableUtilities(from feature: HabitationFeatureData) -> [String] {
        var utilities: [String] = []
        
        if feature.isElectricityAvailable {
            utilities.append("Electricity")
        }
        if feature.isWachineMachineAvailable {
            utilities.append("Washing Machine")
        }
        if feature.isWaterAvailable {
            utilities.append("Water")
        }
        
        return utilities
    }
    
    /**
     * Calculates utility availability score for comparison.
     * 
     * @param feature The feature data to analyze
     * @return Score from 0-3 based on available utilities
     */
    func getUtilityAvailabilityScore(from feature: HabitationFeatureData) -> Int {
        var score = 0
        if feature.isElectricityAvailable { score += 1 }
        if feature.isWachineMachineAvailable { score += 1 }
        if feature.isWaterAvailable { score += 1 }
        return score
    }
    
    /**
     * Formats square footage for display.
     * 
     * @param sqft The square footage value
     * @return Formatted string with units
     */
    func formatSquareFootage(_ sqft: Int) -> String {
        return "\(sqft) sq ft"
    }
    
    /**
     * Generates comprehensive feature summary for display.
     * 
     * @param feature The feature data to summarize
     * @return Formatted summary string
     */
    func getFeatureSummary(from feature: HabitationFeatureData) -> String {
        let bedrooms = getTotalBedrooms(from: feature)
        let utilities = getAvailableUtilities(from: feature)
        
        return "\(formatSquareFootage(feature.sqft)) • \(bedrooms) bedroom(s) • \(feature.familyType) • \(utilities.count) utilities"
    }
    
    /**
     * Validation and suggestion methods for feature data integrity.
     */
    
    /**
     * Validates feature data parameters for creation or update operations.
     * 
     * Performs comprehensive validation of all numeric parameters to ensure
     * they meet business rules and constraints.
     * 
     * @param sqft Square footage value
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param chairCount Number of chairs
     * @param tableCount Number of tables
     * @return Tuple containing validation result and error message if invalid
     */
    func validateFeatureData(
        sqft: Int,
        windowsCount: Int,
        smallBedCount: Int,
        largeBedCount: Int,
        chairCount: Int,
        tableCount: Int
    ) -> (isValid: Bool, errorMessage: String?) {
        if sqft <= 0 {
            return (false, "Square footage must be greater than 0")
        }
        
        if windowsCount < 0 {
            return (false, "Windows count cannot be negative")
        }
        
        if smallBedCount < 0 {
            return (false, "Small bed count cannot be negative")
        }
        
        if largeBedCount < 0 {
            return (false, "Large bed count cannot be negative")
        }
        
        if chairCount < 0 {
            return (false, "Chair count cannot be negative")
        }
        
        if tableCount < 0 {
            return (false, "Table count cannot be negative")
        }
        
        if smallBedCount == 0 && largeBedCount == 0 {
            return (false, "At least one bedroom is required")
        }
        
        return (true, nil)
    }
    
    /**
     * Suggests minimum furniture requirements based on space and bedroom count.
     * 
     * Calculates appropriate furniture quantities using base requirements
     * and square footage multipliers for optimal space utilization.
     * 
     * @param sqft Total square footage of the habitation
     * @param bedrooms Number of bedrooms in the habitation
     * @return Tuple containing suggested chair and table counts
     */
    func suggestMinimumFurniture(sqft: Int, bedrooms: Int) -> (chairs: Int, tables: Int) {
        let baseChairs = max(2, bedrooms * 2)
        let baseTables = max(1, bedrooms)
        
        // Adjust based on square footage
        let sqftMultiplier = sqft / 500 // Every 500 sqft adds more furniture
        let additionalChairs = sqftMultiplier * 2
        let additionalTables = sqftMultiplier
        
        return (baseChairs + additionalChairs, baseTables + additionalTables)
    }
    
    /**
     * Error handling and state management methods.
     */
    
    /**
     * Handles network errors for general operations with appropriate user messaging.
     * 
     * Processes different types of network errors and provides user-friendly
     * error messages while handling authentication token cleanup when necessary.
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
     * Handles network errors specifically for feature creation operations.
     * 
     * Similar to general error handling but targets feature creation specific
     * error states and messaging.
     * 
     * @param error The network error to handle
     */
    private func handleFeatureCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showFeatureCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showFeatureCreationError(message)
                
            case .serverError(let message):
                showFeatureCreationError("Server error: \(message)")
                
            default:
                showFeatureCreationError(networkError.localizedDescription)
            }
        } else {
            showFeatureCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Displays general error message and updates error state.
     * 
     * Sets error flags and messages for UI display and debugging.
     * 
     * @param message The error message to display
     */
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        fetchFeatureError = message
        print("❌ Habitation Feature Error: \(message)")
    }
    
    /**
     * Clears general error state and messages.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
        fetchFeatureError = nil
    }
    
    /**
     * Displays feature creation specific error message.
     * 
     * @param message The error message to display
     */
    func showFeatureCreationError(_ message: String) {
        featureCreationMessage = message
        featureCreationSuccess = false
        print("❌ Feature Creation Error: \(message)")
    }
    
    /**
     * Clears feature creation error state and messages.
     */
    private func clearFeatureCreationError() {
        featureCreationMessage = nil
        featureCreationSuccess = false
    }
    
    /**
     * Computed properties for feature analysis and UI presentation.
     */
    
    /**
     * Total number of loaded features.
     */
    var featureCount: Int {
        return features.count
    }
    
    /**
     * Flag indicating if a feature is currently selected.
     */
    var hasSelectedFeature: Bool {
        return selectedFeature != nil
    }
    
    /**
     * Average square footage across all loaded features.
     */
    var averageSquareFootage: Int {
        guard !features.isEmpty else { return 0 }
        let total = features.reduce(0) { $0 + $1.sqft }
        return total / features.count
    }
    
    /**
     * Total bedroom count across all loaded features.
     */
    var totalBedrooms: Int {
        return features.reduce(0) { result, feature in
            result + getTotalBedrooms(from: feature)
        }
    }
    
    /**
     * Date formatting utilities.
     */
    
    /**
     * Formats ISO8601 date strings for user display.
     * 
     * @param dateString The ISO8601 formatted date string
     * @return Human-readable date and time string
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
    
    /**
     * Data management and state reset methods.
     */
    
    /**
     * Clears all feature data and resets error states.
     * Used for logout operations and complete data cleanup.
     */
    func clearFeatures() {
        features.removeAll()
        selectedFeature = nil
        clearError()
        clearFeatureCreationError()
    }
    
    /**
     * Resets feature creation state to initial values.
     * Clears creation flags, messages, and references for new operations.
     */
    func resetFeatureCreationState() {
        isCreatingFeature = false
        featureCreationSuccess = false
        featureCreationMessage = nil
        createdFeature = nil
    }
    
    /**
     * Clears the currently selected feature.
     */
    func resetSelectedFeature() {
        selectedFeature = nil
    }
}

/**
 * Extension providing integration methods with HabitationViewModel.
 * 
 * These methods facilitate seamless workflow between habitation creation
 * and feature management operations.
 */
extension HabitationFeatureViewModel {
    
    /**
     * Creates features using a newly created habitation from HabitationViewModel.
     * 
     * This convenience method extracts the created habitation and initiates
     * feature creation with the provided parameters.
     * 
     * @param habitationViewModel The habitation view model containing created habitation
     * @param sqft Square footage of the habitation
     * @param familyType Type of family accommodation
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param chairCount Number of chairs
     * @param tableCount Number of tables
     * @param isElectricityAvailable Electricity availability
     * @param isWachineMachineAvailable Washing machine availability
     * @param isWaterAvailable Water supply availability
     */
    func createFeatureFromHabitationViewModel(
        habitationViewModel: HabitationViewModel,
        sqft: Int,
        familyType: FamilyType,
        windowsCount: Int,
        smallBedCount: Int,
        largeBedCount: Int,
        chairCount: Int,
        tableCount: Int,
        isElectricityAvailable: Bool,
        isWachineMachineAvailable: Bool,
        isWaterAvailable: Bool
    ) {
        guard let createdHabitation = habitationViewModel.createdHabitation else {
            showFeatureCreationError("No habitation found. Please create a habitation first.")
            return
        }
        
        createFeatureForHabitation(
            habitation: createdHabitation,
            sqft: sqft,
            familyType: familyType,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: chairCount,
            tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWachineMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
    }
    
    /**
     * Fetches features for the currently selected habitation.
     * 
     * @param habitationViewModel The habitation view model with selected habitation
     */
    func fetchFeaturesForSelectedHabitation(habitationViewModel: HabitationViewModel) {
        guard let selectedHabitation = habitationViewModel.selectedHabitation else {
            showError("No habitation selected")
            return
        }
        
        fetchFeaturesByHabitationId(habitationId: selectedHabitation.id)
    }
    
    /**
     * Creates features with automatically suggested furniture quantities.
     * 
     * This method calculates appropriate furniture counts based on space size
     * and bedroom count, then creates features with the suggested values.
     * 
     * @param habitationViewModel The habitation view model
     * @param sqft Square footage of the habitation
     * @param familyType Type of family accommodation
     * @param windowsCount Number of windows
     * @param smallBedCount Number of small beds
     * @param largeBedCount Number of large beds
     * @param isElectricityAvailable Electricity availability
     * @param isWachineMachineAvailable Washing machine availability
     * @param isWaterAvailable Water supply availability
     */
    func createFeatureWithSuggestedFurniture(
        habitationViewModel: HabitationViewModel,
        sqft: Int,
        familyType: FamilyType,
        windowsCount: Int,
        smallBedCount: Int,
        largeBedCount: Int,
        isElectricityAvailable: Bool,
        isWachineMachineAvailable: Bool,
        isWaterAvailable: Bool
    ) {
        let totalBedrooms = smallBedCount + largeBedCount
        let suggestedFurniture = suggestMinimumFurniture(sqft: sqft, bedrooms: totalBedrooms)
        
        createFeatureFromHabitationViewModel(
            habitationViewModel: habitationViewModel,
            sqft: sqft,
            familyType: familyType,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: suggestedFurniture.chairs,
            tableCount: suggestedFurniture.tables,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWachineMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
    }
}
