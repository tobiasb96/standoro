import Foundation
import UserNotifications
import Combine

enum PosturePhase: String {
    case sitting = "sitting"
    case standing = "standing"
}

enum SessionType: String {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
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
    @Published private(set) var completedFocusSessions: Int = 0  // Publishes updates so UI can react in real-time
    @Published var pomodoroModeEnabled: Bool = false
    private var _focusInterval: TimeInterval = 25 * 60 // Default 25 minutes for Pomodoro
    private var _shortBreakInterval: TimeInterval = 5 * 60 // Default 5 minutes
    private var _longBreakInterval: TimeInterval = 15 * 60 // Default 15 minutes
    private var _intervalsBeforeLongBreak: Int = 4 // Default 4 focus sessions
    
    // Posture Nudge Feature
    private var postureNudgesEnabled: Bool = false
    private var motionService: MotionService? = nil
    var notificationService: NotificationService? = nil
    private var postureNudgeTimer: Timer?
    private var nextPostureNudgeInterval: TimeInterval = 0
    private var lastPostureNudgeTime: Date?
    private let minNudgeInterval: TimeInterval = 15 * 60 // 15 minutes
    private let maxNudgeInterval: TimeInterval = 45 * 60 // 45 minutes
    
    // Stats recording
    private var statsService: StatsService?
    private var phaseStartTime: Date?
    private var userPrefs: UserPrefs?
    
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
        guard self.pomodoroModeEnabled != enabled else { return }
        
        self.pomodoroModeEnabled = enabled
        
        if enabled {
            // When enabling Pomodoro, reset state for a clean start
            completedFocusSessions = 0
            currentSessionType = .focus
            if isRunning && !isPaused {
                // Also reset the timer to the new focus interval
                nextFire = Date().addingTimeInterval(self.focusInterval)
            }
        } else {
            // When disabling Pomodoro, reset to a standard sitting phase
            currentPhase = .sitting
            if isRunning && !isPaused {
                nextFire = Date().addingTimeInterval(self.sittingInterval)
            }
        }
        
        saveState()
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
        
        phaseStartTime = Date()
        isRunning = true
        isPaused = false
        
