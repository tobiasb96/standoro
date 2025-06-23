//
//  SettingsModels.swift
//  PosturePulse
//
//  Created by Tobias Blanck on 22.06.25.
//

import Foundation
import SwiftData

@Model
class UserPrefs {
    var maxSitMinutes: Int
    var maxStandMinutes: Int
    var calendarFilter: Bool
    var showMenuBarCountdown: Bool
    var postureMonitoringEnabled: Bool?
    var poorPostureThresholdSeconds: Int?
    var postureSensitivityDegrees: Double?
    var autoStartEnabled: Bool?
    
    // Pomodoro settings
    var pomodoroModeEnabled: Bool?
    var focusIntervalMinutes: Int?
    var shortBreakMinutes: Int?
    var longBreakMinutes: Int?
    var intervalsBeforeLongBreak: Int?
    
    init(maxSitMinutes: Int = 45, maxStandMinutes: Int = 15, calendarFilter: Bool = true, showMenuBarCountdown: Bool = false, postureMonitoringEnabled: Bool = false, poorPostureThresholdSeconds: Int = 30, postureSensitivityDegrees: Double = 15.0, autoStartEnabled: Bool = true, pomodoroModeEnabled: Bool = false, focusIntervalMinutes: Int = 25, shortBreakMinutes: Int = 5, longBreakMinutes: Int = 15, intervalsBeforeLongBreak: Int = 4) {
        self.maxSitMinutes = maxSitMinutes
        self.maxStandMinutes = maxStandMinutes
        self.calendarFilter = calendarFilter
        self.showMenuBarCountdown = showMenuBarCountdown
        self.postureMonitoringEnabled = postureMonitoringEnabled
        self.poorPostureThresholdSeconds = poorPostureThresholdSeconds
        self.postureSensitivityDegrees = postureSensitivityDegrees
        self.autoStartEnabled = autoStartEnabled
        self.pomodoroModeEnabled = pomodoroModeEnabled
        self.focusIntervalMinutes = focusIntervalMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.intervalsBeforeLongBreak = intervalsBeforeLongBreak
    }
    
    // Computed properties to provide default values
    var postureMonitoringEnabledValue: Bool {
        get { postureMonitoringEnabled ?? false }
        set { postureMonitoringEnabled = newValue }
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
} 