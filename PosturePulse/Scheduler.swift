import Foundation
import UserNotifications
import Combine

enum PosturePhase {
    case sitting
    case standing
}

@MainActor
class Scheduler: ObservableObject {
    @Published var nextFire = Date()
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: PosturePhase = .sitting
    
    private var timer: Timer?
    private var _sittingInterval: TimeInterval = 25 * 60 // Default 25 minutes
    private var _standingInterval: TimeInterval = 5 * 60 // Default 5 minutes
    private var pauseStartTime: Date?
    private var remainingTimeWhenPaused: TimeInterval = 0
    private var calendarService: CalendarService?
    private var shouldCheckCalendar: Bool = false
    
    var sittingInterval: TimeInterval {
        get { _sittingInterval }
        set { _sittingInterval = newValue }
    }
    
    var standingInterval: TimeInterval {
        get { _standingInterval }
        set { _standingInterval = newValue }
    }
    
    var currentInterval: TimeInterval {
        switch currentPhase {
        case .sitting:
            return sittingInterval
        case .standing:
            return standingInterval
        }
    }

    var remainingTimeString: String {
        let remaining = nextFire.timeIntervalSinceNow
        if remaining <= 0 {
            return "0s"
        }
        
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var currentRemainingTime: TimeInterval {
        if isPaused {
            return remainingTimeWhenPaused
        } else {
            return nextFire.timeIntervalSinceNow
        }
    }
    
    func setCalendarService(_ calendarService: CalendarService, shouldCheck: Bool) {
        self.calendarService = calendarService
        self.shouldCheckCalendar = shouldCheck
    }

    func start(sittingInterval: TimeInterval? = nil, standingInterval: TimeInterval? = nil) {
        if let sittingInterval = sittingInterval {
            self.sittingInterval = sittingInterval
        }
        if let standingInterval = standingInterval {
            self.standingInterval = standingInterval
        }
        
        guard self.sittingInterval > 0 && self.standingInterval > 0 else {
            return
        }
        
        // Cancel existing timer
        timer?.invalidate()
        timer = nil
        
        // Reset pause state
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        
        // Start with sitting phase
        currentPhase = .sitting
        
        // Create new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimer()
            }
        }
        
        nextFire = Date().addingTimeInterval(self.sittingInterval)
        isRunning = true
        isPaused = false
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentPhase = .sitting
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        
        pauseStartTime = Date()
        remainingTimeWhenPaused = nextFire.timeIntervalSinceNow
        isPaused = true
    }
    
    func resume() {
        guard isRunning, isPaused, let _ = pauseStartTime else { return }
        
        // Calculate new next fire time based on remaining time when paused
        nextFire = Date().addingTimeInterval(remainingTimeWhenPaused)
        isPaused = false
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
    }

    func restart() {
        guard sittingInterval > 0 && standingInterval > 0 else {
            return
        }
        
        stop()
        start()
    }
    
    func skipPhase() {
        guard isRunning else {
            return
        }
        
        // If paused, resume first
        if isPaused {
            resume()
        }
        
        // Switch to next phase immediately without sending notification
        switchPhase()
    }

    private func checkTimer() {
        guard isRunning, !isPaused else { return }
        
        let remaining = nextFire.timeIntervalSinceNow
        
        if remaining <= 0 {
            fire()
        }
    }

    private func fire() {
        // Check if we should skip notification due to calendar meetings
        if shouldCheckCalendar, let calendarService = calendarService {
            if calendarService.isInMeeting() {
                // Still switch phases but don't send notification
                switchPhase()
                return
            }
        }
        
        // Capture values before the closure to avoid MainActor isolation issues
        let currentPhase = self.currentPhase
        let sittingMinutes = Int(sittingInterval / 60)
        let standingMinutes = Int(standingInterval / 60)
        
        // Check notification authorization first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                
                // Set notification based on current phase
                switch currentPhase {
                case .sitting:
                    content.title = "Time to Stand Up!"
                    content.subtitle = "You've been sitting for \(sittingMinutes) minutes."
                    content.body = "A quick stretch will do you good."
                case .standing:
                    content.title = "Time to Sit Down"
                    content.subtitle = "You've been standing for \(standingMinutes) minutes."
                    content.body = "Time to relax for a bit."
                }
                
                content.sound = .default
                
                let req = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                
                UNUserNotificationCenter.current().add(req) { error in
                    if let error = error {
                        print("🔔 Scheduler - Notification error: \(error)")
                    }
                }
            }
        }
        
        // Switch to next phase
        switchPhase()
    }
    
    private func switchPhase() {
        switch currentPhase {
        case .sitting:
            currentPhase = .standing
            nextFire = Date().addingTimeInterval(self.standingInterval)
        case .standing:
            currentPhase = .sitting
            nextFire = Date().addingTimeInterval(self.sittingInterval)
        }
    }
} 
