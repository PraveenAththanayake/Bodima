import SwiftUI
import UIKit
import Foundation

struct ReserveView: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var navigateToPayment = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @StateObject private var reservationViewModel = ReservationViewModel()
    
    private var monthlyRent: Double {
        return Double(habitation.price)
    }
    
    private var propertyTitle: String {
        return habitation.name
    }
    
    private var propertyAddress: String {
        if let locationData = locationData {
            return locationData.shortAddress ??
            "\(locationData.addressNo ?? ""), \(locationData.city ?? ""), \(locationData.district ?? "")"
        }
        return locationData?.shortAddress ?? "Address not available"
    }
    
    private var propertyImageURL: String? {
        return habitation.mainPictureUrl
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.background)
                    
                    propertyInfoCard
                        .padding(.horizontal, 16)
                    
                    dateSelectionCard
                        .padding(.horizontal, 16)
                    
                    pricingSummaryCard
                        .padding(.horizontal, 16)
                    
                    continueButton
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToPayment) {
                if let reservationId = reservationViewModel.reservationId {
                    PaymentView(
                        habitation: habitation,
                        totalAmount: monthlyRent,
                        propertyTitle: propertyTitle,
                        propertyAddress: propertyAddress,
                        reservationId: reservationId,
                        habitationOwnerId: habitation.user?.id ?? "unknown_owner"
                    )
                } else {
                    // Fallback view in case reservation ID is missing
                    Text("Error: Reservation not found")
                        .foregroundColor(.red)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reserve")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Complete your reservation")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {}) {
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
    
    private var propertyInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Details")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
            
            HStack(spacing: 12) {
                Group {
                    if let imageURL = propertyImageURL {
                        CachedImage(url: imageURL, contentMode: .fill) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.input)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundStyle(AppColors.mutedForeground)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.input)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(AppColors.mutedForeground)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(propertyTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                        .lineLimit(2)
                    
                    Text(propertyAddress)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text("4.5")
                            .font(.caption)
                            .foregroundStyle(AppColors.foreground)
                        Text("(235)")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                }
                
                Spacer()
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
    
    private var dateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reservation Dates")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Check-in Date")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Check-out Date")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    DatePicker(
                        "",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(AppColors.primary)
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
    
    private var pricingSummaryCard: some View {
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
                    Text("LKR \(String(format: "%.2f", monthlyRent))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Divider()
                    .background(AppColors.border)
                
                HStack {
                    Text("Total Amount")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    Spacer()
                    Text("LKR \(String(format: "%.2f", monthlyRent))")
                        .font(.subheadline.bold())
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
    
    private var continueButton: some View {
        Button(action: {
            createReservationAndNavigate()
        }) {
            HStack {
                if reservationViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(reservationViewModel.isLoading ? "Creating Reservation..." : "Continue to Payment")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(reservationViewModel.isLoading ? AppColors.mutedForeground : AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(reservationViewModel.isLoading)
        .accessibilityLabel("Continue to Payment")
    }
    
    private func createReservationAndNavigate() {
        // Get the user profile ID using the ViewModel's helper method
        guard let userProfileId = reservationViewModel.getUserProfileId() else {
            showAlert(
                title: "User Profile Required",
                message: "Unable to retrieve user profile. Please complete your profile setup."
            )
            return
        }
        
        createReservationWithUserId(userProfileId)
    }
    
    private func createReservationWithUserId(_ userId: String) {
        reservationViewModel.createReservation(
            userId: userId,
            habitationId: habitation.id,
            startDate: startDate,
            endDate: endDate
        ) { [self] success in
            if success {
                // Start the timer for this reservation
                if let reservationId = reservationViewModel.reservationId {
                    reservationViewModel.startReservationTimer(for: reservationId)
                }
                navigateToPayment = true
            } else {
                showAlert(
                    title: "Reservation Failed",
                    message: reservationViewModel.errorMessage ?? "Unable to create reservation. Please try again."
                )
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}