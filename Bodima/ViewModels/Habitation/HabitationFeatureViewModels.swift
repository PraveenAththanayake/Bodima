import Foundation

// MARK: - HabitationFeature Models
struct HabitationFeatureData: Codable, Identifiable {
    let id: String
    let habitation: String
    let sqft: Int
    let familyType: String
    let windowsCount: Int
    let smallBedCount: Int
    let largeBedCount: Int
    let chairCount: Int
    let tableCount: Int
    let isElectricityAvailable: Bool
    let isWachineMachineAvailable: Bool
    let isWaterAvailable: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case sqft
        case familyType
        case windowsCount
        case smallBedCount
        case largeBedCount
        case chairCount
        case tableCount
        case isElectricityAvailable
        case isWachineMachineAvailable
        case isWaterAvailable
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

// MARK: - Family Type Enum
enum FamilyType: String, CaseIterable, Codable {
    case oneStory = "One Story"
    case twoStory = "Two Story"
    case threeStory = "Three Story"
    case apartment = "Apartment"
    case villa = "Villa"
    case cottage = "Cottage"
    case townhouse = "Townhouse"
    case duplex = "Duplex"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Create HabitationFeature Request
struct CreateHabitationFeatureRequest: Codable {
    let habitation: String
    let sqft: Int
    let familyType: String
    let windowsCount: Int
    let smallBedCount: Int
    let largeBedCount: Int
    let chairCount: Int
    let tableCount: Int
    let isElectricityAvailable: Bool
    let isWachineMachineAvailable: Bool
    let isWaterAvailable: Bool
}

// MARK: - Create HabitationFeature Response
struct CreateHabitationFeatureResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationFeatureData?
}

// MARK: - Get HabitationFeature Response
struct GetHabitationFeatureResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationFeatureData?
}

// MARK: - HabitationFeature Error Types
enum HabitationFeatureError: Error, LocalizedError {
    case invalidHabitationId
    case featureNotFound
    case networkError(String)
    case invalidSquareFootage
    case invalidCountValues
    case missingRequiredFields
    
    var errorDescription: String? {
        switch self {
        case .invalidHabitationId:
            return "Invalid habitation ID provided"
        case .featureNotFound:
            return "Habitation features not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidSquareFootage:
            return "Invalid square footage provided"
        case .invalidCountValues:
            return "Count values must be non-negative"
        case .missingRequiredFields:
            return "Required fields are missing"
        }
    }
}



// MARK: - HabitationFeatureViewModel
@MainActor
class HabitationFeatureViewModel: ObservableObject {
    @Published var features: [HabitationFeatureData] = []
    @Published var selectedFeature: HabitationFeatureData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Create feature specific states
    @Published var isCreatingFeature = false
    @Published var featureCreationSuccess = false
    @Published var featureCreationMessage: String?
    @Published var createdFeature: HabitationFeatureData?
    
    // Fetch feature specific states
    @Published var isFetchingFeature = false
    @Published var fetchFeatureError: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Create HabitationFeature
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
        guard !habitationId.isEmpty else {
            showFeatureCreationError("Habitation ID is required")
            return
        }
        
        guard sqft > 0 else {
            showFeatureCreationError("Square footage must be greater than 0")
            return
        }
        
