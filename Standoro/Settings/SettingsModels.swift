import Foundation
import SwiftData

@Model
class UserPrefs {
    var maxSitMinutes: Int
    var maxStandMinutes: Int
    var calendarFilter: Bool
    var showMenuBarCountdown: Bool
    var postureMonitoringEnabled: Bool?
    var postureNudgesEnabled: Bool?
    var poorPostureThresholdSeconds: Int?
    var postureSensitivityDegrees: Double?
    var autoStartEnabled: Bool?
    
    // Pomodoro settings
    var pomodoroModeEnabled: Bool?
    var focusIntervalMinutes: Int?
    var shortBreakMinutes: Int?
    var longBreakMinutes: Int?
    var intervalsBeforeLongBreak: Int?
    
    // Move challenges settings
    var moveChallengesEnabled: Bool?
    var challengeAudioFeedbackEnabled: Bool?
    
    // Scheduler state persistence
    var completedFocusSessions: Int?
    var currentPhase: String?
    var currentSessionType: String?
    var isRunning: Bool?
    var isPaused: Bool?
    var nextFireTime: Date?
    var remainingTimeWhenPaused: TimeInterval?
    var phaseStartTime: Date?
    
    // Posture calibration persistence
    var calibratedPitch: Double?
    var calibratedRoll: Double?
    var isCalibrated: Bool?
    
    init(maxSitMinutes: Int = 45, maxStandMinutes: Int = 15, calendarFilter: Bool = true, showMenuBarCountdown: Bool = false, postureMonitoringEnabled: Bool = false, postureNudgesEnabled: Bool = false, poorPostureThresholdSeconds: Int = 30, postureSensitivityDegrees: Double = 15.0, autoStartEnabled: Bool = true, pomodoroModeEnabled: Bool = false, focusIntervalMinutes: Int = 25, shortBreakMinutes: Int = 5, longBreakMinutes: Int = 15, intervalsBeforeLongBreak: Int = 4, moveChallengesEnabled: Bool = false, challengeAudioFeedbackEnabled: Bool = true, completedFocusSessions: Int = 0, currentPhase: String = "sitting", currentSessionType: String = "focus", isRunning: Bool = false, isPaused: Bool = false, nextFireTime: Date = Date(), remainingTimeWhenPaused: TimeInterval = 0, phaseStartTime: Date? = nil, calibratedPitch: Double? = nil, calibratedRoll: Double? = nil, isCalibrated: Bool? = nil) {
        self.maxSitMinutes = maxSitMinutes
        self.maxStandMinutes = maxStandMinutes
        self.calendarFilter = calendarFilter
        self.showMenuBarCountdown = showMenuBarCountdown
        self.postureMonitoringEnabled = postureMonitoringEnabled
        self.postureNudgesEnabled = postureNudgesEnabled
        self.poorPostureThresholdSeconds = poorPostureThresholdSeconds
        self.postureSensitivityDegrees = postureSensitivityDegrees
        self.autoStartEnabled = autoStartEnabled
        self.pomodoroModeEnabled = pomodoroModeEnabled
        self.focusIntervalMinutes = focusIntervalMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.intervalsBeforeLongBreak = intervalsBeforeLongBreak
        self.moveChallengesEnabled = moveChallengesEnabled
        self.challengeAudioFeedbackEnabled = challengeAudioFeedbackEnabled
        self.completedFocusSessions = completedFocusSessions
        self.currentPhase = currentPhase
        self.currentSessionType = currentSessionType
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.nextFireTime = nextFireTime
        self.remainingTimeWhenPaused = remainingTimeWhenPaused
        self.phaseStartTime = phaseStartTime
        self.calibratedPitch = calibratedPitch
        self.calibratedRoll = calibratedRoll
        self.isCalibrated = isCalibrated
    }
    
    // Computed properties to provide default values
    var postureMonitoringEnabledValue: Bool {
        get { postureMonitoringEnabled ?? false }
        set { postureMonitoringEnabled = newValue }
    }
    
    var postureNudgesEnabledValue: Bool {
        get { postureNudgesEnabled ?? false }
        set { postureNudgesEnabled = newValue }
    }
    
    var poorPostureThresholdSecondsValue: Int {
        get { poorPostureThresholdSeconds ?? 30 }
        set { poorPostureThresholdSeconds = newValue }
    }
    
    var postureSensitivityDegreesValue: Double {
        get { postureSensitivityDegrees ?? 15.0 }
        set { postureSensitivityDegrees = newValue }
    }
    
    var autoStartEnabledValue: Bool {
        get { autoStartEnabled ?? true }
        set { autoStartEnabled = newValue }
    }
    
    // Pomodoro computed properties
    var pomodoroModeEnabledValue: Bool {
        get { pomodoroModeEnabled ?? false }
        set { pomodoroModeEnabled = newValue }
    }
    
    var focusIntervalMinutesValue: Int {
        get { focusIntervalMinutes ?? 25 }
        set { focusIntervalMinutes = newValue }
    }
    
    var shortBreakMinutesValue: Int {
        get { shortBreakMinutes ?? 5 }
        set { shortBreakMinutes = newValue }
    }
    
    var longBreakMinutesValue: Int {
        get { longBreakMinutes ?? 15 }
        set { longBreakMinutes = newValue }
    }
    
    var intervalsBeforeLongBreakValue: Int {
        get { intervalsBeforeLongBreak ?? 4 }
        set { intervalsBeforeLongBreak = newValue }
    }
    
    // Move challenges computed property
    var moveChallengesEnabledValue: Bool {
        get { moveChallengesEnabled ?? false }
        set { moveChallengesEnabled = newValue }
    }
    
    var challengeAudioFeedbackEnabledValue: Bool {
        get { challengeAudioFeedbackEnabled ?? true }
        set { challengeAudioFeedbackEnabled = newValue }
    }
    
    // Scheduler state computed properties
    var completedFocusSessionsValue: Int {
        get { completedFocusSessions ?? 0 }
        set { completedFocusSessions = newValue }
    }
    
    var currentPhaseValue: String {
        get { currentPhase ?? "sitting" }
        set { currentPhase = newValue }
    }
    
    var currentSessionTypeValue: String {
        get { currentSessionType ?? "focus" }
        set { currentSessionType = newValue }
    }
    
    var isRunningValue: Bool {
        get { isRunning ?? false }
        set { isRunning = newValue }
    }
    
    var isPausedValue: Bool {
        get { isPaused ?? false }
        set { isPaused = newValue }
    }
    
    var nextFireTimeValue: Date {
        get { nextFireTime ?? Date() }
        set { nextFireTime = newValue }
    }
    
    var remainingTimeWhenPausedValue: TimeInterval {
        get { remainingTimeWhenPaused ?? 0 }
        set { remainingTimeWhenPaused = newValue }
    }
    
    var phaseStartTimeValue: Date? {
        get { phaseStartTime }
        set { phaseStartTime = newValue }
    }
    
    // Posture calibration computed properties
    var calibratedPitchValue: Double? {
        get { calibratedPitch }
        set { calibratedPitch = newValue }
    }
    
    var calibratedRollValue: Double? {
        get { calibratedRoll }
        set { calibratedRoll = newValue }
    }
    
    var isCalibratedValue: Bool {
        get { isCalibrated ?? false }
        set { isCalibrated = newValue }
    }
} 