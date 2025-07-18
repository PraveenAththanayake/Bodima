import Foundation
import SwiftUI

@MainActor
class HabitationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var alertMessage: AlertMessage?
    @Published var createdHabitation: CompleteHabitation?
    @Published var habitations: [CompleteHabitation] = []
    @Published var creationProgress: HabitationCreationProgress = .idle
    
    // MARK: - Form Properties
    @Published var habitationName = ""
    @Published var habitationDescription = ""
    @Published var selectedHabitationType: HabitationType = .singleRoom
    @Published var isReserved = false
    
    // Location properties
    @Published var addressNo = ""
    @Published var addressLine01 = ""
    @Published var addressLine02 = ""
    @Published var city = ""
    @Published var selectedDistrict: District = .colombo
    @Published var latitude: Double = 6.9271
    @Published var longitude: Double = 79.8612
    @Published var nearestHabitationLatitude: Double = 6.9300
    @Published var nearestHabitationLongitude: Double = 79.8650
    
    // Feature properties
    @Published var sqft = 1500
    @Published var selectedFamilyType: FamilyType = .oneStory
    @Published var windowsCount = 8
    @Published var smallBedCount = 0
    @Published var largeBedCount = 1
    @Published var chairCount = 6
    @Published var tableCount = 2
    @Published var isElectricityAvailable = true
    @Published var isWashingMachineAvailable = true
    @Published var isWaterAvailable = true
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private let authViewModel: AuthViewModel
    
    // MARK: - Initialization
    init(
        networkManager: NetworkManager = NetworkManager.shared,
        authViewModel: AuthViewModel = AuthViewModel.shared
    ) {
        self.networkManager = networkManager
        self.authViewModel = authViewModel
    }
    
    // MARK: - Computed Properties
    var hasAlert: Bool {
        alertMessage != nil
    }
    
    var canCreateHabitation: Bool {
        !habitationName.isEmpty && !habitationDescription.isEmpty && authViewModel.hasValidToken
    }
    
    var canCreateLocation: Bool {
        !addressNo.isEmpty && !addressLine01.isEmpty && !city.isEmpty
    }
    
    var canCreateFeatures: Bool {
        sqft > 0 && windowsCount >= 0 && smallBedCount >= 0 && largeBedCount >= 0 && chairCount >= 0 && tableCount >= 0
    }
    
    // MARK: - Main Creation Method
    func createCompleteHabitation() async {
        guard let userId = authViewModel.currentUser?.id else {
            showAlert(.error("User not authenticated"))
            return
        }
        
        guard canCreateHabitation else {
            showAlert(.error("Please fill in all required habitation details"))
            return
        }
        
        setLoading(true)
        creationProgress = .creatingHabitation
        
        do {
            // Step 1: Create Habitation
            let habitation = try await createHabitation(userId: userId)
            
            // Step 2: Create Location
            creationProgress = .creatingLocation
            let location = try await createLocation(habitationId: habitation.id)
            
            // Step 3: Create Features
            creationProgress = .creatingFeatures
            let features = try await createHabitationFeatures(habitationId: habitation.id)
            
            // Step 4: Complete
            creationProgress = .completed
            let completeHabitation = CompleteHabitation(
                id: habitation.id,
                habitation: habitation,
                location: location,
                features: features
            )
            
            createdHabitation = completeHabitation
            habitations.append(completeHabitation)
            
            showAlert(.success("Habitation created successfully!"))
            resetForm()
            
        } catch {
            creationProgress = .failed
            handleError(error)
        }
        
        setLoading(false)
    }
    
    // MARK: - Individual API Calls
    private func createHabitation(userId: String) async throws -> Habitation {
        let request = CreateHabitationRequest(
            user: userId,
            name: habitationName,
            description: habitationDescription,
            type: selectedHabitationType.rawValue,
            isReserved: isReserved
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.request(
                endpoint: .createHabitation,
                body: request,
                responseType: CreateHabitationResponse.self
            ) { result in
                switch result {
                case .success(let response):
                    if response.success, let habitation = response.data {
                        continuation.resume(returning: habitation)
                    } else {
                        let error = NSError(domain: "HabitationError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: response.message
                        ])
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createLocation(habitationId: String) async throws -> HabitationLocation {
        guard canCreateLocation else {
            throw NSError(domain: "LocationError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Location details are incomplete"
            ])
        }
        
        let request = CreateLocationRequest(
            habitation: habitationId,
            addressNo: addressNo,
            addressLine01: addressLine01,
            addressLine02: addressLine02,
            city: city,
            district: selectedDistrict.rawValue,
            latitude: latitude,
            longitude: longitude,
            nearestHabitationLatitude: nearestHabitationLatitude,
            nearestHabitationLongitude: nearestHabitationLongitude
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.request(
                endpoint: .createLocation,
                body: request,
                responseType: CreateLocationResponse.self
            ) { result in
                switch result {
                case .success(let response):
                    if response.success, let location = response.data {
                        continuation.resume(returning: location)
                    } else {
                        let error = NSError(domain: "LocationError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: response.message
                        ])
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createHabitationFeatures(habitationId: String) async throws -> HabitationFeature {
        guard canCreateFeatures else {
            throw NSError(domain: "FeaturesError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Feature details are invalid"
            ])
        }
        
        let request = CreateHabitationFeatureRequest(
            habitation: habitationId,
            sqft: sqft,
            familyType: selectedFamilyType.rawValue,
            windowsCount: windowsCount,
            smallBedCount: smallBedCount,
            largeBedCount: largeBedCount,
            chairCount: chairCount,
            tableCount: tableCount,
            isElectricityAvailable: isElectricityAvailable,
            isWachineMachineAvailable: isWashingMachineAvailable,
            isWaterAvailable: isWaterAvailable
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.request(
                endpoint: .createHabitationFeature(habitationId: habitationId),
                body: request,
                responseType: CreateHabitationFeatureResponse.self
            ) { result in
                switch result {
                case .success(let response):
                    if response.success, let features = response.data {
                        continuation.resume(returning: features)
                    } else {
                        let error = NSError(domain: "FeaturesError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: response.message
                        ])
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Individual Creation Methods (for step-by-step creation)
    func createHabitationOnly() async {
        guard let userId = authViewModel.currentUser?.id else {
            showAlert(.error("User not authenticated"))
            return
        }
        
        guard canCreateHabitation else {
            showAlert(.error("Please fill in all required habitation details"))
            return
        }
        
        setLoading(true)
        creationProgress = .creatingHabitation
        
        do {
            let habitation = try await createHabitation(userId: userId)
            let completeHabitation = CompleteHabitation(
                id: habitation.id,
                habitation: habitation,
                location: nil,
                features: nil
            )
            
            createdHabitation = completeHabitation
            creationProgress = .habitationCreated
            showAlert(.success("Habitation created successfully!"))
            
        } catch {
            creationProgress = .failed
            handleError(error)
        }
        
        setLoading(false)
    }
    
    func addLocationToHabitation(habitationId: String) async {
        guard canCreateLocation else {
            showAlert(.error("Please fill in all required location details"))
            return
        }
        
        setLoading(true)
        creationProgress = .creatingLocation
        
        do {
            let location = try await createLocation(habitationId: habitationId)
            
            // Update the existing habitation
            if let index = habitations.firstIndex(where: { $0.id == habitationId }) {
                let updatedHabitation = CompleteHabitation(
                    id: habitations[index].id,
                    habitation: habitations[index].habitation,
                    location: location,
                    features: habitations[index].features
                )
                habitations[index] = updatedHabitation
                createdHabitation = updatedHabitation
            }
            
            creationProgress = .locationCreated
            showAlert(.success("Location added successfully!"))
            
        } catch {
            creationProgress = .failed
            handleError(error)
        }
        
        setLoading(false)
    }
    
    func addFeaturesToHabitation(habitationId: String) async {
        guard canCreateFeatures else {
            showAlert(.error("Please fill in all required feature details"))
            return
        }
        
        setLoading(true)
        creationProgress = .creatingFeatures
        
        do {
            let features = try await createHabitationFeatures(habitationId: habitationId)
            
            // Update the existing habitation
            if let index = habitations.firstIndex(where: { $0.id == habitationId }) {
                let updatedHabitation = CompleteHabitation(
                    id: habitations[index].id,
                    habitation: habitations[index].habitation,
                    location: habitations[index].location,
                    features: features
                )
                habitations[index] = updatedHabitation
                createdHabitation = updatedHabitation
            }
            
            creationProgress = .featuresCreated
            showAlert(.success("Features added successfully!"))
            
        } catch {
            creationProgress = .failed
            handleError(error)
        }
        
        setLoading(false)
    }
    
    // MARK: - Helper Methods
    private func handleError(_ error: Error) {
        let message = ErrorHandler.getErrorMessage(for: error)
        showAlert(.error(message))
    }
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearAlert()
        }
    }
    
    func showAlert(_ alert: AlertMessage) {
        alertMessage = alert
        
        if alert.type == .success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.alertMessage?.message == alert.message {
                    self.clearAlert()
                }
            }
        }
    }
    
    func clearAlert() {
        alertMessage = nil
    }
    
    func resetForm() {
        habitationName = ""
        habitationDescription = ""
        selectedHabitationType = .singleRoom
        isReserved = false
        
        addressNo = ""
        addressLine01 = ""
        addressLine02 = ""
        city = ""
        selectedDistrict = .colombo
        latitude = 6.9271
        longitude = 79.8612
        nearestHabitationLatitude = 6.9300
        nearestHabitationLongitude = 79.8650
        
        sqft = 1500
        selectedFamilyType = .oneStory
        windowsCount = 8
        smallBedCount = 0
        largeBedCount = 1
        chairCount = 6
        tableCount = 2
        isElectricityAvailable = true
        isWashingMachineAvailable = true
        isWaterAvailable = true
        
        creationProgress = .idle
    }
    
    func resetProgress() {
        creationProgress = .idle
    }
}

// MARK: - Creation Progress Enum
enum HabitationCreationProgress {
    case idle
    case creatingHabitation
    case habitationCreated
    case creatingLocation
    case locationCreated
    case creatingFeatures
    case featuresCreated
    case completed
    case failed
    
    var description: String {
        switch self {
        case .idle:
            return "Ready to create"
        case .creatingHabitation:
            return "Creating habitation..."
        case .habitationCreated:
            return "Habitation created"
        case .creatingLocation:
            return "Adding location..."
        case .locationCreated:
            return "Location added"
        case .creatingFeatures:
            return "Adding features..."
        case .featuresCreated:
            return "Features added"
        case .completed:
            return "Completed successfully"
        case .failed:
            return "Creation failed"
        }
    }
    
    var isInProgress: Bool {
        switch self {
        case .creatingHabitation, .creatingLocation, .creatingFeatures:
            return true
        default:
            return false
        }
    }
    
    var isCompleted: Bool {
        self == .completed
    }
    
    var isFailed: Bool {
        self == .failed
    }
}
