import Foundation

// MARK: - Reservation Models

struct ReservationData: Codable, Identifiable {
    let id: String
    let user: String
    let habitation: String
    let reservedDateTime: String
    let reservationEndDateTime: String
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case habitation
        case reservedDateTime
        case reservationEndDateTime
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

struct EnhancedReservationData: Codable, Identifiable {
    let id: String
    let user: ReservationUserData
    let habitation: ReservationHabitationData
    let reservedDateTime: String
    let reservationEndDateTime: String
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case habitation
        case reservedDateTime
        case reservationEndDateTime
        case createdAt
        case updatedAt
        case v = "__v"
    }
    
    // Computed properties for easy access
    var userFullName: String {
        return "\(user.firstName) \(user.lastName)"
    }
    
    var userPhoneNumber: String {
        return user.phoneNumber
    }
    
    var userFullAddress: String {
        return "\(user.addressNo), \(user.addressLine1), \(user.addressLine2), \(user.city), \(user.district)"
    }
    
    var habitationName: String {
        return habitation.name
    }
    
    var habitationDescription: String {
        return habitation.description
    }
    
    var habitationPrice: Int {
        return habitation.price
    }
    
    var habitationType: String {
        return habitation.type
    }
    
    var isHabitationReserved: Bool {
        return habitation.isReserved
    }
    
    var reservationDuration: TimeInterval {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = formatter.date(from: reservedDateTime),
              let endDate = formatter.date(from: reservationEndDateTime) else {
            return 0
        }
        
        return endDate.timeIntervalSince(startDate)
    }
    
    var reservationDurationInDays: Int {
        return Int(reservationDuration / (24 * 60 * 60))
    }
}

struct ReservationUserData: Codable, Identifiable {
    let id: String
    let auth: String
    let firstName: String
    let lastName: String
    let bio: String
    let phoneNumber: String
    let addressNo: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let district: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case auth
        case firstName
        case lastName
        case bio
        case phoneNumber
        case addressNo
        case addressLine1
        case addressLine2
        case city
        case district
        case createdAt
        case updatedAt
    }
}

struct ReservationHabitationData: Codable, Identifiable {
    let id: String
    let user: String
    let name: String
    let description: String
    let price: Int
    let type: String
    let isReserved: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case name
        case description
        case price
        case type
        case isReserved
        case createdAt
        case updatedAt
    }
}

// MARK: - Request Models

struct CreateReservationRequest: Codable {
    let user: String
    let habitation: String
    let reservedDateTime: String
    let reservationEndDateTime: String
}

// MARK: - Response Models

struct CreateReservationResponse: Codable {
    let success: Bool
    let message: String
    let data: ReservationData?
}

struct GetReservationResponse: Codable {
    let success: Bool?
    let data: EnhancedReservationData?
    let message: String?
}

// MARK: - Reservation ViewModel

