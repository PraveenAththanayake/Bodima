import Foundation

@MainActor
class HabitationViewModel: ObservableObject {
    // MARK: - Published Properties for Original Models
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
    
    // MARK: - Published Properties for Enhanced Models
    @Published var enhancedHabitations: [EnhancedHabitationData] = []
    @Published var selectedEnhancedHabitation: EnhancedHabitationData?
    @Published var isFetchingEnhancedHabitations = false
    @Published var isFetchingEnhancedSingleHabitation = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Original Methods (UNCHANGED)
    
    // MARK: - Update and Delete Methods
    
    func updateHabitation(
        habitationId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false,
        price: Int
    ) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard !name.isEmpty else {
            showError("Habitation name is required")
            return
        }
        
        guard !description.isEmpty else {
            showError("Description is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isLoading = true
        clearError()
        
        // Get the current user ID
        var userId = ""
        if let currentUserId = AuthViewModel.shared.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") {
            userId = currentUserId
        }
        
        let updateHabitationRequest = CreateHabitationRequest(
            user: userId, // Include the user ID for update
            name: name,
            description: description,
            type: type.rawValue,
            isReserved: isReserved,
            price: price
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .updateHabitation(habitationId: habitationId),
            body: updateHabitationRequest,
            headers: headers,
            responseType: CreateHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - UpdateHabitation success: \(response.success)")
                    print("🔍 DEBUG - UpdateHabitation message: \(response.message)")
                    
                    if response.success {
                        // Update the habitation in the arrays
                        if let updatedHabitation = response.data {
                            // Update in habitations array
                            if let index = self?.habitations.firstIndex(where: { $0.id == habitationId }) {
                                self?.habitations[index] = updatedHabitation
                            }
                            
                            // Refresh enhanced habitations
                            self?.fetchAllEnhancedHabitations()
                            
                            // Update selected habitation if it's the one being edited
                            if self?.selectedHabitation?.id == habitationId {
                                self?.selectedHabitation = updatedHabitation
                            }
                        }
                        
                        self?.showSuccess(message: "Habitation updated successfully")
                    } else {
                        self?.showError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Update habitation error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    func deleteHabitation(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
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
            endpoint: .deleteHabitation(habitationId: habitationId),
            headers: headers,
            responseType: DeleteHabitationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - DeleteHabitation success: \(response.success)")
                    print("🔍 DEBUG - DeleteHabitation message: \(response.message)")
                    
                    if response.success {
                        // Remove the habitation from the arrays
                        self?.habitations.removeAll { $0.id == habitationId }
                        self?.enhancedHabitations.removeAll { $0.id == habitationId }
                        
                        // Reset selected habitation if it's the one being deleted
                        if self?.selectedHabitation?.id == habitationId {
                            self?.selectedHabitation = nil
                        }
                        
                        if self?.selectedEnhancedHabitation?.id == habitationId {
                            self?.selectedEnhancedHabitation = nil
                        }
                        
                        self?.showSuccess(message: "Habitation deleted successfully")
                    } else {
                        self?.showError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Delete habitation error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    func createHabitation(
        profileUserId: String,
        name: String,
        description: String,
        type: HabitationType,
        isReserved: Bool = false,
        price: Int
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
            isReserved: isReserved,
            price: price
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
                            // Trigger notification for new habitation
                            self?.triggerHabitationCreatedNotification(habitationName: newHabitation.name)
                        }
                        
                        // Refresh enhanced habitations after creating new one
                        self?.fetchAllEnhancedHabitations()
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
    
    // MARK: - New Enhanced Methods
    
    func fetchAllEnhancedHabitations() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingEnhancedHabitations = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getHabitations,
            headers: headers,
            responseType: GetEnhancedHabitationsResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingEnhancedHabitations = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetEnhancedHabitations success: \(response.success)")
                    print("🔍 DEBUG - GetEnhancedHabitations data count: \(response.data?.count ?? 0)")
                    
                    if response.success {
                        self?.enhancedHabitations = response.data ?? []
                        print("✅ Enhanced Habitations fetched successfully: \(self?.enhancedHabitations.count ?? 0) items")
                        
                        // Debug: Print enhanced habitation details
                        self?.enhancedHabitations.forEach { habitation in
                            print("📍 Enhanced Habitation: \(habitation.name) - Type: \(habitation.type)")
                            print("   User: \(habitation.userFullName)")
                            if let user = habitation.user {
                                print("   City: \(user.city), District: \(user.district)")
                            } else {
                                print("   City: Unknown, District: Unknown")
                            }
                            print("   Pictures: \(habitation.pictures?.count ?? 0)")
                            print("   Reserved: \(habitation.isReserved)")
                            print("   Price: \(habitation.price)")
                        }
                    } else {
                        self?.showError(response.message ?? "Failed to fetch enhanced habitations")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch enhanced habitations error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
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
                                print("   City: \(user.city), District: \(user.district)")
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
            guard let user = habitation.user else { return false }
            return user.city.lowercased().contains(city.lowercased())
        }
    }
    
    func filterEnhancedHabitationsByDistrict(_ district: String) -> [EnhancedHabitationData] {
        return enhancedHabitations.filter { habitation in
            guard let user = habitation.user else { return false }
            return user.district.lowercased().contains(district.lowercased())
        }
    }
    
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
            let userMatch = habitation.user?.city.lowercased().contains(lowercasedQuery) == true ||
                          habitation.user?.district.lowercased().contains(lowercasedQuery) == true
            
            return basicMatch || userMatch
        }
    }
    
    func getEnhancedHabitationsByLocation(city: String? = nil, district: String? = nil) -> [EnhancedHabitationData] {
        var filteredHabitations = enhancedHabitations
        
        if let city = city, !city.isEmpty {
            filteredHabitations = filteredHabitations.filter { habitation in
                guard let user = habitation.user else { return false }
                return user.city.lowercased().contains(city.lowercased())
            }
        }
        
        if let district = district, !district.isEmpty {
            filteredHabitations = filteredHabitations.filter { habitation in
                guard let user = habitation.user else { return false }
                return user.district.lowercased().contains(district.lowercased())
            }
        }
        
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
        let cities = Set(enhancedHabitations.compactMap { $0.user?.city })
        return Array(cities).sorted()
    }
    
    var uniqueDistricts: [String] {
        let districts = Set(enhancedHabitations.compactMap { $0.user?.district })
        return Array(districts).sorted()
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
}
