import Foundation
import UserNotifications
import Combine

/// Handles all notifications for the app
@MainActor
class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    private var calendarService: CalendarService?
    private var shouldCheckCalendar: Bool = false
    
    // Exponential backoff state for posture notifications
    private var postureNotificationCount: Int = 0
    private var lastPostureNotificationTime: Date?
    private var backoffMultiplier: TimeInterval = 1.0
    private var maxBackoffTime: TimeInterval = 300 // 5 minutes max
    private var resetBackoffAfter: TimeInterval = 1800 // Reset after 30 minutes of good posture
    
    // Sustained good posture tracking
    private var goodPostureStartTime: Date?
    private var requiredGoodPostureDuration: TimeInterval = 120 // 2 minutes of sustained good posture
    private var isTrackingGoodPosture = false
    
    // Backoff configuration
    private let baseBackoffTime: TimeInterval = 60 // Start with 1 minute
    private let backoffExponent: Double = 1.5 // Exponential factor
    private let maxNotificationCount: Int = 5 // Max notifications before max backoff
    
    init() {
        checkAuthorizationStatus()
        startBackoffResetTimer()
    }
    
    func setCalendarService(_ calendarService: CalendarService, shouldCheck: Bool) {
        self.calendarService = calendarService
        self.shouldCheckCalendar = shouldCheck
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
    
    private func shouldSendNotification() -> Bool {
        // Check if we should mute due to calendar meetings
        if shouldCheckCalendar, let calendarService = calendarService {
            if calendarService.isCurrentlyBusy() {
                return false
            }
        }
        return true
    }
    
    private func shouldSendPostureNotification() -> Bool {
        guard shouldSendNotification() else { return false }
        
        // If this is the first notification, always send it
        if postureNotificationCount == 0 {
            return true
        }
        
        // Check if enough time has passed since last notification
        guard let lastTime = lastPostureNotificationTime else { return true }
        
        let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
        let requiredWaitTime = calculateBackoffTime()
        
        return timeSinceLastNotification >= requiredWaitTime
    }
    
    private func calculateBackoffTime() -> TimeInterval {
        // Calculate exponential backoff: base * (exponent ^ count)
        let exponentialBackoff = baseBackoffTime * pow(backoffExponent, Double(postureNotificationCount))
        
        // Cap at maximum backoff time
        return min(exponentialBackoff, maxBackoffTime)
    }
    
    private func getPostureNotificationContent() -> (title: String, body: String) {
        switch postureNotificationCount {
        case 0:
            return ("Check Your Posture!", "Sit up straight to maintain good posture.")
        case 1:
            return ("Posture Reminder", "You're still slouching. Let's straighten up!")
        case 2:
            return ("Posture Check Needed", "Your posture needs attention. Time to sit up straight.")
        case 3:
            return ("Posture Alert", "You've been slouching for a while. Please adjust your posture.")
        case 4:
            return ("Posture Warning", "Your posture has been poor for an extended period. Consider taking a break.")
        default:
            return ("Posture Check", "Please check your posture and consider taking a short break.")
        }
    }
    
    func sendPostureNotification() {
        guard isAuthorized else {
            return
        }
        
        guard shouldSendPostureNotification() else {
            print("🔔 NotificationService - Skipping posture notification due to backoff (count: \(postureNotificationCount))")
            return
        }
        
        let content = UNMutableNotificationContent()
        let notificationContent = getPostureNotificationContent()
        content.title = notificationContent.title
        content.body = notificationContent.body
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
                Task { @MainActor in
                    self.postureNotificationCount += 1
                    self.lastPostureNotificationTime = Date()
                    print("🔔 NotificationService - Sent posture notification #\(self.postureNotificationCount)")
                }
            }
        }
    }
    
    func sendStandupNotification() {
        guard isAuthorized else {
            return
        }
        
        guard shouldSendNotification() else {
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
            }
        }
    }
    
    /// Start tracking good posture - called when posture improves
    func startTrackingGoodPosture() {
        if !isTrackingGoodPosture {
            goodPostureStartTime = Date()
            isTrackingGoodPosture = true
            print("🔔 NotificationService - Started tracking good posture")
        }
    }
    
    /// Stop tracking good posture - called when posture becomes poor again
    func stopTrackingGoodPosture() {
        if isTrackingGoodPosture {
            goodPostureStartTime = nil
            isTrackingGoodPosture = false
            print("🔔 NotificationService - Stopped tracking good posture (posture became poor)")
        }
    }
    
    /// Check if sustained good posture duration has been reached
    private func checkSustainedGoodPosture() {
        guard isTrackingGoodPosture, let startTime = goodPostureStartTime else { return }
        
        let goodPostureDuration = Date().timeIntervalSince(startTime)
        if goodPostureDuration >= requiredGoodPostureDuration {
            resetPostureBackoff()
            print("🔔 NotificationService - Sustained good posture for \(Int(requiredGoodPostureDuration))s, resetting backoff")
        } else {
            let remaining = requiredGoodPostureDuration - goodPostureDuration
            print("🔔 NotificationService - Good posture for \(Int(goodPostureDuration))s, \(Int(remaining))s until backoff reset")
        }
    }
    
    /// Reset posture notification backoff when sustained good posture is achieved
    func resetPostureBackoff() {
        postureNotificationCount = 0
        lastPostureNotificationTime = nil
        goodPostureStartTime = nil
        isTrackingGoodPosture = false
        print("🔔 NotificationService - Reset posture notification backoff")
    }
    
    /// Check if backoff should be reset due to time passing
    private func checkBackoffReset() {
        guard let lastTime = lastPostureNotificationTime else { return }
        
        let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
        if timeSinceLastNotification >= resetBackoffAfter {
            resetPostureBackoff()
            print("🔔 NotificationService - Reset backoff due to time passing")
        }
    }
    
    private func startBackoffResetTimer() {
        // Check for backoff reset and sustained good posture every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBackoffReset()
                self?.checkSustainedGoodPosture()
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
    
    // Add this method for random posture nudges
    func sendRandomPostureNudge() {
        guard isAuthorized else { return }
        guard shouldSendNotification() else { return }
        
        let messages = [
            ("Posture Nudge", "Remember to sit up straight and relax your shoulders."),
            ("Posture Nudge", "Keep your back aligned and avoid slouching."),
            ("Posture Nudge", "Take a moment to check your posture."),
            ("Posture Nudge", "Adjust your screen to eye level for better posture."),
            ("Posture Nudge", "Stretch and reset your posture for a productivity boost!"),
            ("Posture Nudge", "A quick posture check can help you stay healthy!"),
            ("Posture Nudge", "Uncross your legs and plant your feet flat for best posture."),
            ("Posture Nudge", "Roll your shoulders back and take a deep breath."),
        ]
        let message = messages.randomElement() ?? ("Posture Nudge", "Check your posture!")
        
        let content = UNMutableNotificationContent()
        content.title = message.0
        content.body = message.1
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 NotificationService - Random nudge error: \(error)")
            } else {
                print("🔔 NotificationService - Sent random posture nudge")
            }
        }
    }
} 