@MainActor
class ReservationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var reservations: [ReservationData] = []
    @Published var enhancedReservations: [EnhancedReservationData] = []
    @Published var selectedReservation: EnhancedReservationData?
    
    @Published var isCreatingReservation = false
    @Published var reservationCreationSuccess = false
    @Published var reservationCreationMessage: String?
    @Published var createdReservation: ReservationData?
    
    @Published var isFetchingReservation = false
    @Published var fetchReservationError: String?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Create Reservation
    
    func createReservation(
        userId: String,
        habitationId: String,
        reservedDateTime: Date,
        reservationEndDateTime: Date
    ) {
        guard !userId.isEmpty else {
            showReservationCreationError("User ID is required")
            return
        }
        
        guard !habitationId.isEmpty else {
            showReservationCreationError("Habitation ID is required")
            return
        }
        
        guard reservationEndDateTime > reservedDateTime else {
            showReservationCreationError("End date must be after start date")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showReservationCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingReservation = true
        clearReservationCreationError()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createReservationRequest = CreateReservationRequest(
            user: userId,
            habitation: habitationId,
            reservedDateTime: formatter.string(from: reservedDateTime),
            reservationEndDateTime: formatter.string(from: reservationEndDateTime)
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .createReservation,
            body: createReservationRequest,
            headers: headers,
            responseType: CreateReservationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingReservation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateReservation success: \(response.success)")
                    print("🔍 DEBUG - CreateReservation message: \(response.message)")
                    print("🔍 DEBUG - CreateReservation data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.reservationCreationSuccess = true
                        self?.reservationCreationMessage = response.message
                        self?.createdReservation = response.data
                        print("✅ Reservation created successfully")
                        
                        if let newReservation = response.data {
                            self?.reservations.append(newReservation)
                        }
                    } else {
                        self?.showReservationCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create reservation error: \(error)")
                    self?.handleReservationCreationError(error)
                }
            }
        }
    }
    
    func createReservationWithDateStrings(
        userId: String,
        habitationId: String,
        reservedDateTimeString: String,
        reservationEndDateTimeString: String
    ) {
        guard !userId.isEmpty else {
            showReservationCreationError("User ID is required")
            return
        }
        
        guard !habitationId.isEmpty else {
            showReservationCreationError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showReservationCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingReservation = true
        clearReservationCreationError()
        
        let createReservationRequest = CreateReservationRequest(
            user: userId,
            habitation: habitationId,
            reservedDateTime: reservedDateTimeString,
            reservationEndDateTime: reservationEndDateTimeString
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .createReservation,
            body: createReservationRequest,
            headers: headers,
            responseType: CreateReservationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingReservation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateReservation success: \(response.success)")
                    print("🔍 DEBUG - CreateReservation message: \(response.message)")
                    print("🔍 DEBUG - CreateReservation data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.reservationCreationSuccess = true
                        self?.reservationCreationMessage = response.message
                        self?.createdReservation = response.data
                        print("✅ Reservation created successfully")
                        
                        if let newReservation = response.data {
                            self?.reservations.append(newReservation)
                        }
                    } else {
                        self?.showReservationCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create reservation error: \(error)")
                    self?.handleReservationCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Get Reservation
    
    func getReservation(reservationId: String) {
        guard !reservationId.isEmpty else {
            showError("Reservation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingReservation = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getReservation(reservationId: reservationId),
            headers: headers,
            responseType: GetReservationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingReservation = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetReservation success: \(response.success ?? false)")
                    print("🔍 DEBUG - GetReservation data: \(String(describing: response.data))")
                    
                    if response.success == true {
                        self?.selectedReservation = response.data
                        print("✅ Reservation fetched successfully")
                        
                        if let reservation = response.data {
                            print("📍 Reservation Details:")
                            print("   ID: \(reservation.id)")
                            print("   User: \(reservation.userFullName)")
                            print("   Habitation: \(reservation.habitationName)")
                            print("   Start Date: \(reservation.reservedDateTime)")
                            print("   End Date: \(reservation.reservationEndDateTime)")
                            print("   Duration: \(reservation.reservationDurationInDays) days")
                            print("   Price: \(reservation.habitationPrice)")
                            
                            // Add to enhanced reservations if not already present
                            if let strongSelf = self, !strongSelf.enhancedReservations.contains(where: { $0.id == reservation.id }) {
                                strongSelf.enhancedReservations.append(reservation)
                            }
                        }
                    } else {
                        self?.showError(response.message ?? "Failed to fetch reservation")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Get reservation error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Filter Methods
    
    func filterReservationsByUser(userId: String) -> [EnhancedReservationData] {
        return enhancedReservations.filter { $0.user.id == userId }
    }
    
    func filterReservationsByHabitation(habitationId: String) -> [EnhancedReservationData] {
        return enhancedReservations.filter { $0.habitation.id == habitationId }
    }
    
    func filterReservationsByDateRange(startDate: Date, endDate: Date) -> [EnhancedReservationData] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return enhancedReservations.filter { reservation in
            guard let reservationStart = formatter.date(from: reservation.reservedDateTime) else { return false }
            return reservationStart >= startDate && reservationStart <= endDate
        }
    }
    
    func filterActiveReservations() -> [EnhancedReservationData] {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return enhancedReservations.filter { reservation in
            guard let startDate = formatter.date(from: reservation.reservedDateTime),
                  let endDate = formatter.date(from: reservation.reservationEndDateTime) else { return false }
            return now >= startDate && now <= endDate
        }
    }
    
    func filterUpcomingReservations() -> [EnhancedReservationData] {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return enhancedReservations.filter { reservation in
            guard let startDate = formatter.date(from: reservation.reservedDateTime) else { return false }
            return startDate > now
        }
    }
    
    func filterPastReservations() -> [EnhancedReservationData] {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return enhancedReservations.filter { reservation in
            guard let endDate = formatter.date(from: reservation.reservationEndDateTime) else { return false }
            return endDate < now
        }
    }
    
    // MARK: - Computed Properties
    
    var reservationCount: Int {
        return enhancedReservations.count
    }
    
    var activeReservationCount: Int {
        return filterActiveReservations().count
    }
    
    var upcomingReservationCount: Int {
        return filterUpcomingReservations().count
    }
    
    var pastReservationCount: Int {
        return filterPastReservations().count
    }
    
    // MARK: - Helper Methods
    
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
    
    private func handleReservationCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showReservationCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showReservationCreationError(message)
                
            case .serverError(let message):
                showReservationCreationError("Server error: \(message)")
                
            default:
                showReservationCreationError(networkError.localizedDescription)
            }
        } else {
            showReservationCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Reservation Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    func showReservationCreationError(_ message: String) {
        reservationCreationMessage = message
        reservationCreationSuccess = false
        print("❌ Reservation Creation Error: \(message)")
    }
    
    private func clearReservationCreationError() {
        reservationCreationMessage = nil
        reservationCreationSuccess = false
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
    
    func formatDateRange(startDate: String, endDate: String) -> String {
        let startFormatted = formatDate(startDate)
        let endFormatted = formatDate(endDate)
        return "\(startFormatted) - \(endFormatted)"
    }
    
    func clearReservations() {
        reservations.removeAll()
        enhancedReservations.removeAll()
        selectedReservation = nil
        clearError()
        clearReservationCreationError()
    }
    
    func resetReservationCreationState() {
        isCreatingReservation = false
        reservationCreationSuccess = false
        reservationCreationMessage = nil
        createdReservation = nil
    }
    
    func resetSelectedReservation() {
        selectedReservation = nil
    }
}

// MARK: - Extensions

extension ReservationViewModel {
    
    func createReservationWithCurrentUser(
        habitationId: String,
        reservedDateTime: Date,
        reservationEndDateTime: Date
    ) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showReservationCreationError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.createReservation(
                userId: userId,
                habitationId: habitationId,
                reservedDateTime: reservedDateTime,
                reservationEndDateTime: reservationEndDateTime
            )
        }
    }
    
    func createReservationWithCurrentUserAndDateStrings(
        habitationId: String,
        reservedDateTimeString: String,
        reservationEndDateTimeString: String
    ) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId else {
                self?.showReservationCreationError("User profile not found. Please complete your profile first.")
                return
            }
            
            self?.createReservationWithDateStrings(
                userId: userId,
                habitationId: habitationId,
                reservedDateTimeString: reservedDateTimeString,
                reservationEndDateTimeString: reservationEndDateTimeString
            )
        }
    }
    
    func getReservationsForCurrentUser(completion: @escaping ([EnhancedReservationData]) -> Void) {
        getUserIdFromProfile { [weak self] userId in
            guard let userId = userId, let self = self else {
                completion([])
                return
            }
            
            let userReservations = self.filterReservationsByUser(userId: userId)
            completion(userReservations)
        }
    }
}
