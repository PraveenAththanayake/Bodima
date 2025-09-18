import SwiftUI
import UIKit
import Foundation
import EventKit

// Main reservation view controller managing the booking confirmation flow
// Orchestrates modular components and handles calendar integration
// Maintains reservation state through ReservationStateManager
struct ReserveView: View {
    // Navigation and UI state management
    @State private var navigateToPayment = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingEventKitPermission = false
    @State private var eventStore = EKEventStore()
    @State private var calendarEventCreated = false
    
    // Centralized state management for reservation flow
    @StateObject private var reservationStateManager = ReservationStateManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Computed properties for clean data access from reservation state
    private var reservationData: PendingReservationData? {
        return reservationStateManager.currentReservationData
    }
    
    private var monthlyRent: Double {
        return reservationData?.totalAmount ?? 0.0
    }
    
    private var propertyTitle: String {
        return reservationData?.propertyTitle ?? "Property"
    }
    
    private var propertyAddress: String {
        return reservationData?.propertyAddress ?? "Address not available"
    }
    
    private var propertyImageURL: String? {
        return reservationData?.propertyImageURL
    }
    
    // Main view body orchestrating modular components
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with navigation and validation
                    ReserveHeaderComponent(onBackTapped: {
                        presentationMode.wrappedValue.dismiss()
                    })
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.background)
                    
                    // Property information display
                    ReservePropertySummaryComponent(
                        propertyTitle: propertyTitle,
                        propertyAddress: propertyAddress,
                        propertyImageURL: propertyImageURL
                    )
                    .padding(.horizontal, 16)
                    
                    // Date selection interface with blocked dates functionality
                    if let reservationData = reservationStateManager.currentReservationData {
                        IndustryDatePickerComponent(
                            checkInDate: Binding(
                                get: { reservationData.checkInDate },
                                set: { reservationData.checkInDate = $0 }
                            ),
                            checkOutDate: Binding(
                                get: { reservationData.checkOutDate },
                                set: { reservationData.checkOutDate = $0 }
                            ),
                            habitationId: reservationData.habitation.id,
                            onDateChange: { checkIn, checkOut in
                                reservationStateManager.updateReservationDates(checkInDate: checkIn, checkOutDate: checkOut)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Pricing breakdown and summary
                    ReservePricingBreakdownComponent(monthlyRent: monthlyRent)
                        .padding(.horizontal, 16)
                    
                    // Action buttons for calendar and payment flow
                    ReserveActionButtonsComponent(onContinueAction: {
                        requestCalendarPermissionAndProceed()
                    })
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 80)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToPayment) {
                PaymentView()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            // Validate reservation state on view appearance
            if reservationStateManager.currentReservationData == nil {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // Navigation and flow control functions
    // Handles payment navigation without premature reservation creation
    private func proceedToPayment() {
        navigateToPayment = true
    }
    
    // Calendar integration and permission handling
    // Manages EventKit permissions and calendar event creation
    private func requestCalendarPermissionAndProceed() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            createCalendarEventAndProceed()
        case .notDetermined:
            eventStore.requestAccess(to: .event) { [self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        createCalendarEventAndProceed()
                    } else {
                        proceedToPayment()
                    }
                }
            }
        case .denied, .restricted:
            proceedToPayment()
        @unknown default:
            proceedToPayment()
        }
    }
    
    // Calendar event creation with reservation details
    // Creates comprehensive event with property and booking information
    private func createCalendarEventAndProceed() {
        guard let reservationData = reservationData else {
            proceedToPayment()
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Bodima Reservation - \(propertyTitle)"
        event.startDate = reservationData.checkInDate
        event.endDate = reservationData.checkOutDate
        event.isAllDay = true
        event.notes = """
        Property: \(propertyTitle)
        Address: \(propertyAddress)
        Monthly Rent: LKR \(String(format: "%.2f", monthlyRent))
        
        Reservation created through Bodima app.
        """
        event.location = propertyAddress
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            calendarEventCreated = true
            DispatchQueue.main.async {
                self.reservationStateManager.currentReservationData?.calendarEventCreated = true
            }
        } catch {
            print("Calendar event creation failed: \(error.localizedDescription)")
        }
        
        proceedToPayment()
    }
    
    // Alert display utility for error handling and user feedback
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}