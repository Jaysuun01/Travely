import Foundation
import UserNotifications
import UIKit
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    func setupNotifications() {
        // First, check current settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("ℹ️ Current notification settings:")
            print("ℹ️ Authorization status: \(settings.authorizationStatus.rawValue)")
            print("ℹ️ Alert setting: \(settings.alertSetting.rawValue)")
            print("ℹ️ Sound setting: \(settings.soundSetting.rawValue)")
            print("ℹ️ Badge setting: \(settings.badgeSetting.rawValue)")
        }
        
        // Request authorization
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("✅ Notification permission granted")
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("❌ Notification permission denied")
                }
            }
        )
    }
    
    private func sendImmediateNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(identifier)-immediate",
            content: content,
            trigger: nil  // nil trigger means deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending immediate notification: \(error)")
            } else {
                print("✅ Immediate notification sent for \(identifier)")
            }
        }
    }
    
    func scheduleTripNotification(for trip: [String: Any]) {
        if !UserDefaults.standard.bool(forKey: "notificationsEnabled") {
            print("🔕 Notifications are disabled by user.")
            return
        }
        guard let startDate = (trip["startDate"] as? Timestamp)?.dateValue(),
              let tripName = trip["tripName"] as? String,
              let destination = trip["destination"] as? String else {
            print("❌ Missing required trip data for notification")
            return
        }
        
        print("ℹ️ Scheduling notifications for trip: \(tripName)")
        
        // Schedule notification for 1 day before
        let oneDayBefore = startDate.addingTimeInterval(-24 * 60 * 60)
        if oneDayBefore > Date() {
            scheduleNotification(
                title: "Trip Tomorrow",
                body: "Your trip to \(destination) starts tomorrow!",
                date: oneDayBefore,
                identifier: "trip-\(trip["tripId"] as? String ?? UUID().uuidString)-tomorrow"
            )
        }
        
        // Schedule notification for 1 hour before
        let oneHourBefore = startDate.addingTimeInterval(-60 * 60)
        if oneHourBefore > Date() {
            scheduleNotification(
                title: "Trip Today",
                body: "Your trip to \(destination) starts in 1 hour!",
                date: oneHourBefore,
                identifier: "trip-\(trip["tripId"] as? String ?? UUID().uuidString)-today"
            )
        }
        
        // Schedule notification for exact start time
        if startDate > Date() {
            scheduleNotification(
                title: "Trip Starting Now",
                body: "Your trip to \(destination) is starting now!",
                date: startDate,
                identifier: "trip-\(trip["tripId"] as? String ?? UUID().uuidString)-start"
            )
        }
    }
    
    func scheduleLocationNotification(for location: [String: Any], tripName: String) {
        if !UserDefaults.standard.bool(forKey: "notificationsEnabled") {
            print("🔕 Notifications are disabled by user.")
            return
        }
        guard let startDate = (location["startDate"] as? Timestamp)?.dateValue(),
              let locationName = location["name"] as? String,
              let locationId = location["id"] as? String else {
            print("❌ Missing required location data for notification")
            return
        }
        let reminderOffset = location["reminderOffset"] as? TimeInterval
        if reminderOffset == nil {
            print("ℹ️ No reminder set for this location, skipping notification.")
            return
        }
        let identifier = "location-\(locationId)-start"
        let fireDate = startDate.addingTimeInterval(-reminderOffset!)
        if fireDate < Date() {
            print("⏰ Reminder time is in the past, not scheduling notification.")
            return
        }
        let title = "Reminder: \(locationName) in \(tripName)"
        let body: String
        if reminderOffset == 0 {
            body = "It's time for \(locationName) in your trip '\(tripName)'!"
        } else {
            let minutes = Int(reminderOffset! / 60)
            body = "Get ready for \(locationName) in your trip '\(tripName)' in \(minutes) minutes!"
        }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "tripName": tripName,
            "locationName": locationName
        ]
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled for location: \(locationName) with identifier: \(identifier)")
                // Add to Firestore for notification view
                if let userId = Auth.auth().currentUser?.uid {
                    let notification = AppNotification(
                        id: UUID().uuidString,
                        title: title,
                        message: body,
                        date: fireDate,
                        isRead: false
                    )
                    do {
                        let notificationData = try Firestore.Encoder().encode(notification)
                        self.db.collection("users").document(userId).collection("notifications").document(notification.id).setData(notificationData)
                    } catch {
                        print("❌ Error saving notification to Firebase:", error)
                    }
                }
            }
        }
    }
    
    private func scheduleNotification(title: String, body: String, date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create date components for the trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled for \(date)")
            }
        }
    }
    
    // Schedules notifications for all locations in a trip
    func scheduleAllLocationNotifications(for trip: Trip) {
        for location in trip.locations {
            scheduleLocationNotification(for: [
                "id": location.id,
                "name": location.name,
                "startDate": Timestamp(date: location.startDate)
            ], tripName: trip.tripName)
        }
    }

    // Removes a scheduled notification for a location by its id
    func removeLocationNotification(locationId: String) {
        let identifier = "location-\(locationId)-start"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

extension Notification.Name {
    static let locationNotificationDelivered = Notification.Name("locationNotificationDelivered")
    static let locationNotificationScheduled = Notification.Name("locationNotificationScheduled")
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 willPresent called for notification: \(notification.request.identifier)")
        let content = notification.request.content
        // Post NotificationCenter event for all location notifications
        if let locationName = content.userInfo["locationName"] as? String {
            let tripName = content.userInfo["tripName"] as? String ?? ""
            print("🔔 Posting NotificationCenter event from willPresent for location notification (any identifier)")
            NotificationCenter.default.post(name: .locationNotificationDelivered, object: nil, userInfo: [
                "title": content.title,
                "body": content.body,
                "date": Date(),
                "tripName": tripName,
                "locationName": locationName
            ])
        }
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 didReceive called for notification: \(response.notification.request.identifier)")
        let content = response.notification.request.content
        // Post NotificationCenter event for all location notifications
        if let locationName = content.userInfo["locationName"] as? String {
            let tripName = content.userInfo["tripName"] as? String ?? ""
            print("🔔 Posting NotificationCenter event from didReceive for location notification (any identifier)")
            NotificationCenter.default.post(name: .locationNotificationDelivered, object: nil, userInfo: [
                "title": content.title,
                "body": content.body,
                "date": Date(),
                "tripName": tripName,
                "locationName": locationName
            ])
        }
        completionHandler()
    }
}

enum TripNotificationType: String {
    case tomorrow
    case today
}

// MARK: - Test Functions
extension NotificationManager {
    func scheduleTestNotification() {
        // Create test notification content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification that appears 30 seconds after scheduling"
        content.sound = .default
        
        // Create trigger for 30 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error)")
            } else {
                print("✅ Test notification scheduled successfully")
            }
        }
        
        // Also show an immediate test notification
        let immediateContent = UNMutableNotificationContent()
        immediateContent.title = "Immediate Test"
        immediateContent.body = "This notification should appear immediately"
        immediateContent.sound = .default
        
        let immediateRequest = UNNotificationRequest(
            identifier: "immediate-test",
            content: immediateContent,
            trigger: nil  // nil trigger means deliver immediately
        )
        
        UNUserNotificationCenter.current().add(immediateRequest) { error in
            if let error = error {
                print("❌ Error scheduling immediate notification: \(error)")
            } else {
                print("✅ Immediate notification scheduled successfully")
            }
        }
    }
}
