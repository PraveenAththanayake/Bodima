import UIKit
import Foundation
import SwiftUI

struct DetailView: View {
    // Properties
    // Core data models passed from parent view
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    let featureData: HabitationFeatureData?
    
    // State Variables
    // UI interaction states managed locally within this view
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likesCount = 24
    @State private var isFollowing = false
    @State private var navigateToReserve = false
    @State private var showReservationDialog = false
    @State private var navigateToHome = false
    @State private var reservedDates: [ReservedDateRange] = []
    @State private var isLoadingReservations = false
    
    // View Models and Managers
    // Centralized state management for reservation flow and data fetching
    @StateObject private var reservationViewModel = ReservationViewModel()
    @StateObject private var reservationStateManager = ReservationStateManager.shared
    @StateObject private var dateBlockingViewModel = DateBlockingViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // Main View Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with navigation and branding
                    DetailHeaderComponent(onBackTapped: {
                        presentationMode.wrappedValue.dismiss()
                    })
                    
                    // Main content card with all property information
                    VStack(alignment: .leading, spacing: 16) {
                        // User profile section
                        DetailUserProfileComponent(
                            habitation: habitation,
                            isFollowing: $isFollowing
                        )
                        
                        // Property image display
                        DetailPropertyImageComponent(habitation: habitation)
                        
                        // Social action buttons
                        DetailActionButtonsComponent(
                            isLiked: $isLiked,
                            likesCount: $likesCount,
                            isBookmarked: $isBookmarked
                        )
                        
                        // Property details and information
                        DetailPropertyInfoComponent(
                            habitation: habitation,
                            locationData: locationData
                        )
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
                    .padding(.horizontal, 16)
                    
                    // Amenities section (conditional)
                    if let features = featureData {
                        DetailAmenitiesComponent(featureData: features)
                            .padding(.horizontal, 16)
                    }
                    
                    // Reservation status display
                    DetailReservationComponent(
                        reservedDates: reservedDates,
                        isLoadingReservations: isLoadingReservations
                    )
                    .padding(.horizontal, 16)
                    
                    // Pricing and reserve button
                    DetailPricingComponent(
                        habitation: habitation,
                        onReserveAction: handleReserveAction
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToReserve) {
                ReserveView()
            }
        }
        .onAppear {
            loadReservedDates()
            dateBlockingViewModel.fetchBlockedDates(for: habitation.id)
        }
    }
    
    // Action Handlers
    // Centralized action handling for better maintainability and testing
    private func handleReserveAction() {
        reservationStateManager.startReservationFlow(
            habitation: habitation,
            locationData: locationData,
            featureData: featureData
        )
        navigateToReserve = true
    }
    
    // Data Loading
    // Asynchronous data fetching with proper error handling and state management
    
    private func loadReservedDates() {
        isLoadingReservations = true
        
        reservationViewModel.getReservedDates(habitationId: habitation.id) { dates in
            DispatchQueue.main.async {
                self.reservedDates = dates
                self.isLoadingReservations = false
            }
        }
    }
}
