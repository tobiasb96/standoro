//
//  Item.swift
//  PosturePulse
//
//  Created by Tobias Blanck on 22.06.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
