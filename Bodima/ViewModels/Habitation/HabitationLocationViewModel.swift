import Foundation

// MARK: - Nested Habitation Model for Location Response
struct LocationHabitation: Codable {
    let id: String
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
    let price: Int
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case name
        case description
        case type
        case isReserved
        case price
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

// MARK: - Flexible LocationData that handles both String and Object habitation
struct LocationData: Codable, Identifiable {
    let id: String
    let habitationId: String
    let habitationDetails: LocationHabitation?
    let addressNo: String
    let addressLine01: String
    let addressLine02: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let nearestHabitationLatitude: Double
    let nearestHabitationLongitude: Double
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    // Computed property for backward compatibility
    var habitation: LocationHabitation {
        return habitationDetails ?? LocationHabitation(
            id: habitationId,
            user: "",
            name: "Unknown",
            description: "",
            type: "Unknown",
            isReserved: false,
            price: 0,
            createdAt: createdAt,
            updatedAt: updatedAt,
            v: 0
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case addressNo
        case addressLine01
        case addressLine02
        case city
        case district
        case latitude
        case longitude
        case nearestHabitationLatitude
        case nearestHabitationLongitude
        case createdAt
        case updatedAt
        case v = "__v"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        addressNo = try container.decode(String.self, forKey: .addressNo)
        addressLine01 = try container.decode(String.self, forKey: .addressLine01)
        addressLine02 = try container.decode(String.self, forKey: .addressLine02)
        city = try container.decode(String.self, forKey: .city)
        district = try container.decode(String.self, forKey: .district)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        nearestHabitationLatitude = try container.decode(Double.self, forKey: .nearestHabitationLatitude)
        nearestHabitationLongitude = try container.decode(Double.self, forKey: .nearestHabitationLongitude)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        v = try container.decode(Int.self, forKey: .v)
        
        
        if let habitationString = try? container.decode(String.self, forKey: .habitation) {
            habitationId = habitationString
            habitationDetails = nil
            print("🔍 DEBUG - Decoded habitation as String ID: \(habitationString)")
        } else if let habitationObject = try? container.decode(LocationHabitation.self, forKey: .habitation) {
           
            habitationId = habitationObject.id
            habitationDetails = habitationObject
            print("🔍 DEBUG - Decoded habitation as Object with ID: \(habitationObject.id)")
        } else {
           
            let habitationValue = try container.decode(String.self, forKey: .habitation)
            habitationId = habitationValue
            habitationDetails = nil
            print("🔍 DEBUG - Fallback: Decoded habitation as String: \(habitationValue)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(addressNo, forKey: .addressNo)
        try container.encode(addressLine01, forKey: .addressLine01)
        try container.encode(addressLine02, forKey: .addressLine02)
        try container.encode(city, forKey: .city)
        try container.encode(district, forKey: .district)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(nearestHabitationLatitude, forKey: .nearestHabitationLatitude)
        try container.encode(nearestHabitationLongitude, forKey: .nearestHabitationLongitude)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(v, forKey: .v)
        
        // Encode based on what we have
        if let details = habitationDetails {
            try container.encode(details, forKey: .habitation)
        } else {
            try container.encode(habitationId, forKey: .habitation)
        }
    }
}

// MARK: - Response Models
struct GetLocationResponse: Codable {
    let success: Bool
    let data: LocationData?
    let message: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(LocationData.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    enum CodingKeys: String, CodingKey {
        case success, data, message
    }
}

struct CreateLocationRequest: Codable {
    let habitation: String
    let addressNo: String
    let addressLine01: String
    let addressLine02: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let nearestHabitationLatitude: Double
    let nearestHabitationLongitude: Double
}

struct CreateLocationResponse: Codable {
    let success: Bool
    let message: String
    let data: LocationData?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)
        
        // Handle potential decoding errors for data
        do {
            data = try container.decodeIfPresent(LocationData.self, forKey: .data)
        } catch {
            print("🔍 DEBUG - Error decoding location data: \(error)")
            data = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, data
    }
}

enum LocationError: Error, LocalizedError {
    case invalidHabitationId
    case locationNotFound
    case networkError(String)
    case invalidCoordinates
    case missingAddress
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidHabitationId:
            return "Invalid habitation ID provided"
        case .locationNotFound:
            return "Location not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .missingAddress:
            return "Address information is required"
        case .decodingError(let message):
            return "Data decoding error: \(message)"
        }
    }
}

@MainActor
class HabitationLocationViewModel: ObservableObject {
    @Published var locations: [LocationData] = []
    @Published var selectedLocation: LocationData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    @Published var isCreatingLocation = false
    @Published var locationCreationSuccess = false
    @Published var locationCreationMessage: String?
    @Published var createdLocation: LocationData?
    
    @Published var isFetchingLocation = false
    @Published var fetchLocationError: String?
    
    // Cache for storing location data by habitation ID
    @Published var locationCache: [String: LocationData] = [:]
    
    private let networkManager = NetworkManager.shared
    
