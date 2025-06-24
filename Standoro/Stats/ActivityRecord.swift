import Foundation
import SwiftData

@Model
final class ActivityRecord {
    var id: UUID
    var sessionId: UUID
    var timestamp: Date
    var kind: String // focus | shortBreak | longBreak
    var secondsElapsed: Double
    var postureGoal: String // sit | stand | ignored
    var postureReminders: Int
    var skipped: Bool
    var challengeCompleted: Bool

    init(
        sessionId: UUID = UUID(),
        timestamp: Date = .now,
        kind: String,
        secondsElapsed: Double = 0,
        postureGoal: String = "ignored",
        postureReminders: Int = 0,
        skipped: Bool = false,
        challengeCompleted: Bool = false
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.kind = kind
        self.secondsElapsed = secondsElapsed
        self.postureGoal = postureGoal
        self.postureReminders = postureReminders
        self.skipped = skipped
        self.challengeCompleted = challengeCompleted
    }
} 