        guard windowsCount >= 0, smallBedCount >= 0, largeBedCount >= 0,
              chairCount >= 0, tableCount >= 0 else {
            showFeatureCreationError("Count values must be non-negative")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showFeatureCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingFeature = true
        clearFeatureCreationError()
        
        let createFeatureRequest = CreateHabitationFeatureRequest(
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
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .createHabitationFeature(habitationId: habitationId),
            body: createFeatureRequest,
            headers: headers,
            responseType: CreateHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingFeature = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateHabitationFeature success: \(response.success)")
                    print("🔍 DEBUG - CreateHabitationFeature message: \(response.message)")
                    print("🔍 DEBUG - CreateHabitationFeature data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.featureCreationSuccess = true
                        self?.featureCreationMessage = response.message
                        self?.createdFeature = response.data
                        print("✅ Habitation feature created successfully")
                        
                        // Add the new feature to the list
                        if let newFeature = response.data {
                            self?.features.append(newFeature)
                        }
                    } else {
                        self?.showFeatureCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create habitation feature error: \(error)")
                    self?.handleFeatureCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Fetch Features by Habitation ID (Updated to handle direct data response)
    func fetchFeaturesByHabitationId(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingFeature = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        // First try to decode as standard response format
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: GetHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingFeature = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetFeaturesByHabitationId success: \(response.success)")
                    print("🔍 DEBUG - GetFeaturesByHabitationId data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.selectedFeature = response.data
                        print("✅ Habitation features fetched successfully")
                    } else {
                        self?.showError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Standard format failed, trying direct data format")
                    // If standard format fails, try direct data format
                    self?.fetchFeaturesByHabitationIdDirectFormat(habitationId: habitationId, headers: headers)
                }
            }
        }
    }
    
    // MARK: - Fetch Features by Habitation ID (Direct Data Format)
    private func fetchFeaturesByHabitationIdDirectFormat(habitationId: String, headers: [String: String]) {
        isFetchingFeature = true
        
        struct DirectHabitationFeatureResponse: Codable {
            let success: Bool
            let data: HabitationFeatureData
        }
        
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: DirectHabitationFeatureResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingFeature = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - Direct format GetFeaturesByHabitationId success: \(response.success)")
                    print("🔍 DEBUG - Direct format GetFeaturesByHabitationId data: \(response.data)")
                    
                    if response.success {
                        self?.selectedFeature = response.data
                        
                        // Update the features array if this feature isn't already in it
                        if let index = self?.features.firstIndex(where: { $0.id == response.data.id }) {
                            self?.features[index] = response.data
                        } else {
                            self?.features.append(response.data)
                        }
                        
                        print("✅ Habitation features fetched successfully (direct format)")
                    } else {
                        self?.showError("Failed to fetch features")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Direct format fetch habitation features error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Fetch All Features for Habitation (Alternative method for arrays)
    func fetchAllFeaturesByHabitationId(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingFeature = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        // Define response type for array of features
        struct HabitationFeaturesArrayResponse: Codable {
            let success: Bool
            let message: String?
            let data: [HabitationFeatureData]
        }
        
        networkManager.requestWithHeaders(
            endpoint: .getFeaturesByHabitationId(habitationId: habitationId),
            headers: headers,
            responseType: HabitationFeaturesArrayResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingFeature = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetAllFeaturesByHabitationId success: \(response.success)")
                    print("🔍 DEBUG - GetAllFeaturesByHabitationId data count: \(response.data.count)")
                    
                    if response.success {
                        self?.features = response.data
                        
                        // Set the first feature as selected if available
                        if let firstFeature = response.data.first {
                            self?.selectedFeature = firstFeature
                        }
                        
                        print("✅ All habitation features fetched successfully")
                    } else {
                        self?.showError(response.message ?? "Failed to fetch features")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch all habitation features error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Generic Fetch Method (Handles both single and array responses)
    func fetchHabitationFeatures(habitationId: String, expectArray: Bool = false) {
        if expectArray {
            fetchAllFeaturesByHabitationId(habitationId: habitationId)
        } else {
            fetchFeaturesByHabitationId(habitationId: habitationId)
        }
    }
    
    // MARK: - Create Feature with Created Habitation
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
    
    // MARK: - Utility Methods
    func getFeatureForHabitation(habitationId: String) -> HabitationFeatureData? {
        return features.first { $0.habitation == habitationId }
    }
    
    func getTotalBedrooms(from feature: HabitationFeatureData) -> Int {
        return feature.smallBedCount + feature.largeBedCount
    }
    
    func getTotalFurniture(from feature: HabitationFeatureData) -> Int {
        return feature.chairCount + feature.tableCount
    }
    
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
    
    func getUtilityAvailabilityScore(from feature: HabitationFeatureData) -> Int {
        var score = 0
        if feature.isElectricityAvailable { score += 1 }
        if feature.isWachineMachineAvailable { score += 1 }
        if feature.isWaterAvailable { score += 1 }
        return score
    }
    
    func formatSquareFootage(_ sqft: Int) -> String {
        return "\(sqft) sq ft"
    }
    
    func getFeatureSummary(from feature: HabitationFeatureData) -> String {
        let bedrooms = getTotalBedrooms(from: feature)
        let utilities = getAvailableUtilities(from: feature)
        
        return "\(formatSquareFootage(feature.sqft)) • \(bedrooms) bedroom(s) • \(feature.familyType) • \(utilities.count) utilities"
    }
    
    // MARK: - Validation Methods
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
    
    func suggestMinimumFurniture(sqft: Int, bedrooms: Int) -> (chairs: Int, tables: Int) {
        let baseChairs = max(2, bedrooms * 2)
        let baseTables = max(1, bedrooms)
        
        // Adjust based on square footage
        let sqftMultiplier = sqft / 500 // Every 500 sqft adds more furniture
        let additionalChairs = sqftMultiplier * 2
        let additionalTables = sqftMultiplier
        
        return (baseChairs + additionalChairs, baseTables + additionalTables)
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
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        fetchFeatureError = message
        print("❌ Habitation Feature Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
        fetchFeatureError = nil
    }
    
    func showFeatureCreationError(_ message: String) {
        featureCreationMessage = message
        featureCreationSuccess = false
        print("❌ Feature Creation Error: \(message)")
    }
    
    private func clearFeatureCreationError() {
        featureCreationMessage = nil
        featureCreationSuccess = false
    }
    
    // MARK: - Computed Properties
    var featureCount: Int {
        return features.count
    }
    
    var hasSelectedFeature: Bool {
        return selectedFeature != nil
    }
    
    var averageSquareFootage: Int {
        guard !features.isEmpty else { return 0 }
        let total = features.reduce(0) { $0 + $1.sqft }
        return total / features.count
    }
    
    var totalBedrooms: Int {
        return features.reduce(0) { result, feature in
            result + getTotalBedrooms(from: feature)
        }
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
    func clearFeatures() {
        features.removeAll()
        selectedFeature = nil
        clearError()
        clearFeatureCreationError()
    }
    
    // MARK: - Reset States
    func resetFeatureCreationState() {
        isCreatingFeature = false
        featureCreationSuccess = false
        featureCreationMessage = nil
        createdFeature = nil
    }
    
    func resetSelectedFeature() {
        selectedFeature = nil
    }
}

// MARK: - HabitationFeatureViewModel Extension for Integration
extension HabitationFeatureViewModel {
    
    // Convenience method to create feature using just created habitation
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
    
    // Get features for selected habitation
    func fetchFeaturesForSelectedHabitation(habitationViewModel: HabitationViewModel) {
        guard let selectedHabitation = habitationViewModel.selectedHabitation else {
            showError("No habitation selected")
            return
        }
        
        fetchFeaturesByHabitationId(habitationId: selectedHabitation.id)
    }
    
    // Create feature with suggested furniture based on size
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
