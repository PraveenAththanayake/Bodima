import Foundation

@MainActor
class HabitationViewModel: ObservableObject {
    @Published var habitations: [HabitationData] = []
    @Published var selectedHabitation: HabitationData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    @Published var isCreatingHabitation = false
    @Published var habitationCreationSuccess = false
    @Published var habitationCreationMessage: String?
    @Published var createdHabitation: HabitationData?
    
    @Published var isFetchingHabitations = false
    @Published var fetchHabitationsError: String?
    
    @Published var isFetchingSingleHabitation = false
    @Published var fetchSingleHabitationError: String?
    
    private let networkManager = NetworkManager.shared
    
    func createHabitation(
        profileUserId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false
    ) {
        guard !profileUserId.isEmpty else {
            showHabitationCreationError("User ID is required")
            return
        }
        
        guard !name.isEmpty else {
            showHabitationCreationError("Habitation name is required")
            return
        }
        
        guard !description.isEmpty else {
            showHabitationCreationError("Description is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showHabitationCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingHabitation = true
        clearHabitationCreationError()
        
        let createHabitationRequest = CreateHabitationRequest(
            user: profileUserId,
            name: name,
            description: description,
            type: type.rawValue,
            isReserved: isReserved
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .createHabitation,
            body: createHabitationRequest,
            headers: headers,
            responseType: CreateHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingHabitation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateHabitation success: \(response.success)")
                    print("🔍 DEBUG - CreateHabitation message: \(response.message)")
                    print("🔍 DEBUG - CreateHabitation data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.habitationCreationSuccess = true
                        self?.habitationCreationMessage = response.message
                        self?.createdHabitation = response.data
                        print("✅ Habitation created successfully")
                        
                        if let newHabitation = response.data {
                            self?.habitations.append(newHabitation)
                        }
                    } else {
                        self?.showHabitationCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create habitation error: \(error)")
                    self?.handleHabitationCreationError(error)
                }
            }
        }
    }
    
    func fetchAllHabitations() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingHabitations = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitations,
            headers: headers,
            responseType: GetHabitationsResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingHabitations = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetHabitations success: \(response.success)")
                    print("🔍 DEBUG - GetHabitations data count: \(response.data?.count ?? 0)")
                    
                    if response.success {
                        self?.habitations = response.data ?? []
                        print("✅ Habitations fetched successfully: \(self?.habitations.count ?? 0) items")
                    } else {
                        self?.showError(response.message ?? "Failed to fetch habitations")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch habitations error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    func fetchHabitationById(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingSingleHabitation = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitationById(habitationId: habitationId),
            headers: headers,
            responseType: GetHabitationByIdResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingSingleHabitation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetHabitationById success: \(response.success)")
                    print("🔍 DEBUG - GetHabitationById data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.selectedHabitation = response.data
                        print("✅ Habitation fetched successfully by ID")
                    } else {
                        self?.showError(response.message ?? "Failed to fetch habitation")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch habitation by ID error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
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
    
    func filterHabitationsByType(_ type: HabitationType) -> [HabitationData] {
        return habitations.filter { $0.type == type.rawValue }
    }
    
    func filterAvailableHabitations() -> [HabitationData] {
        return habitations.filter { !$0.isReserved }
    }
    
    func filterReservedHabitations() -> [HabitationData] {
        return habitations.filter { $0.isReserved }
    }
    
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
    
    var habitationCount: Int {
        return habitations.count
    }
    
    var availableHabitationCount: Int {
        return filterAvailableHabitations().count
    }
    
    var reservedHabitationCount: Int {
        return filterReservedHabitations().count
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
    
    func clearHabitations() {
        habitations.removeAll()
        selectedHabitation = nil
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
    }
}

extension HabitationViewModel {
    
    func createHabitationWithCurrentUser(
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false
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
                isReserved: isReserved
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
}
