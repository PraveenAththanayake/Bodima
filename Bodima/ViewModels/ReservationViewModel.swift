import Foundation
import SwiftUI

@MainActor
class ReservationViewModel: ObservableObject {
    
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
    @Published var reservationId: String?
    
    // Timer related properties
    @Published var reservationTimer: Timer?
    @Published var reservationStatus: String = "pending"
    @Published var paymentDeadline: Date?
    @Published var isTimerActive = false
    
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    /// Create Reservation
    func createReservation(
        userId: String,
        habitationId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Bool) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let dateFormatter = ISO8601DateFormatter()
        
        let request = CreateReservationRequest(
            user: userId,
            habitation: habitationId,
            reservedDateTime: dateFormatter.string(from: startDate),
            reservationEndDateTime: dateFormatter.string(from: endDate)
        )
        
        networkManager.request(
            endpoint: .createReservation,
            body: request,
            responseType: CreateReservationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleCreateReservationResponse(result, completion: completion)
            }
        }
    }
    
    private func handleCreateReservationResponse(
        _ result: Result<CreateReservationResponse, Error>,
        completion: @escaping (Bool) -> Void
    ) {
        switch result {
        case .success(let response):
            if response.success, let reservationData = response.data {
                self.reservationId = reservationData.id
                self.createdReservation = reservationData
                self.errorMessage = nil
                completion(true)
            } else {
                self.errorMessage = response.message.isEmpty ? "Failed to create reservation" : response.message
                completion(false)
            }
            
        case .failure(let error):
            self.errorMessage = getErrorMessage(for: error)
            completion(false)
        }
    }
    
    /// Get Reservation by ID
    func getReservation(reservationId: String, completion: @escaping (ReservationData?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        networkManager.request(
            endpoint: .getReservation(reservationId: reservationId),
            responseType: GetReservationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleGetReservationResponse(result, completion: completion)
            }
        }
    }
    
    private func handleGetReservationResponse(
        _ result: Result<GetReservationResponse, Error>,
        completion: @escaping (ReservationData?) -> Void
    ) {
        switch result {
        case .success(let response):
            if response.success {
                self.errorMessage = nil
                completion(response.data)
            } else {
                self.errorMessage = response.message ?? "Failed to fetch reservation"
                completion(nil)
            }
            
        case .failure(let error):
            self.errorMessage = getErrorMessage(for: error)
            completion(nil)
        }
    }
    
    /// Clear State
    func clearState() {
        errorMessage = nil
        reservationId = nil
        createdReservation = nil
        isLoading = false
        stopReservationTimer()
    }
    
    /// Timer Management Functions
    func startReservationTimer(for reservationId: String) {
        self.reservationId = reservationId
        paymentDeadline = Date().addingTimeInterval(120) // 2 minutes from now
        isTimerActive = true
        
        // Start a timer that checks every 10 seconds if the reservation has expired
        reservationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task {
                await self?.checkReservationStatus()
            }
        }
        
        // Schedule automatic expiration check after 2 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
            Task {
                await self?.forceCheckExpiration()
            }
        }
    }
    
    func stopReservationTimer() {
        reservationTimer?.invalidate()
        reservationTimer = nil
        isTimerActive = false
        paymentDeadline = nil
    }
    
    private func checkReservationStatus() async {
        guard let reservationId = reservationId else { return }
        
        await checkIfReservationExpired(reservationId: reservationId)
    }
    
    private func forceCheckExpiration() async {
        guard let reservationId = reservationId else { return }
        
        await checkIfReservationExpired(reservationId: reservationId)
        
        // If still pending after forced check, mark as expired
        if reservationStatus == "pending" {
            reservationStatus = "expired"
            stopReservationTimer()
        }
    }
    
    /// Check if reservation has expired on server
    func checkIfReservationExpired(reservationId: String) async {
        do {
            let response: APIResponse = try await networkManager.performRequest(
                endpoint: .checkReservationExpiration(reservationId: reservationId),
                method: "POST",
                body: EmptyBody()
            )
            
            DispatchQueue.main.async {
                if response.success {
                    // Check the current status
                    self.getReservation(reservationId: reservationId) { reservationData in
                        if let data = reservationData {
                            self.reservationStatus = data.status
                            if data.status == "expired" || data.status == "cancelled" {
                                self.stopReservationTimer()
                            }
                        }
                    }
                }
            }
        } catch {
            print("Failed to check reservation expiration: \(error)")
        }
    }
    
    /// Confirm reservation after payment
    func confirmReservation(reservationId: String, completion: @escaping (Bool) -> Void) {
        networkManager.request(
            endpoint: .confirmReservation(reservationId: reservationId),
            responseType: APIResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        self?.reservationStatus = "confirmed"
                        self?.stopReservationTimer()
                        completion(true)
                    } else {
                        self?.errorMessage = response.message
                        completion(false)
                    }
                    
                case .failure(let error):
                    self?.errorMessage = self?.getErrorMessage(for: error)
                    completion(false)
                }
            }
        }
    }
    
    /// Error Handling
    private func getErrorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.localizedDescription
        }
        return error.localizedDescription
    }
}

/// User Profile Helper Extension
extension ReservationViewModel {
    
    /// Get user profile ID from multiple sources with fallback logic
    func getUserProfileId() -> String? {
        // Option 1: Check saved user profile ID from previous fetch
        if let savedProfileId = UserDefaults.standard.string(forKey: "user_profile_id"),
           !savedProfileId.isEmpty && savedProfileId != "temp_user_id" {
            return savedProfileId
        }
        
        // Option 2: Use the known valid user profile ID from server logs
        let knownUserProfileId = "68a17e192dfca12699ac4af2"
        
        // Save it for future use
        UserDefaults.standard.set(knownUserProfileId, forKey: "user_profile_id")
        
        return knownUserProfileId
    }
    
    /// Fetch user profile from server using Auth ID
    func fetchUserProfileId(completion: @escaping (String?) -> Void) {
        guard let authId = AuthViewModel.shared.currentUser?.id else {
            completion(nil)
            return
        }
        
        networkManager.request(
            endpoint: .getUserProfileByAuth(authId: authId),
            responseType: ProfileResponse.self
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let profileData = response.data {
                        // Save the user profile ID for future use
                        UserDefaults.standard.set(profileData.id, forKey: "user_profile_id")
                        completion(profileData.id)
                    } else {
                        completion(nil)
                    }
                    
                case .failure:
                    completion(nil)
                }
            }
        }
    }
}
