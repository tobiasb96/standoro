//
//  Item.swift
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
    
    init(maxSitMinutes: Int = 45, maxStandMinutes: Int = 15, calendarFilter: Bool = true, showMenuBarCountdown: Bool = false) {
        self.maxSitMinutes = maxSitMinutes
        self.maxStandMinutes = maxStandMinutes
        self.calendarFilter = calendarFilter
        self.showMenuBarCountdown = showMenuBarCountdown
    }
}
