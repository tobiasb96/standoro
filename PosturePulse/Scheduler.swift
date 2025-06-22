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

    func start(sittingInterval: TimeInterval? = nil, standingInterval: TimeInterval? = nil) {
        if let sittingInterval = sittingInterval {
            self.sittingInterval = sittingInterval
        }
        if let standingInterval = standingInterval {
            self.standingInterval = standingInterval
        }
        
        guard self.sittingInterval > 0 && self.standingInterval > 0 else {
            print("🔔 Cannot start timer: intervals not set")
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
        
        print("🔔 Timer started: sitting \(self.sittingInterval) seconds, standing \(self.standingInterval) seconds, next fire at \(nextFire)")
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentPhase = .sitting
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        print("🔔 Timer stopped")
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        
        pauseStartTime = Date()
        remainingTimeWhenPaused = nextFire.timeIntervalSinceNow
        isPaused = true
        
        print("🔔 Timer paused, remaining time: \(remainingTimeWhenPaused) seconds")
    }
    
    func resume() {
        guard isRunning, isPaused, let pauseStart = pauseStartTime else { return }
        
        // Calculate new next fire time based on remaining time when paused
        nextFire = Date().addingTimeInterval(remainingTimeWhenPaused)
        isPaused = false
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        
        print("🔔 Timer resumed, next fire at \(nextFire)")
    }

    func restart() {
        guard sittingInterval > 0 && standingInterval > 0 else {
            print("🔔 Cannot restart: intervals not set")
            return
        }
        
        stop()
        start()
    }

    private func checkTimer() {
        guard isRunning, !isPaused else { return }
        
        let remaining = nextFire.timeIntervalSinceNow
        
        if remaining <= 0 {
            print("🔔 Timer fired - sending notification")
            fire()
        }
    }

    private func fire() {
        print("🔔 Timer fired - sending notification")
        
        // Check notification authorization first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Notification settings: \(settings.authorizationStatus.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                
                // Set notification based on current phase
                switch self.currentPhase {
                case .sitting:
                    content.title = "Stand-up break"
                    content.body = "Time to raise your desk!"
                case .standing:
                    content.title = "Sit-down break"
                    content.body = "Time to sit back down!"
                }
                
                content.sound = .default
                
                let req = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                
                UNUserNotificationCenter.current().add(req) { error in
                    if let error = error {
                        print("🔔 Notification error: \(error)")
                    } else {
                        print("🔔 Notification sent successfully")
                    }
                }
            } else {
                print("🔔 Notifications not authorized")
            }
        }
        
        // Switch to next phase
        switch currentPhase {
        case .sitting:
            currentPhase = .standing
            nextFire = Date().addingTimeInterval(self.standingInterval)
            print("🔔 Switched to standing phase, next fire at \(nextFire)")
        case .standing:
            currentPhase = .sitting
            nextFire = Date().addingTimeInterval(self.sittingInterval)
            print("🔔 Switched to sitting phase, next fire at \(nextFire)")
        }
    }
} 