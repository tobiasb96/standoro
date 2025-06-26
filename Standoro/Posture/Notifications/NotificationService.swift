import Foundation
import UserNotifications
import Combine

/// Handles all notifications for the app
@MainActor
class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    private var calendarService: CalendarService?
    private var shouldCheckCalendar: Bool = false
    private var statsService: StatsService?
    
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
    private let backoffExponent: Double = 3.0 // Exponential factor (increased from 1.5 to 3.0)
    private let maxNotificationCount: Int = 5 // Max notifications before max backoff
    
    // Timer for periodic backoff/good-posture checks. Nil when tracking is disabled.
    private var backoffResetTimer: Timer?
    
    init() {
        checkAuthorizationStatus()
        // Do NOT start the timer automatically – it will be started only when
        // posture tracking is explicitly enabled (e.g. when the user turns the
        // "AirPods Posture Monitoring" feature on).
    }
    
    func setCalendarService(_ calendarService: CalendarService, shouldCheck: Bool) {
        self.calendarService = calendarService
        self.shouldCheckCalendar = shouldCheck
    }
    
    func setStatsService(_ statsService: StatsService) {
        self.statsService = statsService
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
            #if DEBUG
            print("NotificationService: Authorization error: \(error)")
            #endif
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
        // With exponent = 3.0: 60s → 180s → 540s → 1620s → 4860s (capped at 300s max)
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
                #if DEBUG
                print("NotificationService: Notification error: \(error)")
                #endif
            } else {
                Task { @MainActor in
                    self.postureNotificationCount += 1
                    self.lastPostureNotificationTime = Date()
                    // Only track stats when notification is actually sent
                    self.statsService?.recordPostureAlert()
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
                #if DEBUG
                print("NotificationService: Notification error: \(error)")
                #endif
            }
        }
    }
    
    /// Start tracking good posture - called when posture improves
    func startTrackingGoodPosture() {
        if !isTrackingGoodPosture {
            goodPostureStartTime = Date()
            isTrackingGoodPosture = true
        }
    }
    
    /// Stop tracking good posture - called when posture becomes poor again
    func stopTrackingGoodPosture() {
        if isTrackingGoodPosture {
            goodPostureStartTime = nil
            isTrackingGoodPosture = false
        }
    }
    
    /// Enable posture tracking and start the backoff timer
    func enablePostureTracking() {
        // Reset backoff state when enabling
        postureNotificationCount = 0
        lastPostureNotificationTime = nil
        backoffMultiplier = 1.0
        
        // Start the backoff reset timer
        startBackoffResetTimer()
        
        #if DEBUG
        print("NotificationService: Posture tracking enabled")
        #endif
    }
    
    /// Disable posture tracking and stop the backoff timer
    func disablePostureTracking() {
        // Stop the backoff reset timer
        stopBackoffResetTimer()
        
        // Reset tracking state
        isTrackingGoodPosture = false
        goodPostureStartTime = nil
        
        #if DEBUG
        print("NotificationService: Posture tracking disabled")
        #endif
    }
    
    private func startBackoffResetTimer() {
        // Cancel existing timer
        backoffResetTimer?.invalidate()
        
        // Create new timer that fires every 30 seconds to check for backoff reset conditions
        backoffResetTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBackoffResetConditions()
            }
        }
    }
    
    private func stopBackoffResetTimer() {
        backoffResetTimer?.invalidate()
        backoffResetTimer = nil
    }
    
    private func checkBackoffResetConditions() {
        // Reset backoff if we've been tracking good posture for the required duration
        if isTrackingGoodPosture, let startTime = goodPostureStartTime {
            let goodPostureDuration = Date().timeIntervalSince(startTime)
            
            if goodPostureDuration >= resetBackoffAfter {
                // Reset backoff state
                postureNotificationCount = 0
                lastPostureNotificationTime = nil
                backoffMultiplier = 1.0
                
                #if DEBUG
                print("NotificationService: Backoff reset after \(Int(goodPostureDuration))s of good posture")
                #endif
            }
        }
    }
    
    /// Send a random posture nudge (for periodic reminders)
    func sendRandomPostureNudge() {
        guard isAuthorized else {
            return
        }
        
        guard shouldSendNotification() else {
            return
        }
        
        let messages = [
            ("Posture Check", "Time for a quick posture check!"),
            ("Posture Reminder", "How's your posture looking?"),
            ("Posture Nudge", "Stretch and reset your posture for a productivity boost!"),
            ("Posture Nudge", "A quick posture check can help you stay healthy!")
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
                #if DEBUG
                print("NotificationService: Random nudge error: \(error)")
                #endif
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
} 