        saveState()
    }
    
    func stop() {
        // Record current phase before stopping
        recordCurrentPhase(skipped: false)
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        currentPhase = .sitting
        currentSessionType = .focus
        completedFocusSessions = 0
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        phaseStartTime = nil
        
        saveState()
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        
        pauseStartTime = Date()
        remainingTimeWhenPaused = nextFire.timeIntervalSinceNow
        isPaused = true
        
        saveState()
    }
    
    func resume() {
        guard isRunning, isPaused, let _ = pauseStartTime else { return }
        
        // Calculate new next fire time based on remaining time when paused
        nextFire = Date().addingTimeInterval(remainingTimeWhenPaused)
        isPaused = false
        pauseStartTime = nil
        remainingTimeWhenPaused = 0
        
        saveState()
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
        let skippingBreak = pomodoroModeEnabled && currentSessionType != .focus
        recordCurrentPhase(skipped: skippingBreak)
        phaseStartTime = Date()
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
        let completedSessions = self.completedFocusSessions
        
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
                    _ = Int(longBreakInterval / 60) // Unused variable replaced with underscore
                    
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
        recordCurrentPhase(skipped: false)
        phaseStartTime = Date()
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
        
        saveState()
    }
    
    // Public setters for integration
    func setMotionService(_ motionService: MotionService) {
        self.motionService = motionService
        self.notificationService = motionService.notificationService
    }
    
    func setPostureNudgesEnabled(_ enabled: Bool) {
        postureNudgesEnabled = enabled
        if enabled {
            startPostureNudgeTimer()
        } else {
            stopPostureNudgeTimer()
        }
    }
    
    private func startPostureNudgeTimer() {
        stopPostureNudgeTimer()
        scheduleNextPostureNudge()
        postureNudgeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPostureNudge()
            }
        }
    }
    
    private func stopPostureNudgeTimer() {
        postureNudgeTimer?.invalidate()
        postureNudgeTimer = nil
    }
    
    private func checkPostureNudge() {
        guard postureNudgesEnabled,
              let motionService = motionService,
              let notificationService = notificationService else { return }
        
        // Only nudge during work periods (sitting/focus)
        let isWorkPeriod: Bool = {
            if pomodoroModeEnabled {
                return currentSessionType == .focus
            } else {
                return currentPhase == .sitting
            }
        }()
        if !isWorkPeriod { return }
        
        // Check if it's time for the next nudge
        let now = Date()
        if let last = lastPostureNudgeTime, now.timeIntervalSince(last) < nextPostureNudgeInterval {
            return
        }
        
        // Send nudge
        notificationService.sendRandomPostureNudge()
        lastPostureNudgeTime = now
        scheduleNextPostureNudge()
    }
    
    private func scheduleNextPostureNudge() {
        nextPostureNudgeInterval = Double.random(in: minNudgeInterval...maxNudgeInterval)
    }
    
    func setStatsService(_ service: StatsService) {
        self.statsService = service
    }
    
    func setUserPrefs(_ prefs: UserPrefs) {
        self.userPrefs = prefs
        // Restore state from UserPrefs on first setup
        restoreStateFromUserPrefs(prefs)
    }
    
    private func saveState() {
        guard let prefs = userPrefs else { return }
        saveStateToUserPrefs(prefs)
        
        // Trigger a save to the model context
        // Note: We can't directly access the model context from here,
        // so we'll use a notification to trigger a save from the view layer
        NotificationCenter.default.post(name: NSNotification.Name("SaveUserPrefs"), object: nil)
    }
    
    private func recordCurrentPhase(skipped: Bool) {
        guard let statsService, let start = phaseStartTime else { 
            print("📊 Stats: Cannot record - statsService: \(statsService != nil), phaseStartTime: \(phaseStartTime != nil)")
            return 
        }
        let elapsed = max(Date().timeIntervalSince(start), 0)
        print("📊 Stats: Recording phase - type: \(currentSessionType), phase: \(currentPhase), elapsed: \(Int(elapsed))s, skipped: \(skipped)")
        
        if pomodoroModeEnabled {
            statsService.recordPhase(type: currentSessionType,
                                     phase: currentSessionType == .focus ? currentPhase : nil,
                                     seconds: elapsed,
                                     skipped: skipped)
        } else {
            statsService.recordPhase(type: .focus,
                                     phase: currentPhase,
                                     seconds: elapsed,
                                     skipped: skipped)
        }
        print("📊 Stats: After recording - focus: \(Int(statsService.focusSeconds/60))m, sitting: \(Int(statsService.sittingSeconds/60))m, standing: \(Int(statsService.standingSeconds/60))m, breaks: \(statsService.breaksTaken)/\(statsService.breaksSkipped)")
    }
    
    // MARK: - State Persistence
    
    func saveStateToUserPrefs(_ userPrefs: UserPrefs) {
        // Save current state to UserPrefs for persistence
        userPrefs.completedFocusSessions = completedFocusSessions
        userPrefs.currentPhase = currentPhase.rawValue
        userPrefs.currentSessionType = currentSessionType.rawValue
        userPrefs.isRunning = isRunning
        userPrefs.isPaused = isPaused
        userPrefs.nextFireTime = nextFire
        userPrefs.remainingTimeWhenPaused = remainingTimeWhenPaused
        userPrefs.phaseStartTime = phaseStartTime
    }
    
    func restoreStateFromUserPrefs(_ userPrefs: UserPrefs) {
        // Restore state from UserPrefs
        completedFocusSessions = userPrefs.completedFocusSessionsValue
        currentPhase = PosturePhase(rawValue: userPrefs.currentPhaseValue) ?? .sitting
        currentSessionType = SessionType(rawValue: userPrefs.currentSessionTypeValue) ?? .focus
        isRunning = userPrefs.isRunningValue
        isPaused = userPrefs.isPausedValue
        nextFire = userPrefs.nextFireTimeValue
        remainingTimeWhenPaused = userPrefs.remainingTimeWhenPausedValue
        phaseStartTime = userPrefs.phaseStartTimeValue
        
        // Restart timer if it was running
        if isRunning && !isPaused {
            startTimer()
        }
    }
    
    private func startTimer() {
        // Cancel existing timer
        timer?.invalidate()
        timer = nil
        
        // Create new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimer()
            }
        }
    }
} 
