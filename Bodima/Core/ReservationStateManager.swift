import SwiftUI
import Foundation

// MARK: - Reservation State Manager
@MainActor
class ReservationStateManager: ObservableObject {
    static let shared = ReservationStateManager()
    
    @Published var currentReservationData: PendingReservationData?
    @Published var isReservationInProgress = false
    
    private init() {}
    
    // MARK: - State Management
    func startReservationFlow(
        habitation: EnhancedHabitationData,
        locationData: LocationData?,
        featureData: HabitationFeatureData?
    ) {
        currentReservationData = PendingReservationData(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )
        isReservationInProgress = true
    }
    
    func updateReservationDates(checkInDate: Date, checkOutDate: Date) {
        currentReservationData?.checkInDate = checkInDate
        currentReservationData?.checkOutDate = checkOutDate
    }
    
    func updatePaymentMethod(paymentCard: PaymentCard) {
        currentReservationData?.selectedPaymentCard = paymentCard
    }
    
    func clearReservationData() {
        print("🔍 DEBUG - Clearing reservation data")
        currentReservationData = nil
        isReservationInProgress = false
    }
    
    // MARK: - Validation Methods
    func validateReservationData() -> (isValid: Bool, errorMessage: String?) {
        guard let data = currentReservationData else {
            return (false, "No reservation data found")
        }
        
        // Validate dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let checkInDay = calendar.startOfDay(for: data.checkInDate)
        let checkOutDay = calendar.startOfDay(for: data.checkOutDate)
        
        if checkOutDay <= checkInDay {
            return (false, "Check-out date must be after check-in date")
        }
        
        if checkInDay < today {
            return (false, "Check-in date cannot be in the past")
        }
        
        // Validate minimum stay (at least 1 day)
        let daysDifference = calendar.dateComponents([.day], from: checkInDay, to: checkOutDay).day ?? 0
        if daysDifference < 1 {
            return (false, "Minimum stay is 1 day")
        }
        
        // Validate payment method
        if data.selectedPaymentCard == nil {
            return (false, "Please select a payment method")
        }
        
        return (true, nil)
    }
    
    // MARK: - Final Reservation Creation
    func finalizeReservation(completion: @escaping (Bool, String?) -> Void) {
        // Validate all reservation data first
        let validation = validateReservationData()
        if !validation.isValid {
            completion(false, validation.errorMessage)
            return
        }
        
        guard let reservationData = currentReservationData else {
            completion(false, "No reservation data found")
            return
        }
        
        guard let userProfileId = getUserProfileId() else {
            completion(false, "Unable to retrieve user profile")
            return
        }
        
        print("🔍 DEBUG - Starting reservation finalization process")
        print("🔍 DEBUG - Habitation ID: \(reservationData.habitation.id)")
        print("🔍 DEBUG - User ID: \(userProfileId)")
        print("🔍 DEBUG - Check-in: \(reservationData.checkInDate)")
        print("🔍 DEBUG - Check-out: \(reservationData.checkOutDate)")
        
        // Create the reservation with all collected data
        Task { @MainActor in
            let reservationViewModel = ReservationViewModel()
            
            let reservationSuccess = await withCheckedContinuation { continuation in
                reservationViewModel.createReservation(
                    userId: userProfileId,
                    habitationId: reservationData.habitation.id,
                    checkInDate: reservationData.checkInDate,
                    checkOutDate: reservationData.checkOutDate,
                    startDate: reservationData.checkInDate,
                    endDate: reservationData.checkOutDate
                ) { success in
                    continuation.resume(returning: success)
                }
            }
            
            if reservationSuccess {
                if let reservationId = reservationViewModel.reservationId {
                    print("🔍 DEBUG - Reservation created successfully with ID: \(reservationId)")
                    await self.processPayment(
                        reservationId: reservationId,
                        reservationData: reservationData,
                        completion: completion
                    )
                } else {
                    print("🔍 DEBUG - Failed to get reservation ID")
                    completion(false, "Failed to get reservation ID")
                }
            } else {
                print("🔍 DEBUG - Reservation creation failed: \(reservationViewModel.errorMessage ?? "Unknown error")")
                completion(false, reservationViewModel.errorMessage ?? "Failed to create reservation")
            }
        }
    }
    
    // MARK: - Payment Processing
    private func processPayment(
        reservationId: String,
        reservationData: PendingReservationData,
        completion: @escaping (Bool, String?) -> Void
    ) async {
        print("🔍 DEBUG - Starting payment processing for reservation: \(reservationId)")
        
        let paymentViewModel = PaymentViewModel()
        
        let paymentSuccess = await withCheckedContinuation { continuation in
            paymentViewModel.createPayment(
                habitationOwnerId: reservationData.habitation.user?.id ?? "unknown_owner",
                reservationId: reservationId,
                amount: Double(reservationData.habitation.price)
            ) { success in
                continuation.resume(returning: success)
            }
        }
        
        if paymentSuccess {
            print("🔍 DEBUG - Payment successful, confirming reservation")
            let reservationViewModel = ReservationViewModel()
            
            let confirmSuccess = await withCheckedContinuation { continuation in
                reservationViewModel.confirmReservation(reservationId: reservationId) { success in
                    continuation.resume(returning: success)
                }
            }
            
            if confirmSuccess {
                print("🔍 DEBUG - Reservation confirmed successfully")
                await MainActor.run {
                    self.clearReservationData()
                }
                completion(true, "Reservation completed successfully!")
            } else {
                print("🔍 DEBUG - Reservation confirmation failed")
                completion(false, "Payment completed but reservation confirmation failed")
            }
        } else {
            print("🔍 DEBUG - Payment failed: \(paymentViewModel.errorMessage ?? "Unknown error")")
            completion(false, paymentViewModel.errorMessage ?? "Payment failed")
        }
    }
    
    private func getUserProfileId() -> String? {
        return AuthViewModel.shared.currentUser?.id
    }
}

// MARK: - Pending Reservation Data Model
class PendingReservationData: ObservableObject {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    
    @Published var checkInDate: Date
    @Published var checkOutDate: Date
    @Published var selectedPaymentCard: PaymentCard?
    @Published var calendarEventCreated: Bool = false
    
    init(
        habitation: EnhancedHabitationData,
        locationData: LocationData?,
        featureData: HabitationFeatureData?
    ) {
        self.habitation = habitation
        self.locationData = locationData
        self.featureData = featureData
        self.checkInDate = Date()
        self.checkOutDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
    }
    
    var totalAmount: Double {
        return Double(habitation.price)
    }
    
    var propertyTitle: String {
        return habitation.name
    }
    
    var propertyAddress: String {
        if let locationData = locationData {
            return locationData.shortAddress ??
            "\(locationData.addressNo ?? ""), \(locationData.city ?? ""), \(locationData.district ?? "")"
        }
        return "Address not available"
    }
    
    var propertyImageURL: String? {
        return habitation.mainPictureUrl
    }
}
