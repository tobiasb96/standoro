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
    
    init(maxSitMinutes: Int = 45, maxStandMinutes: Int = 15, calendarFilter: Bool = true, showMenuBarCountdown: Bool = false, postureMonitoringEnabled: Bool = false, poorPostureThresholdSeconds: Int = 30, postureSensitivityDegrees: Double = 15.0) {
        self.maxSitMinutes = maxSitMinutes
        self.maxStandMinutes = maxStandMinutes
        self.calendarFilter = calendarFilter
        self.showMenuBarCountdown = showMenuBarCountdown
        self.postureMonitoringEnabled = postureMonitoringEnabled
        self.poorPostureThresholdSeconds = poorPostureThresholdSeconds
        self.postureSensitivityDegrees = postureSensitivityDegrees
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
} 