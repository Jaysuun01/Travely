import Foundation
import UserNotifications
import UIKit
import FirebaseFirestore
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private var timer: Timer?
    
    override init() {
        super.init()
        setupNotifications()
        startTimeCheck()
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
    
    private func startTimeCheck() {
        // Check every minute for current time matches
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkCurrentTimeMatches()
        }
    }
    
    private func checkCurrentTimeMatches() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        
        // Get all pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = trigger.nextTriggerDate() {
                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                    
                    // Check if current time matches trigger time
                    if currentComponents.year == triggerComponents.year &&
                       currentComponents.month == triggerComponents.month &&
                       currentComponents.day == triggerComponents.day &&
                       currentComponents.hour == triggerComponents.hour &&
                       currentComponents.minute == triggerComponents.minute {
                        
                        // Send immediate notification
                        self.sendImmediateNotification(
                            title: request.content.title,
                            body: request.content.body,
                            identifier: request.identifier
                        )
                    }
                }
            }
        }
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
        guard let startDate = (location["startDate"] as? Timestamp)?.dateValue(),
              let locationName = location["name"] as? String,
              let locationId = location["id"] as? String else {
            print("❌ Missing required location data for notification")
            return
        }
        
        let identifier = "location-\(locationId)-start"
        print("\n--- Scheduling notification for location: \(locationName) ---")
        let now = Date()
        let interval = startDate.timeIntervalSince(now)
        print("Now: \(now), StartDate: \(startDate), Interval (seconds): \(interval)")
        var trigger: UNNotificationTrigger?
        var title: String
        var body: String
        var notificationDate: Date
        if interval <= 0 {
            // Already in the past, do not schedule
            print("⏰ Location start time is in the past, not scheduling notification.")
            return
        } else if interval <= 30 * 60 {
            // Less than or equal to 30 minutes from now, send immediately
            let minutes = Int(round(interval / 60))
            if minutes <= 1 {
                title = "Visit \(locationName) Now"
                body = "get ready for \(locationName) for your trip now!"
            } else {
                title = "Upcoming: \(locationName)"
                body = "get ready for \(locationName) for your trip in \(minutes) minutes!"
            }
            trigger = nil // Send immediately
            notificationDate = now
        } else {
            // More than 30 minutes away, schedule for 30 minutes before
            let triggerDate = startDate.addingTimeInterval(-30 * 60)
            title = "Upcoming: \(locationName)"
            body = "For your \(tripName) trip. (in 30 minutes)"
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            notificationDate = triggerDate
        }
        // Remove any existing notification for this location
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
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
                if trigger == nil {
                    print("✅ Immediate notification sent for location: \(locationName) with identifier: \(identifier)")
                } else {
                    print("✅ Notification scheduled for location: \(locationName) with identifier: \(identifier)")
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