    func fetchLocationByHabitationId(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        // Check cache first
        if let cachedLocation = locationCache[habitationId] {
            print("📍 Using cached location for habitation: \(habitationId)")
            selectedLocation = cachedLocation
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        print("🔍 DEBUG - Making GET request to: https://bodima-backend-api.vercel.app/locations/habitation/\(habitationId)")
        
        isFetchingLocation = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        print("🔍 DEBUG - Method: GET")
        print("🔍 DEBUG - Headers: \(headers)")
        
        networkManager.requestWithHeaders(
            endpoint: .getLocationByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: GetLocationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingLocation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - Response Status Code: 200")
                    print("🔍 DEBUG - Response Success: \(response.success)")
                    
                    if response.success, let locationData = response.data {
                        print("✅ Location fetched successfully for habitation: \(habitationId)")
                        
                        // Cache the location using the habitation ID
                        self?.locationCache[habitationId] = locationData
                        self?.selectedLocation = locationData
                        
                        // Add to locations array if not already present
                        if let locations = self?.locations, !locations.contains(where: { $0.id == locationData.id }) {
                            self?.locations.append(locationData)
                        }
                        
                        self?.printLocationDataForDebug(location: locationData)
                        
                    } else {
                        print("❌ Location not found for habitation: \(habitationId)")
                        self?.showError(response.message ?? "Location not found for this habitation")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Network Error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
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
        
        // Validation
        let validation = validateLocationData(
            addressNo: addressNo,
            addressLine01: addressLine01,
            city: city,
            district: district,
            latitude: latitude,
            longitude: longitude
        )
        
        if !validation.isValid {
            showLocationCreationError(validation.errorMessage ?? "Invalid location data")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showLocationCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingLocation = true
        clearLocationCreationError()
        
        let createLocationRequest = CreateLocationRequest(
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
        
        print("🔍 DEBUG - Location data:")
        print("  - Address No: \(addressNo)")
        print("  - Address Line 1: \(addressLine01)")
        print("  - Address Line 2: \(addressLine02)")
        print("  - City: \(city)")
        print("  - District: \(district)")
        print("  - Latitude: \(latitude)")
        print("  - Longitude: \(longitude)")
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        // Print request details
        do {
            let requestData = try JSONEncoder().encode(createLocationRequest)
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
            body: createLocationRequest,
            headers: headers,
            responseType: CreateLocationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingLocation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - Response Status Code: 201")
                    print("🔍 DEBUG - Response Success: \(response.success)")
                    print("🔍 DEBUG - Response Message: \(response.message)")
                    
                    if response.success {
                        print("✅ Location created successfully")
                        self?.locationCreationSuccess = true
                        self?.locationCreationMessage = response.message
                        
                        if let newLocation = response.data {
                            print("🔍 DEBUG - Created Location Data: \(newLocation)")
                            self?.createdLocation = newLocation
                            self?.locations.append(newLocation)
                            // Cache the new location
                            self?.locationCache[habitationId] = newLocation
                            self?.selectedLocation = newLocation
                            
                            self?.printLocationDataForDebug(location: newLocation)
                        } else {
                            print("⚠️ Location created but no data returned")
                        }
                    } else {
                        print("❌ Location creation failed: \(response.message)")
                        self?.showLocationCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Location Creation Error: \(error)")
                    self?.handleLocationCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    func getLocationForHabitation(habitationId: String) -> LocationData? {
        // Check cache first
        if let cachedLocation = locationCache[habitationId] {
            return cachedLocation
        }
        
        // Check locations array
        return locations.first { $0.habitationId == habitationId }
    }
    
    func calculateDistance(from location: LocationData, to coordinate: (latitude: Double, longitude: Double)) -> Double {
        let earthRadius = 6371000.0
        
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
    
    func formatCoordinate(_ coordinate: Double) -> String {
        return String(format: "%.6f", coordinate)
    }
    
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
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        fetchLocationError = message
        print("❌ ERROR - \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
        fetchLocationError = nil
    }
    
    func showLocationCreationError(_ message: String) {
        locationCreationMessage = message
        locationCreationSuccess = false
        print("❌ LOCATION CREATION ERROR - \(message)")
    }
    
    private func clearLocationCreationError() {
        locationCreationMessage = nil
        locationCreationSuccess = false
    }
    
    // MARK: - Public Methods
    
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
    
    func fetchLocationForSelectedHabitation(habitationViewModel: HabitationViewModel) {
        guard let selectedHabitation = habitationViewModel.selectedHabitation else {
            showError("No habitation selected")
            return
        }
        
        fetchLocationByHabitationId(habitationId: selectedHabitation.id)
    }
    
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
    
    func clearLocations() {
        locations.removeAll()
        locationCache.removeAll()
        selectedLocation = nil
        clearError()
        clearLocationCreationError()
        print("🔍 DEBUG - Cleared all locations and cache")
    }
    
    func resetLocationCreationState() {
        isCreatingLocation = false
        locationCreationSuccess = false
        locationCreationMessage = nil
        createdLocation = nil
        print("🔍 DEBUG - Reset location creation state")
    }
    
    func resetSelectedLocation() {
        selectedLocation = nil
        print("🔍 DEBUG - Reset selected location")
    }
    
    func refreshLocationForHabitation(habitationId: String) {
        // Remove from cache to force refresh
        locationCache.removeValue(forKey: habitationId)
        fetchLocationByHabitationId(habitationId: habitationId)
    }
    
    // MARK: - Computed Properties
    
    var locationCount: Int {
        return locations.count
    }
    
    var hasSelectedLocation: Bool {
        return selectedLocation != nil
    }
    
    var isLocationOperationInProgress: Bool {
        return isCreatingLocation || isFetchingLocation || isLoading
    }
    
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
