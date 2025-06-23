import Foundation
import UserNotifications
import Combine

/// Handles all notifications for the app
@MainActor
class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("🔔 NotificationService - Authorization error: \(error)")
            return false
        }
    }
    
    func sendPostureNotification() {
        guard isAuthorized else {
            print("🔔 NotificationService - Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Check Your Posture!"
        content.body = "Sit up straight to maintain good posture."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 NotificationService - Notification error: \(error)")
            } else {
                print("🔔 NotificationService - ✅ Posture notification sent")
            }
        }
    }
    
    func sendStandupNotification() {
        guard isAuthorized else {
            print("🔔 NotificationService - Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Great job!"
        content.body = "You stood up - keep moving!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 NotificationService - Notification error: \(error)")
            } else {
                print("🔔 NotificationService - ✅ Standup notification sent")
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
} 
