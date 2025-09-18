import SwiftUI
import Foundation

// Main payment view controller managing the payment confirmation flow
// Orchestrates modular components and handles payment processing
// Maintains reservation state through ReservationStateManager
struct PaymentView: View {
    // Payment state management
    @State private var selectedCard: PaymentCard?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var shouldNavigateToHome = false
    @State private var isProcessingPayment = false
    
    // Centralized state management for reservation flow
    @StateObject private var reservationStateManager = ReservationStateManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Mock payment cards for demonstration purposes
    // In production, these would be fetched from a secure payment service
    private let paymentCards = [
        PaymentCard(type: .visa, cardNumber: "1234567890123456", holderName: "John Doe"),
        PaymentCard(type: .mastercard, cardNumber: "9876543210987654", holderName: "Jane Smith"),
        PaymentCard(type: .visa, cardNumber: "1111222233334444", holderName: "Alex Johnson")
    ]
    
    // Computed properties for clean data access from reservation state
    private var reservationData: PendingReservationData? {
        return reservationStateManager.currentReservationData
    }
    
    private var totalAmount: Double {
        return reservationData?.totalAmount ?? 0.0
    }
    
    private var propertyTitle: String {
        return reservationData?.propertyTitle ?? "Property"
    }
    
    private var propertyAddress: String {
        return reservationData?.propertyAddress ?? "Address not available"
    }
    
    // Main view body orchestrating modular components
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with navigation and payment context
                    PaymentHeaderComponent(onBackTapped: {
                        dismiss()
                    })
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Payment method selection interface
                    PaymentMethodComponent(
                        paymentCards: paymentCards,
                        selectedCard: selectedCard,
                        onCardSelected: { card in
                            selectedCard = card
                            reservationStateManager.updatePaymentMethod(paymentCard: card)
                        }
                    )
                    
                    // Payment summary and total amount
                    PaymentSummaryComponent(totalAmount: totalAmount)
                        .padding(.horizontal, 16)
                    
                    // Payment action button with processing state
                    PaymentActionButtonsComponent(
                        selectedCard: selectedCard,
                        isProcessingPayment: isProcessingPayment,
                        onPayAction: handlePayment
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .onAppear {
                // Validate reservation state on view appearance
                if reservationStateManager.currentReservationData == nil {
                    dismiss()
                }
            }
            .onChange(of: shouldNavigateToHome) { navigate in
                if navigate {
                    dismiss()
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        reservationStateManager.clearReservationData()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Payment processing and validation functions
    // Handles payment flow with comprehensive validation and error handling
    private func handlePayment() {
        guard let selectedCard = selectedCard else {
            showAlert(title: "Error", message: "Please select a payment method")
            return
        }
        
        reservationStateManager.updatePaymentMethod(paymentCard: selectedCard)
        
        let validation = reservationStateManager.validateReservationData()
        if !validation.isValid {
            showAlert(title: "Validation Error", message: validation.errorMessage ?? "Please check your reservation details")
            return
        }
        
        // Begin biometric authentication prior to finalizing payment
        isProcessingPayment = true
        let amountText = String(format: "LKR %.2f", totalAmount)
        Task { @MainActor in
            let authenticated = await BiometricAuthManager.shared.authenticateUser(
                reason: "Confirm payment of \(amountText)"
            )
            guard authenticated else {
                self.isProcessingPayment = false
                showAlert(title: "Authentication Failed", message: "Biometric authentication was not successful. Please try again.")
                return
            }
            
            reservationStateManager.finalizeReservation { [self] success, errorMessage in
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    
                    if success {
                        showAlert(title: "Success", message: "Payment completed and reservation confirmed successfully!")
                    } else {
                        showAlert(title: "Error", message: errorMessage ?? "Reservation failed. Please try again.")
                    }
                }
            }
        }
    }
    
    // Alert display utility for error handling and user feedback
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// Payment card data model with type information and formatting
// Provides card display formatting and type-specific styling
struct PaymentCard: Identifiable {
    let id = UUID()
    let type: CardType
    let cardNumber: String
    let holderName: String
    
    var maskedCardNumber: String {
        let prefix = String(cardNumber.prefix(4))
        let suffix = String(cardNumber.suffix(4))
        return "\(prefix) **** **** \(suffix)"
    }
    
    enum CardType {
        case visa
        case mastercard
        
        var displayName: String {
            switch self {
            case .visa: return "Visa"
            case .mastercard: return "Mastercard"
            }
        }
        
        var iconName: String {
            switch self {
            case .visa: return "creditcard"
            case .mastercard: return "creditcard"
            }
        }
        
        var color: Color {
            switch self {
            case .visa: return .blue
            case .mastercard: return .red
            }
        }
    }
}

