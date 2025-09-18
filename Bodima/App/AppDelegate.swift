import UIKit
import UserNotifications
import FirebaseCore
import CoreSpotlight

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Request notification permissions
        registerForPushNotifications(application: application)
        
        return true
    }
    
    // Register for push notifications
    func registerForPushNotifications(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else {
                print("❌ Notification permission denied")
                return
            }
            
            print("✅ Notification permission granted")
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Log the token for testing purposes
        print("📱 Device Token: \(token)")
        
        // TODO: Send the token to your server
    }
    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification alert even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        // Post notification to update UI if needed
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshNotifications"),
            object: nil
        )
    }
    
    // Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle the notification tap
        let userInfo = response.notification.request.content.userInfo
        print("📬 Notification tapped with userInfo: \(userInfo)")
        
        // Post notification to update UI
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshNotifications"),
            object: nil
        )
        
        completionHandler()
    }
    
    // Handle Core Spotlight deep links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType,
           let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
            // identifier format: "habitation_<id>"
            if identifier.hasPrefix("habitation_") {
                let habitationId = String(identifier.dropFirst("habitation_".count))
                NotificationCenter.default.post(name: NSNotification.Name("OpenHabitationFromSpotlight"),
                                                object: nil,
                                                userInfo: ["habitationId": habitationId])
                return true
            }
        }
        return false
    }
}