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
    
    init(maxSitMinutes: Int = 45, maxStandMinutes: Int = 15, calendarFilter: Bool = true, showMenuBarCountdown: Bool = false, postureMonitoringEnabled: Bool = false, postureNudgesEnabled: Bool = false, poorPostureThresholdSeconds: Int = 30, postureSensitivityDegrees: Double = 15.0, autoStartEnabled: Bool = true, pomodoroModeEnabled: Bool = false, focusIntervalMinutes: Int = 25, shortBreakMinutes: Int = 5, longBreakMinutes: Int = 15, intervalsBeforeLongBreak: Int = 4, moveChallengesEnabled: Bool = false, challengeAudioFeedbackEnabled: Bool = true) {
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
} 