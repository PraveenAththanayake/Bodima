import Foundation

/**
 * ViewModel for managing habitation location operations in the Bodima application.
 * Handles location creation, retrieval, validation, and geographical operations.
 * 
 * This ViewModel provides:
 * - Location creation with comprehensive validation
 * - Location retrieval with intelligent caching
 * - Geographical calculations and coordinate formatting
 * - Address formatting and validation
 * - Integration with NetworkManager for API communication
 * - Comprehensive error handling and user feedback
 */

@MainActor
class HabitationLocationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of all location data loaded in the application
    @Published var locations: [LocationData] = []
    
    /// Currently selected location for display or operations
    @Published var selectedLocation: LocationData?
    
    /// General loading state indicator
    @Published var isLoading = false
    
    /// General error message for display
    @Published var errorMessage: String?
    
    /// Boolean flag indicating if there's an active error
    @Published var hasError = false
    
    /// Loading state specifically for location creation operations
    @Published var isCreatingLocation = false
    
    /// Success state for location creation operations
    @Published var locationCreationSuccess = false
    
    /// Message related to location creation operations
    @Published var locationCreationMessage: String?
    
    /// The most recently created location data
    @Published var createdLocation: LocationData?
    
    /// Loading state specifically for location fetching operations
    @Published var isFetchingLocation = false
    
    /// Error message specifically for location fetching operations
    @Published var fetchLocationError: String?
    
    /// Cache for storing location data by habitation ID for performance optimization
    @Published var locationCache: [String: LocationData] = [:]
    
    // MARK: - Private Properties
    
    /// Shared network manager instance for API communication
    private let networkManager = NetworkManager.shared
    
    // MARK: - Public Methods
    
    /**
     * Fetches location data for a specific habitation with intelligent caching.
     * Checks cache first for performance, then makes API call if needed.
     * 
     * @param habitationId The unique identifier of the habitation
     * 
     * @throws LocationError.invalidHabitationId if habitationId is empty
     * @throws NetworkError.unauthorized if authentication token is missing
     */
    func fetchLocationByHabitationId(habitationId: String) {
        guard validateHabitationId(habitationId) else {
            showError("Habitation ID is required")
            return
        }
        
        // Check cache first for performance optimization
        if let cachedLocation = locationCache[habitationId] {
            print("📍 Using cached location for habitation: \(habitationId)")
            selectedLocation = cachedLocation
            return
        }
        
        guard let token = validateAuthenticationToken() else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        prepareLocationFetchRequest()
        
        let headers = buildAuthenticationHeaders(token: token)
        
        processLocationFetchRequest(
            habitationId: habitationId,
            headers: headers
        )
    }
    
    /**
     * Creates a new location record for a habitation with comprehensive validation.
     * Validates all input parameters, authenticates the request, and handles the response.
     * 
     * @param habitationId The unique identifier of the habitation
     * @param addressNo The address number or building number
     * @param addressLine01 The primary address line
     * @param addressLine02 The secondary address line
     * @param city The city name
     * @param district The district or region name
     * @param latitude The latitude coordinate
     * @param longitude The longitude coordinate
     * @param nearestHabitationLatitude The latitude of the nearest habitation
     * @param nearestHabitationLongitude The longitude of the nearest habitation
     * 
     * @throws LocationError.missingAddress if required address fields are empty
     * @throws LocationError.invalidCoordinates if coordinates are out of valid range
     * @throws NetworkError.unauthorized if authentication token is missing
     */
    func createLocation(
        habitationId: String,
        addressNo: String,
        addressLine01: String,
        addressLine02: String,
        city: String,
        district: String,
        latitude: Double,
        longitude: Double,
        nearestHabitationLatitude: Double,
        nearestHabitationLongitude: Double
    ) {
        print("🔍 DEBUG - Creating location for habitation: \(habitationId)")
        
        let validation = validateLocationData(
            addressNo: addressNo,
            addressLine01: addressLine01,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude
        )
        
        guard validation.isValid else {
            showLocationCreationError(validation.errorMessage ?? "Invalid location data")
            return
        }
        
        guard let token = validateAuthenticationToken() else {
            showLocationCreationError("Authentication token not found. Please login again.")
            return
        }
        
        prepareLocationCreationRequest()
        
        let createLocationRequest = buildLocationCreationRequest(
            habitationId: habitationId,
            addressNo: addressNo,
            addressLine01: addressLine01,
            addressLine02: addressLine02,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude,
            nearestHabitationLatitude: nearestHabitationLatitude,
            nearestHabitationLongitude: nearestHabitationLongitude
        )
        
        let headers = buildAuthenticationHeaders(token: token)
        
        processLocationCreationRequest(
            request: createLocationRequest,
            headers: headers,
            habitationId: habitationId
        )
    }
    
    // MARK: - Public Utility Methods
    
    /**
     * Retrieves location data for a specific habitation.
     * Checks cache first, then searches the locations array.
     * 
     * @param habitationId The unique identifier of the habitation
     * @return LocationData if found, nil otherwise
     */
    func getLocationForHabitation(habitationId: String) -> LocationData? {
        // Check cache first for performance
        if let cachedLocation = locationCache[habitationId] {
            return cachedLocation
        }
        
        // Check locations array
        return locations.first { $0.habitationId == habitationId }
    }
    
    // MARK: - Private Helper Methods
    
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
     * Prepares the UI state for location fetch request.
     */
    private func prepareLocationFetchRequest() {
        isFetchingLocation = true
        clearError()
    }
    
    /**
     * Prepares the UI state for location creation request.
     */
    private func prepareLocationCreationRequest() {
        isCreatingLocation = true
        clearLocationCreationError()
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
     * Builds the request object for location creation.
     * 
     * @param habitationId The habitation ID
     * @param addressNo The address number
     * @param addressLine01 The primary address line
     * @param addressLine02 The secondary address line
     * @param city The city name
     * @param district The district name
     * @param latitude The latitude coordinate
     * @param longitude The longitude coordinate
     * @param nearestHabitationLatitude The nearest habitation latitude
     * @param nearestHabitationLongitude The nearest habitation longitude
     * @return Configured CreateLocationRequest object
     */
    private func buildLocationCreationRequest(
        habitationId: String,
        addressNo: String,
        addressLine01: String,
        addressLine02: String,
        city: String,
        district: String,
        latitude: Double,
        longitude: Double,
        nearestHabitationLatitude: Double,
        nearestHabitationLongitude: Double
    ) -> CreateLocationRequest {
        return CreateLocationRequest(
            habitation: habitationId,
            addressNo: addressNo,
            addressLine01: addressLine01,
            addressLine02: addressLine02,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude,
            nearestHabitationLatitude: nearestHabitationLatitude,
            nearestHabitationLongitude: nearestHabitationLongitude
        )
    }
    
    /**
     * Processes the location fetch network request.
     * 
     * @param habitationId The habitation ID
     * @param headers The HTTP headers
     */
    private func processLocationFetchRequest(
        habitationId: String,
        headers: [String: String]
    ) {
        print("🔍 DEBUG - Making GET request to: https://bodima-backend-api.vercel.app/locations/habitation/\(habitationId)")
        print("🔍 DEBUG - Method: GET")
        print("🔍 DEBUG - Headers: \(headers)")
        
        networkManager.requestWithHeaders(
            endpoint: .getLocationByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: GetLocationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleLocationFetchResponse(result, habitationId: habitationId)
            }
        }
    }
    
    /**
     * Processes the location creation network request.
     * 
     * @param request The location creation request
     * @param headers The HTTP headers
     * @param habitationId The habitation ID for response handling
     */
    private func processLocationCreationRequest(
        request: CreateLocationRequest,
        headers: [String: String],
        habitationId: String
    ) {
        // Print request details for debugging
        do {
            let requestData = try JSONEncoder().encode(request)
            if let requestString = String(data: requestData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(requestString)")
            }
        } catch {
            print("🔍 DEBUG - Could not encode request body: \(error)")
        }
        
        print("🔍 DEBUG - Making request to: https://bodima-backend-api.vercel.app/locations")
        print("🔍 DEBUG - Method: POST")
        print("🔍 DEBUG - Headers: \(headers)")
        
        networkManager.requestWithHeaders(
            endpoint: .createLocation,
            body: request,
            headers: headers,
            responseType: CreateLocationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleLocationCreationResponse(result, habitationId: habitationId)
            }
        }
    }
    
    /**
     * Handles the response from location fetch API call.
     * 
     * @param result The network result
     * @param habitationId The habitation ID for caching
     */
    private func handleLocationFetchResponse(
        _ result: Result<GetLocationResponse, Error>,
        habitationId: String
    ) {
        isFetchingLocation = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Response Status Code: 200")
            print("🔍 DEBUG - Response Success: \(response.success)")
            
            if response.success, let locationData = response.data {
                handleSuccessfulLocationFetch(locationData, habitationId: habitationId)
            } else {
                print("❌ Location not found for habitation: \(habitationId)")
                showError(response.message ?? "Location not found for this habitation")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Network Error: \(error)")
            handleNetworkError(error)
        }
    }
    
    /**
     * Handles the response from location creation API call.
     * 
     * @param result The network result
     * @param habitationId The habitation ID for caching
     */
    private func handleLocationCreationResponse(
        _ result: Result<CreateLocationResponse, Error>,
        habitationId: String
    ) {
        isCreatingLocation = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Response Status Code: 201")
            print("🔍 DEBUG - Response Success: \(response.success)")
            print("🔍 DEBUG - Response Message: \(response.message)")
            
            if response.success {
                handleSuccessfulLocationCreation(response, habitationId: habitationId)
            } else {
                print("❌ Location creation failed: \(response.message)")
                showLocationCreationError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Location Creation Error: \(error)")
            handleLocationCreationError(error)
        }
    }
    
    /**
     * Handles successful location fetch by updating local state.
     * 
     * @param locationData The fetched location data
     * @param habitationId The habitation ID for caching
     */
    private func handleSuccessfulLocationFetch(
        _ locationData: LocationData,
        habitationId: String
    ) {
        print("✅ Location fetched successfully for habitation: \(habitationId)")
        
        // Cache the location using the habitation ID
        locationCache[habitationId] = locationData
        selectedLocation = locationData
        
        // Add to locations array if not already present
        if !locations.contains(where: { $0.id == locationData.id }) {
            locations.append(locationData)
        }
        
        printLocationDataForDebug(location: locationData)
    }
    
    /**
     * Handles successful location creation by updating local state.
     * 
     * @param response The successful API response
     * @param habitationId The habitation ID for caching
     */
    private func handleSuccessfulLocationCreation(
        _ response: CreateLocationResponse,
        habitationId: String
    ) {
        print("✅ Location created successfully")
        locationCreationSuccess = true
        locationCreationMessage = response.message
        
        if let newLocation = response.data {
            print("🔍 DEBUG - Created Location Data: \(newLocation)")
            createdLocation = newLocation
            locations.append(newLocation)
            // Cache the new location
            locationCache[habitationId] = newLocation
            selectedLocation = newLocation
            
            printLocationDataForDebug(location: newLocation)
        } else {
            print("⚠️ Location created but no data returned")
        }
    }
    
    /**
     * Validates if coordinates are within valid geographical ranges.
     * 
     * @param latitude The latitude coordinate
     * @param longitude The longitude coordinate
     * @return True if coordinates are valid, false otherwise
     */
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    /**
     * Calculates the distance between a location and a coordinate using the Haversine formula.
     * Returns the distance in meters.
     * 
     * @param location The source location data
     * @param coordinate The target coordinate (latitude, longitude)
     * @return Distance in meters
     */
    func calculateDistance(from location: LocationData, to coordinate: (latitude: Double, longitude: Double)) -> Double {
        let earthRadius = 6371000.0 // Earth radius in meters
        
        let lat1Rad = location.latitude * .pi / 180
        let lon1Rad = location.longitude * .pi / 180
        let lat2Rad = coordinate.latitude * .pi / 180
        let lon2Rad = coordinate.longitude * .pi / 180
        
        let deltaLat = lat2Rad - lat1Rad
        let deltaLon = lon2Rad - lon1Rad
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) + cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    /**
     * Formats a coordinate value to 6 decimal places for display.
     * 
     * @param coordinate The coordinate value to format
     * @return Formatted coordinate string
     */
    func formatCoordinate(_ coordinate: Double) -> String {
        return String(format: "%.6f", coordinate)
    }
    
    /**
     * Constructs a full address string from location data.
     * Filters out empty components and joins with commas.
     * 
     * @param location The location data to format
     * @return Complete formatted address string
     */
    func getFullAddress(from location: LocationData) -> String {
        let addressComponents = [
            location.addressNo,
            location.addressLine01,
            location.addressLine02,
            location.city,
            location.district
        ].filter { !$0.isEmpty }
        
        return addressComponents.joined(separator: ", ")
    }
    
    /**
     * Prints comprehensive location data for debugging purposes.
     * Outputs all location fields in a formatted, readable manner.
     * 
     * @param location The location data to debug
     */
    private func printLocationDataForDebug(location: LocationData) {
        print("🏠 ===== LOCATION DATA DEBUG =====")
        print("📍 Location ID: \(location.id)")
        print("🏠 Habitation ID: \(location.habitationId)")
        if let details = location.habitationDetails {
            print("🏠 Habitation Name: \(details.name)")
            print("🏠 Habitation Type: \(details.type)")
            print("🏠 Habitation Price: \(details.price)")
        } else {
            print("🏠 Habitation Details: Not available (String ID only)")
        }
        print("📮 Address No: \(location.addressNo)")
        print("🏠 Address Line 1: \(location.addressLine01)")
        print("🏠 Address Line 2: \(location.addressLine02)")
        print("🏙️ City: \(location.city)")
        print("🌍 District: \(location.district)")
        print("📍 Latitude: \(formatCoordinate(location.latitude))")
        print("📍 Longitude: \(formatCoordinate(location.longitude))")
        print("📍 Nearest Habitation Lat: \(formatCoordinate(location.nearestHabitationLatitude))")
        print("📍 Nearest Habitation Lng: \(formatCoordinate(location.nearestHabitationLongitude))")
        print("⏰ Created At: \(location.createdAt)")
        print("⏰ Updated At: \(location.updatedAt)")
        print("📍 Full Address: \(getFullAddress(from: location))")
        print("🏠 ================================")
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
     * Handles location creation specific errors with appropriate messaging.
     * 
     * @param error The error that occurred during location creation
     */
    private func handleLocationCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showLocationCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showLocationCreationError(message)
                
            case .serverError(let message):
                showLocationCreationError("Server error: \(message)")
                
            default:
                showLocationCreationError(networkError.localizedDescription)
            }
        } else {
            showLocationCreationError("Network error: \(error.localizedDescription)")
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
        fetchLocationError = message
        print("❌ ERROR - \(message)")
    }
    
    /**
     * Clears the general error state and message.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
        fetchLocationError = nil
    }
    
    /**
     * Displays a location creation specific error message.
     * 
     * @param message The error message to display
     */
    func showLocationCreationError(_ message: String) {
        locationCreationMessage = message
        locationCreationSuccess = false
        print("❌ LOCATION CREATION ERROR - \(message)")
    }
    
    /**
     * Clears the location creation error state and message.
     */
    private func clearLocationCreationError() {
        locationCreationMessage = nil
        locationCreationSuccess = false
    }
    
    // MARK: - Integration Methods
    
    /**
     * Creates a location for a habitation using HabitationData object.
     * Convenience method for integration with HabitationViewModel.
     * 
     * @param habitation The habitation data object
     * @param addressNo The address number
     * @param addressLine01 The primary address line
     * @param addressLine02 The secondary address line
     * @param city The city name
     * @param district The district name
     * @param latitude The latitude coordinate
     * @param longitude The longitude coordinate
     * @param nearestHabitationLatitude The nearest habitation latitude
     * @param nearestHabitationLongitude The nearest habitation longitude
     */
    func createLocationForHabitation(
        habitation: HabitationData,
        addressNo: String,
        addressLine01: String,
        addressLine02: String,
        city: String,
        district: String,
        latitude: Double,
        longitude: Double,
        nearestHabitationLatitude: Double,
        nearestHabitationLongitude: Double
    ) {
        createLocation(
            habitationId: habitation.id,
            addressNo: addressNo,
            addressLine01: addressLine01,
            addressLine02: addressLine02,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude,
            nearestHabitationLatitude: nearestHabitationLatitude,
            nearestHabitationLongitude: nearestHabitationLongitude
        )
    }
    
    /**
     * Fetches location for the currently selected habitation in HabitationViewModel.
     * Integration method for seamless cooperation between ViewModels.
     * 
     * @param habitationViewModel The habitation view model instance
     */
    func fetchLocationForSelectedHabitation(habitationViewModel: HabitationViewModel) {
        guard let selectedHabitation = habitationViewModel.selectedHabitation else {
            showError("No habitation selected")
            return
        }
        
        fetchLocationByHabitationId(habitationId: selectedHabitation.id)
    }
    
    // MARK: - Validation Methods
    
    /**
     * Validates location data for completeness and correctness.
     * Checks required fields and coordinate validity.
     * 
     * @param addressNo The address number to validate
     * @param addressLine01 The primary address line to validate
     * @param city The city name to validate
     * @param district The district name to validate
     * @param latitude The latitude coordinate to validate
     * @param longitude The longitude coordinate to validate
     * @return Tuple containing validation result and error message if invalid
     */
    func validateLocationData(
        addressNo: String,
        addressLine01: String,
        city: String,
        district: String,
        latitude: Double,
        longitude: Double
    ) -> (isValid: Bool, errorMessage: String?) {
        if addressNo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (false, "Address number is required")
        }
        
        if addressLine01.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (false, "Address line 1 is required")
        }
        
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (false, "City is required")
        }
        
        if district.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (false, "District is required")
        }
        
        if !isValidCoordinate(latitude: latitude, longitude: longitude) {
            return (false, "Invalid coordinates provided. Latitude must be between -90 and 90, longitude between -180 and 180")
        }
        
        return (true, nil)
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
     * Clears all location data and resets error states.
     * Useful for logout or data refresh scenarios.
     */
    func clearLocations() {
        locations.removeAll()
        locationCache.removeAll()
        selectedLocation = nil
        clearError()
        clearLocationCreationError()
        print("🔍 DEBUG - Cleared all locations and cache")
    }
    
    /**
     * Resets all location creation related states to their initial values.
     * Useful for preparing for new location creation operations.
     */
    func resetLocationCreationState() {
        isCreatingLocation = false
        locationCreationSuccess = false
        locationCreationMessage = nil
        createdLocation = nil
        print("🔍 DEBUG - Reset location creation state")
    }
    
    /**
     * Resets the selected location to nil.
     * Used when switching contexts or clearing selection.
     */
    func resetSelectedLocation() {
        selectedLocation = nil
        print("🔍 DEBUG - Reset selected location")
    }
    
    /**
     * Refreshes location data for a specific habitation by clearing cache and refetching.
     * Forces a fresh API call even if data is cached.
     * 
     * @param habitationId The unique identifier of the habitation
     */
    func refreshLocationForHabitation(habitationId: String) {
        // Remove from cache to force refresh
        locationCache.removeValue(forKey: habitationId)
        fetchLocationByHabitationId(habitationId: habitationId)
    }
    
    // MARK: - Computed Properties
    
    /**
     * Total count of all locations loaded in the application.
     * 
     * @return The total number of locations
     */
    var locationCount: Int {
        return locations.count
    }
    
    /**
     * Boolean indicating if a location is currently selected.
     * 
     * @return True if a location is selected, false otherwise
     */
    var hasSelectedLocation: Bool {
        return selectedLocation != nil
    }
    
    /**
     * Boolean indicating if any location operation is currently in progress.
     * 
     * @return True if any operation is active, false otherwise
     */
    var isLocationOperationInProgress: Bool {
        return isCreatingLocation || isFetchingLocation || isLoading
    }
    
    /**
     * Human-readable summary of available locations.
     * 
     * @return Descriptive string about location availability
     */
    var locationSummary: String {
        if locations.isEmpty {
            return "No locations available"
        } else if locations.count == 1 {
            return "1 location available"
        } else {
            return "\(locations.count) locations available"
        }
    }
}

// MARK: - Extensions for Additional Functionality

extension LocationData: Equatable {
    static func == (lhs: LocationData, rhs: LocationData) -> Bool {
        return lhs.id == rhs.id
    }
}

extension LocationData {
    var coordinateString: String {
        return "\(formatCoordinate(latitude)), \(formatCoordinate(longitude))"
    }
    
    private func formatCoordinate(_ coordinate: Double) -> String {
        return String(format: "%.6f", coordinate)
    }
    
    var shortAddress: String {
        return "\(addressNo) \(addressLine01), \(city)"
    }
    
    var isValidLocation: Bool {
        return !addressNo.isEmpty &&
               !addressLine01.isEmpty &&
               !city.isEmpty &&
               !district.isEmpty &&
               latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}
