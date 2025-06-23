import Foundation
import UserNotifications
import Combine

enum PosturePhase {
    case sitting
    case standing
}

enum SessionType {
    case focus
    case shortBreak
    case longBreak
}

@MainActor
class Scheduler: ObservableObject {
    @Published var nextFire = Date()
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: PosturePhase = .sitting
    @Published var currentSessionType: SessionType = .focus
    
    private var timer: Timer?
    private var _sittingInterval: TimeInterval = 25 * 60 // Default 25 minutes
    private var _standingInterval: TimeInterval = 5 * 60 // Default 5 minutes
    private var pauseStartTime: Date?
    private var remainingTimeWhenPaused: TimeInterval = 0
    private var calendarService: CalendarService?
    private var shouldCheckCalendar: Bool = false
    private var autoStartEnabled: Bool = true // Default to true
    
    // Pomodoro tracking
    private var completedFocusSessions: Int = 0
    @Published var pomodoroModeEnabled: Bool = false
    private var _focusInterval: TimeInterval = 25 * 60 // Default 25 minutes for Pomodoro
    private var _shortBreakInterval: TimeInterval = 5 * 60 // Default 5 minutes
    private var _longBreakInterval: TimeInterval = 15 * 60 // Default 15 minutes
    private var _intervalsBeforeLongBreak: Int = 4 // Default 4 focus sessions
    
    var sittingInterval: TimeInterval {
        get { _sittingInterval }
        set { _sittingInterval = newValue }
    }
    
    var standingInterval: TimeInterval {
        get { _standingInterval }
        set { _standingInterval = newValue }
    }
    
    // Pomodoro intervals
    var focusInterval: TimeInterval {
        get { _focusInterval }
        set { _focusInterval = newValue }
    }
    
    var shortBreakInterval: TimeInterval {
        get { _shortBreakInterval }
        set { _shortBreakInterval = newValue }
    }
    
    var longBreakInterval: TimeInterval {
        get { _longBreakInterval }
        set { _longBreakInterval = newValue }
    }
    
    var intervalsBeforeLongBreak: Int {
        get { _intervalsBeforeLongBreak }
        set { _intervalsBeforeLongBreak = newValue }
    }
    
    var currentInterval: TimeInterval {
        if pomodoroModeEnabled {
            switch currentSessionType {
            case .focus:
                return focusInterval
            case .shortBreak:
                return shortBreakInterval
            case .longBreak:
                return longBreakInterval
            }
        } else {
            switch currentPhase {
            case .sitting:
                return sittingInterval
            case .standing:
                return standingInterval
            }
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
    
    func setAutoStartEnabled(_ enabled: Bool) {
        self.autoStartEnabled = enabled
    }
    
    func setPomodoroMode(_ enabled: Bool) {
        self.pomodoroModeEnabled = enabled
        if enabled {
            // Reset Pomodoro tracking when enabling
            completedFocusSessions = 0
            currentSessionType = .focus
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
            return
        }
        
        // Cancel existing timer
        timer?.invalidate()
        timer = nil
        
        // Reset pause state
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        
        // Initialize based on mode
        if pomodoroModeEnabled {
            currentSessionType = .focus
            currentPhase = .sitting // Start with sitting for focus
            nextFire = Date().addingTimeInterval(self.focusInterval)
        } else {
            currentPhase = .sitting
            nextFire = Date().addingTimeInterval(self.sittingInterval)
        }
        
        // Create new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimer()
            }
        }
        
        isRunning = true
        isPaused = false
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentPhase = .sitting
        currentSessionType = .focus
        completedFocusSessions = 0
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
        let currentSessionType = self.currentSessionType
        let autoStartEnabled = self.autoStartEnabled
        let pomodoroModeEnabled = self.pomodoroModeEnabled
        
        // Capture Pomodoro intervals before the closure
        let focusInterval = self.focusInterval
        let shortBreakInterval = self.shortBreakInterval
        let longBreakInterval = self.longBreakInterval
        let completedFocusSessions = self.completedFocusSessions
        
        // Capture normal intervals before the closure
        let sittingInterval = self.sittingInterval
        let standingInterval = self.standingInterval
        
        // Check notification authorization first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                
                if pomodoroModeEnabled {
                    // Use captured values to avoid MainActor isolation issues
                    let focusMinutes = Int(focusInterval / 60)
                    let shortBreakMinutes = Int(shortBreakInterval / 60)
                    let longBreakMinutes = Int(longBreakInterval / 60)
                    let completedSessions = completedFocusSessions
                    
                    // Pomodoro mode notifications
                    switch currentSessionType {
                    case .focus:
                        content.title = "Focus Session Complete!"
                        content.subtitle = "You've been \(currentPhase == .sitting ? "sitting" : "standing") for \(focusMinutes) minutes."
                        content.body = autoStartEnabled ? "Time for a break." : "Time for a break. Open the menu to start your break."
                    case .shortBreak:
                        content.title = "Break Complete!"
                        content.subtitle = "You've rested for \(shortBreakMinutes) minutes."
                        content.body = autoStartEnabled ? "Ready for your next focus session?" : "Ready for your next focus session? Open the menu to start."
                    case .longBreak:
                        content.title = "Long Break Complete!"
                        content.subtitle = "You've completed \(completedSessions) focus sessions."
                        content.body = autoStartEnabled ? "Great work! Ready for more?" : "Great work! Ready for more? Open the menu to start."
                    }
                } else {
                    // Normal mode notifications (existing logic)
                    let sittingMinutes = Int(sittingInterval / 60)
                    let standingMinutes = Int(standingInterval / 60)
                    
                    switch currentPhase {
                    case .sitting:
                        content.title = "Time to Stand Up!"
                        content.subtitle = "You've been sitting for \(sittingMinutes) minutes."
                        content.body = autoStartEnabled ? "A quick stretch will do you good." : "A quick stretch will do you good. Open the menu to start your standing session."
                    case .standing:
                        content.title = "Time to Sit Down"
                        content.subtitle = "You've been standing for \(standingMinutes) minutes."
                        content.body = autoStartEnabled ? "Time to relax for a bit." : "Time to relax for a bit. Open the menu to start your sitting session."
                    }
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
        
        // Handle auto-start logic
        if autoStartEnabled {
            // Continue to next phase automatically
            switchPhase()
        } else {
            // Pause the timer and wait for manual start
            pause()
        }
    }
    
    private func switchPhase() {
        if pomodoroModeEnabled {
            switch currentSessionType {
            case .focus:
                completedFocusSessions += 1
                if completedFocusSessions % intervalsBeforeLongBreak == 0 {
                    currentSessionType = .longBreak
                    nextFire = Date().addingTimeInterval(self.longBreakInterval)
                } else {
                    currentSessionType = .shortBreak
                    nextFire = Date().addingTimeInterval(self.shortBreakInterval)
                }
            case .shortBreak, .longBreak:
                currentSessionType = .focus
                // Toggle sitting/standing for variety in focus sessions
                currentPhase = (currentPhase == .sitting) ? .standing : .sitting
                nextFire = Date().addingTimeInterval(self.focusInterval)
            }
        } else {
            // Existing logic for normal mode
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
} 
