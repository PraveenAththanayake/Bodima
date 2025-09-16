import SwiftUI
import EventKit

struct ReservationConfirmationDialog: View {
    let habitation: EnhancedHabitationData
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onExpired: () -> Void
    
    @State private var showTimerView = false
    @StateObject private var reservationTimer = ReservationTimer()
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Dialog content
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Confirm Reservation")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Do you really want to reserve this property?")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                
                // Property details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Property:")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                        Text(habitation.name)
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    HStack {
                        Text("Price:")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                        Text("LKR \(habitation.price).00")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    HStack {
                        Text("Type:")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                        Text(habitation.type)
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )
                
                // Warning message
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.red)
                        Text("Important!")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                        Spacer()
                    }
                    
                    Text("You must complete the payment within 2 minutes after confirming, or the reservation will automatically expire and the property will become available for others.")
                        .font(.caption)
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        onConfirm()
                        showTimerView = true
                    }) {
                        Text("Confirm & Start Timer")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.primary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.background)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            
            // Timer overlay
            if showTimerView {
                PaymentTimerView(
                    reservationTimer: reservationTimer,
                    habitation: habitation,
                    onTimerExpired: {
                        showTimerView = false
                        onExpired() // Navigate to home screen
                    },
                    onPaymentCompleted: {
                        showTimerView = false
                        onCancel() // Close the dialog when payment is completed
                    }
                )
            }
        }
    }
}

struct PaymentTimerView: View {
    @ObservedObject var reservationTimer: ReservationTimer
    let habitation: EnhancedHabitationData
    let onTimerExpired: () -> Void
    let onPaymentCompleted: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Timer display
                VStack(spacing: 16) {
                    Text("Payment Timer")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: reservationTimer.progressPercentage)
                            .stroke(
                                reservationTimer.timeRemaining > 30 ? .green : .red,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: reservationTimer.progressPercentage)
                        
                        VStack {
                            Text(reservationTimer.formattedTimeRemaining)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text("Complete your payment before time runs out!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                // Action button
                Button(action: onPaymentCompleted) {
                    Text("Proceed to Payment")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            // Start the timer when view appears
            reservationTimer.startTimer(for: habitation.id) {
                onTimerExpired()
            }
        }
        .onDisappear {
            reservationTimer.stopTimer()
        }
        .onChange(of: reservationTimer.hasExpired) { expired in
            if expired {
                onTimerExpired()
            }
        }
    }
}

// Preview
struct ReservationConfirmationDialog_Previews: PreviewProvider {
    static var previews: some View {
        ReservationConfirmationDialog(
            habitation: sampleHabitation,
            onConfirm: {},
            onCancel: {},
            onExpired: {}
        )
    }
    
    static let sampleHabitation: EnhancedHabitationData = {
        let jsonString = """
        {
            "_id": "1",
            "user": null,
            "name": "Sample Property",
            "description": "A beautiful property",
            "price": 25000,
            "type": "Apartment",
            "isReserved": false,
            "pictures": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "__v": 0
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(EnhancedHabitationData.self, from: data)
    }()
}