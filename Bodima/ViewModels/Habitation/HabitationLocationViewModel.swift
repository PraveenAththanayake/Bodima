import Foundation

// MARK: - Location Models
struct LocationData: Codable, Identifiable {
    let id: String
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
    let createdAt: String
    let updatedAt: String
    let v: Int
    
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
}

// MARK: - Create Location Request
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

// MARK: - Create Location Response
struct CreateLocationResponse: Codable {
    let success: Bool
    let message: String
    let data: LocationData?
}

// MARK: - Get Location Response
struct GetLocationResponse: Codable {
    let success: Bool
    let message: String
    let data: LocationData?
}

// MARK: - Location Error Types
enum LocationError: Error, LocalizedError {
    case invalidHabitationId
    case locationNotFound
    case networkError(String)
    case invalidCoordinates
    case missingAddress
    
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
        }
    }
}

// MARK: - HabitationLocationViewModel
@MainActor
class HabitationLocationViewModel: ObservableObject {
    @Published var locations: [LocationData] = []
    @Published var selectedLocation: LocationData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Create location specific states
    @Published var isCreatingLocation = false
    @Published var locationCreationSuccess = false
    @Published var locationCreationMessage: String?
    @Published var createdLocation: LocationData?
    
    // Fetch location specific states
    @Published var isFetchingLocation = false
    @Published var fetchLocationError: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Create Location
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
        guard !habitationId.isEmpty else {
            showLocationCreationError("Habitation ID is required")
            return
        }
        
        guard !addressNo.isEmpty else {
            showLocationCreationError("Address number is required")
            return
        }
        
        guard !addressLine01.isEmpty else {
            showLocationCreationError("Address line 1 is required")
            return
        }
        
        guard !city.isEmpty else {
            showLocationCreationError("City is required")
            return
        }
        
        guard !district.isEmpty else {
            showLocationCreationError("District is required")
            return
        }
        
        guard isValidCoordinate(latitude: latitude, longitude: longitude) else {
            showLocationCreationError("Invalid coordinates provided")
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
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
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
                    print("🔍 DEBUG - CreateLocation success: \(response.success)")
                    print("🔍 DEBUG - CreateLocation message: \(response.message)")
                    print("🔍 DEBUG - CreateLocation data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.locationCreationSuccess = true
                        self?.locationCreationMessage = response.message
                        self?.createdLocation = response.data
                        print("✅ Location created successfully")
                        
                        // Add the new location to the list
                        if let newLocation = response.data {
                            self?.locations.append(newLocation)
                        }
                    } else {
                        self?.showLocationCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create location error: \(error)")
                    self?.handleLocationCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Fetch Location by Habitation ID
    func fetchLocationByHabitationId(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingLocation = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getLocationByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: GetLocationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingLocation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetLocationByHabitationId success: \(response.success)")
                    print("🔍 DEBUG - GetLocationByHabitationId data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.selectedLocation = response.data
                        print("✅ Location fetched successfully by habitation ID")
                    } else {
                        self?.showError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch location by habitation ID error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Create Location with Created Habitation
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
    
    // MARK: - Utility Methods
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
    
    func getLocationForHabitation(habitationId: String) -> LocationData? {
        return locations.first { $0.habitation == habitationId }
    }
    
    func calculateDistance(from location: LocationData, to coordinate: (latitude: Double, longitude: Double)) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        
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
        return String(format: "%.4f", coordinate)
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
        print("❌ Location Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
        fetchLocationError = nil
    }
    
    func showLocationCreationError(_ message: String) {
        locationCreationMessage = message
        locationCreationSuccess = false
        print("❌ Location Creation Error: \(message)")
    }
    
    private func clearLocationCreationError() {
        locationCreationMessage = nil
        locationCreationSuccess = false
    }
    
    // MARK: - Computed Properties
    var locationCount: Int {
        return locations.count
    }
    
    var hasSelectedLocation: Bool {
        return selectedLocation != nil
    }
    
    // MARK: - Date Formatting
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
    
    // MARK: - Clear Data
    func clearLocations() {
        locations.removeAll()
        selectedLocation = nil
        clearError()
        clearLocationCreationError()
    }
    
    // MARK: - Reset States
    func resetLocationCreationState() {
        isCreatingLocation = false
        locationCreationSuccess = false
        locationCreationMessage = nil
        createdLocation = nil
    }
    
    func resetSelectedLocation() {
        selectedLocation = nil
    }
    
    // MARK: - Validation Methods
    func validateLocationData(
        addressNo: String,
        addressLine01: String,
        city: String,
        district: String,
        latitude: Double,
        longitude: Double
    ) -> (isValid: Bool, errorMessage: String?) {
        if addressNo.isEmpty {
            return (false, "Address number is required")
        }
        
        if addressLine01.isEmpty {
            return (false, "Address line 1 is required")
        }
        
        if city.isEmpty {
            return (false, "City is required")
        }
        
        if district.isEmpty {
            return (false, "District is required")
        }
        
        if !isValidCoordinate(latitude: latitude, longitude: longitude) {
            return (false, "Invalid coordinates provided")
        }
        
        return (true, nil)
    }
}

// MARK: - HabitationLocationViewModel Extension for Integration
extension HabitationLocationViewModel {
    
    // Convenience method to create location using just created habitation
    func createLocationFromHabitationViewModel(
        habitationViewModel: HabitationViewModel,
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
        guard let createdHabitation = habitationViewModel.createdHabitation else {
            showLocationCreationError("No habitation found. Please create a habitation first.")
            return
        }
        
        createLocationForHabitation(
            habitation: createdHabitation,
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
    
    // Get location for selected habitation
    func fetchLocationForSelectedHabitation(habitationViewModel: HabitationViewModel) {
        guard let selectedHabitation = habitationViewModel.selectedHabitation else {
            showError("No habitation selected")
            return
        }
        
        fetchLocationByHabitationId(habitationId: selectedHabitation.id)
    }
}
