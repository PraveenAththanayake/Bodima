import SwiftUI
import Foundation

struct PaymentView: View {
    @State private var selectedCard: PaymentCard?
    @StateObject private var paymentViewModel = PaymentViewModel()
    @StateObject private var reservationViewModel = ReservationViewModel()
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var shouldNavigateToHome = false
    
    let habitation: EnhancedHabitationData?
    @Environment(\.dismiss) private var dismiss
    
    let totalAmount: Double
    let propertyTitle: String
    let propertyAddress: String
    let reservationId: String
    let habitationOwnerId: String
    
    private let paymentCards = [
        PaymentCard(type: .visa, cardNumber: "1234567890123456", holderName: "John Doe"),
        PaymentCard(type: .mastercard, cardNumber: "9876543210987654", holderName: "Jane Smith"),
        PaymentCard(type: .visa, cardNumber: "1111222233334444", holderName: "Alex Johnson")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Payment Method")
                            .font(.headline.bold())
                            .foregroundStyle(AppColors.foreground)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(paymentCards) { card in
                                PaymentCardRow(
                                    card: card,
                                    isSelected: selectedCard?.id == card.id
                                ) {
                                    selectedCard = card
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    totalAmountCard
                        .padding(.horizontal, 16)
                    
                    payButton
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .onAppear {
                // Monitor reservation status for expiration
                checkReservationStatus()
            }
            .onChange(of: shouldNavigateToHome) { navigate in
                if navigate {
                    dismiss()
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Complete your payment")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.foreground)
                    .frame(width: 44, height: 44)
                    .background(AppColors.input)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }
    
    
    private var totalAmountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Summary")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Monthly Rent")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                    Spacer()
                    Text("LKR \(String(format: "%.2f", totalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Divider()
                    .background(AppColors.border)
                
                HStack {
                    Text("Total Amount")
                        .font(.headline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Spacer()
                    
                    Text("LKR \(String(format: "%.2f", totalAmount))")
                        .font(.headline.bold())
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var payButton: some View {
        Button(action: handlePayment) {
            HStack {
                if paymentViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(paymentViewModel.isLoading ? "Processing..." : "Pay Now")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                selectedCard != nil && !paymentViewModel.isLoading ? AppColors.primary : AppColors.mutedForeground
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(selectedCard == nil || paymentViewModel.isLoading)
        .accessibilityLabel("Pay Now")
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Success" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Methods
    private func handlePayment() {
        // Validate payment method selection
        guard let selectedCard = selectedCard else {
            showAlert(title: "Error", message: "Please select a payment method")
            return
        }
        
        // Test server connection before processing payment
        paymentViewModel.testConnection { [self] success in
            if success {
                // Process payment through NetworkManager
                paymentViewModel.createPayment(
                    habitationOwnerId: habitationOwnerId,
                    reservationId: reservationId,
                    amount: totalAmount
                ) { [self] success in
                    if success {
                        // Payment successful, now confirm the reservation
                        reservationViewModel.confirmReservation(reservationId: reservationId) { confirmSuccess in
                            if confirmSuccess {
                                showAlert(title: "Success", message: "Payment completed and reservation confirmed successfully!")
                            } else {
                                showAlert(title: "Warning", message: "Payment completed but reservation confirmation failed. Please contact support.")
                            }
                        }
                    } else {
                        showAlert(title: "Error", message: paymentViewModel.errorMessage ?? "Payment failed. Please try again.")
                    }
                }
            } else {
                showAlert(title: "Connection Error", message: paymentViewModel.errorMessage ?? "Cannot connect to payment server. Please check your connection.")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func checkReservationStatus() {
        // Check reservation status periodically
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            reservationViewModel.getReservation(reservationId: reservationId) { reservationData in
                if let data = reservationData {
                    if data.status == "expired" {
                        timer.invalidate()
                        showAlert(title: "Reservation Expired", message: "Your reservation has expired. Returning to home screen.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            shouldNavigateToHome = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Payment Card Components
struct PaymentCardRow: View {
    let card: PaymentCard
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: card.type.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(card.type.color)
                    .frame(width: 40, height: 40)
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.type.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Text(card.maskedCardNumber)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Text(card.holderName)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Circle()
                    .fill(isSelected ? AppColors.primary : AppColors.input)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Payment Card Model
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

