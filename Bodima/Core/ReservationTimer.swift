import Foundation
import EventKit
import UserNotifications

class ReservationTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 120 // 2 minutes in seconds
    @Published var isActive = false
    @Published var hasExpired = false
    
    private var timer: Timer?
    private let eventStore = EKEventStore()
    private var reservationId: String?
    private var onExpired: (() -> Void)?
    
    // MARK: - Timer Management
    
    func startTimer(for reservationId: String, onExpired: @escaping () -> Void) {
        self.reservationId = reservationId
        self.onExpired = onExpired
        self.timeRemaining = 120
        self.isActive = true
        self.hasExpired = false
        
        // Start the countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTimer()
            }
        }
        
        // Request notification permissions and schedule notification
        requestNotificationPermission()
        schedulePaymentReminder()
        
        // Request calendar access and create event
        requestCalendarAccess()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer expired
            hasExpired = true
            isActive = false
            timer?.invalidate()
            timer = nil
            onExpired?()
        }
    }
    
    // MARK: - EventKit Integration
    
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            if granted && error == nil {
                DispatchQueue.main.async {
                    self?.createCalendarEvent()
                }
            } else {
                print("Calendar access denied or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func createCalendarEvent() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Complete Payment for Reservation"
        event.notes = "Payment deadline for your habitation reservation. Complete payment within 2 minutes to confirm your booking."
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(120) // 2 minutes from now
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add alarm 30 seconds before deadline
        let alarm = EKAlarm(relativeOffset: -30)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Calendar event created successfully")
        } catch {
            print("Failed to create calendar event: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Integration
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func schedulePaymentReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "Only 30 seconds left to complete your payment!"
        content.sound = .default
        
        // Schedule notification 30 seconds before deadline (90 seconds from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 90, repeats: false)
        let request = UNNotificationRequest(identifier: "payment_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Payment reminder notification scheduled")
            }
        }
        
        // Schedule expiration notification
        let expirationContent = UNMutableNotificationContent()
        expirationContent.title = "Reservation Expired"
        expirationContent.body = "Your reservation has expired due to timeout. The property is now available for others to book."
        expirationContent.sound = .default
        
        let expirationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 120, repeats: false)
        let expirationRequest = UNNotificationRequest(identifier: "reservation_expired", content: expirationContent, trigger: expirationTrigger)
        
        UNUserNotificationCenter.current().add(expirationRequest) { error in
            if let error = error {
                print("Failed to schedule expiration notification: \(error.localizedDescription)")
            } else {
                print("Expiration notification scheduled")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        return timeRemaining / 120.0
    }
    
    deinit {
        stopTimer()
    }
}