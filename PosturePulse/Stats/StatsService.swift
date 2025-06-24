import Foundation
import Combine

enum AggregationPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

/// Lean statistics collector. Stores counters in-memory for now. Persistence will be added later.
@MainActor
final class StatsService: ObservableObject {
    // MARK: - Published summary values
    @Published var focusSeconds: TimeInterval = 0
    @Published var sittingSeconds: TimeInterval = 0
    @Published var standingSeconds: TimeInterval = 0
    @Published var breaksTaken: Int = 0
    @Published var breaksSkipped: Int = 0
    @Published var challengesCompleted: Int = 0
    @Published var challengesDiscarded: Int = 0
    @Published var postureAlerts: Int = 0
    
    // MARK: - Aggregation
    @Published var selectedPeriod: AggregationPeriod = .day
    
    // MARK: - Recording helpers
    func recordPhase(type: SessionType,
                     phase: PosturePhase?,
                     seconds: TimeInterval,
                     skipped: Bool) {
        print("📊 StatsService: recordPhase called - type: \(type), seconds: \(Int(seconds)), skipped: \(skipped)")
        
        switch type {
        case .focus:
            focusSeconds += seconds
            print("📊 StatsService: Added \(Int(seconds))s to focus (total: \(Int(focusSeconds/60))m)")
            if let phase {
                switch phase {
                case .sitting:
                    sittingSeconds += seconds
                    print("📊 StatsService: Added \(Int(seconds))s to sitting (total: \(Int(sittingSeconds/60))m)")
                case .standing:
                    standingSeconds += seconds
                    print("📊 StatsService: Added \(Int(seconds))s to standing (total: \(Int(standingSeconds/60))m)")
                }
            }
        case .shortBreak, .longBreak:
            if skipped {
                breaksSkipped += 1
                print("📊 StatsService: Break skipped (total skipped: \(breaksSkipped))")
            } else {
                breaksTaken += 1
                print("📊 StatsService: Break taken (total taken: \(breaksTaken))")
            }
        }
    }

    func recordChallengeAction(completed: Bool) {
        if completed {
            challengesCompleted += 1
            print("📊 StatsService: Challenge completed (total: \(challengesCompleted))")
        } else {
            challengesDiscarded += 1
            print("📊 StatsService: Challenge discarded (total: \(challengesDiscarded))")
        }
    }

    func recordPostureAlert() {
        postureAlerts += 1
        print("📊 StatsService: Posture alert recorded (total: \(postureAlerts))")
    }
    
    // MARK: - Refresh and aggregation
    func refreshStats() {
        // For now, just trigger UI update
        // In Phase 4, this would load from SwiftData based on selectedPeriod
        objectWillChange.send()
    }
    
    func setAggregationPeriod(_ period: AggregationPeriod) {
        selectedPeriod = period
        refreshStats()
    }
} 
