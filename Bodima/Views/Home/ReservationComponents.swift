import SwiftUI
import Foundation

struct HabitationAvailabilityView: View {
    let habitation: EnhancedHabitationData
    @StateObject private var reservationViewModel = ReservationViewModel()
    @State private var showDatePicker = false
    @State private var isCheckingAvailability = false
    @State private var availabilityStatus: String = ""
    
    var body: some View {
        VStack(spacing: 4) {
            if habitation.isReserved {
                Button(action: {
                    showDatePicker = true
                }) {
                    HStack(spacing: 4) {
                        if isCheckingAvailability {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                        }
                        Text("Partially Reserved")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Button(action: {
                    showDatePicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 10))
                        Text("Available")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if !availabilityStatus.isEmpty {
                Text(availabilityStatus)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            ReservationDatePickerView(
                habitation: habitation,
                reservationViewModel: reservationViewModel
            )
        }
    }
}

struct ReservationDatePickerView: View {
    let habitation: EnhancedHabitationData
    let reservationViewModel: ReservationViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authViewModel = AuthViewModel.shared
    
    @State private var checkInDate = Date()
    @State private var checkOutDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isCheckingAvailability = false
    @State private var availabilityMessage = ""
    @State private var isAvailable = false
    @State private var totalAmount: Double = 0
    @State private var totalDays: Int = 0
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var minimumDate: Date {
        Date()
    }
    
    private var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Dates")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Choose your check-in and check-out dates for \(habitation.name)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Date Pickers
                VStack(spacing: 20) {
                    // Check-in Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-in Date")
                            .font(.headline)
                            .foregroundColor(AppColors.foreground)
                        
                        DatePicker(
                            "Check-in",
                            selection: $checkInDate,
                            in: minimumDate...maximumDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: checkInDate) { newValue in
                            // Ensure check-out is after check-in
                            if checkOutDate <= newValue {
                                checkOutDate = Calendar.current.date(byAdding: .day, value: 1, to: newValue) ?? newValue
                            }
                            checkAvailability()
                        }
                    }
                    
                    // Check-out Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-out Date")
                            .font(.headline)
                            .foregroundColor(AppColors.foreground)
                        
                        DatePicker(
                            "Check-out",
                            selection: $checkOutDate,
                            in: Calendar.current.date(byAdding: .day, value: 1, to: checkInDate)!...maximumDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .onChange(of: checkOutDate) { _ in
                            checkAvailability()
                        }
                    }
                }
                
                // Availability Status
                if isCheckingAvailability {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking availability...")
                            .font(.subheadline)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                } else if !availabilityMessage.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isAvailable ? .green : .red)
                            Text(availabilityMessage)
                                .font(.subheadline)
                                .foregroundColor(isAvailable ? .green : .red)
                        }
                        
                        if isAvailable && totalAmount > 0 {
                            VStack(spacing: 4) {
                                Text("Total: \(totalDays) nights")
                                    .font(.caption)
                                    .foregroundColor(AppColors.mutedForeground)
                                Text("Amount: LKR \(String(format: "%.2f", totalAmount))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.foreground)
                            }
                        }
                    }
                    .padding()
                    .background((isAvailable ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.muted)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .navigationBarHidden(true)
        }
        .onAppear {
            checkAvailability()
        }
    }
    
    private func checkAvailability() {
        guard checkOutDate > checkInDate else { return }
        
        isCheckingAvailability = true
        availabilityMessage = ""
        isAvailable = false
        
        
        reservationViewModel.checkDateAvailability(
            habitationId: habitation.id,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate
        ) { available in
            DispatchQueue.main.async {
                self.isCheckingAvailability = false
                self.isAvailable = available
                if available {
                    let days = Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0
                    self.totalDays = days
                    self.totalAmount = Double(days * habitation.price)
                    self.availabilityMessage = "Available for \(days) nights"
                } else {
                    self.availabilityMessage = "Not available for selected dates"
                    self.totalDays = 0
                    self.totalAmount = 0
                }
            }
        }
    }
    
}
