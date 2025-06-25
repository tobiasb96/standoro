import Foundation
import Combine
import SwiftData

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

/// Statistics collector that persists data using SwiftData ActivityRecord model
@MainActor
final class StatsService: ObservableObject {
    // MARK: - Published summary values (computed from persistent data)
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
    
    // MARK: - Model Context
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshStats()
    }
    
    // MARK: - Recording helpers
    func recordPhase(type: SessionType,
                     phase: PosturePhase?,
                     seconds: TimeInterval,
                     skipped: Bool) {
        
        // Create and save ActivityRecord
        guard let ctx = modelContext else {
            return
        }
        
        let record = ActivityRecord(
            kind: type.rawValue,
            secondsElapsed: seconds,
            postureGoal: phase?.rawValue ?? "ignored",
            skipped: skipped
        )
        
        ctx.insert(record)
        
        do {
            try ctx.save()
        } catch {
            // Log error but don't crash the app
            #if DEBUG
            print("StatsService: Failed to save activity record: \(error)")
            #endif
        }
        
        // Update published values
        refreshStats()
    }

    func recordChallengeAction(completed: Bool) {
        guard let ctx = modelContext else {
            return
        }
        
        let record = ActivityRecord(
            kind: "challenge",
            secondsElapsed: 0,
            postureGoal: "ignored",
            skipped: !completed,
            challengeCompleted: completed
        )
        
        ctx.insert(record)
        
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("StatsService: Failed to save challenge record: \(error)")
            #endif
        }
        
        // Update published values
        refreshStats()
    }

    func recordPostureAlert() {
        guard let ctx = modelContext else {
            return
        }
        
        let record = ActivityRecord(
            kind: "posture_alert",
            secondsElapsed: 0,
            postureGoal: "ignored",
            postureReminders: 1
        )
        
        ctx.insert(record)
        
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("StatsService: Failed to save posture alert record: \(error)")
            #endif
        }
        
        // Update published values
        refreshStats()
    }
    
    // MARK: - Refresh and aggregation
    func refreshStats() {
        guard let ctx = modelContext else {
            return
        }
        
        // Calculate date range based on selected period
        let calendar = Calendar.current
        let now = Date()
        let startOfPeriod: Date
        
        switch selectedPeriod {
        case .day:
            startOfPeriod = calendar.startOfDay(for: now)
        case .week:
            startOfPeriod = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            startOfPeriod = calendar.dateInterval(of: .month, for: now)?.start ?? now
        }
        
        // Fetch records for the selected period
        let descriptor = FetchDescriptor<ActivityRecord>(
            predicate: #Predicate<ActivityRecord> { record in
                record.timestamp >= startOfPeriod
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            let records = try ctx.fetch(descriptor)
            calculateStats(from: records)
        } catch {
            #if DEBUG
            print("StatsService: Failed to fetch records: \(error)")
            #endif
        }
    }
    
    private func calculateStats(from records: [ActivityRecord]) {
        // Reset counters
        focusSeconds = 0
        sittingSeconds = 0
        standingSeconds = 0
        breaksTaken = 0
        breaksSkipped = 0
        challengesCompleted = 0
        challengesDiscarded = 0
        postureAlerts = 0
        
        for record in records {
            switch record.kind {
            case "focus":
                focusSeconds += record.secondsElapsed
                if record.postureGoal == "sitting" {
                    sittingSeconds += record.secondsElapsed
                } else if record.postureGoal == "standing" {
                    standingSeconds += record.secondsElapsed
                }
            case "shortBreak", "longBreak":
                if record.skipped {
                    breaksSkipped += 1
                } else {
                    breaksTaken += 1
                }
            case "challenge":
                if record.challengeCompleted {
                    challengesCompleted += 1
                } else {
                    challengesDiscarded += 1
                }
            case "posture_alert":
                postureAlerts += record.postureReminders
            default:
                break
            }
        }
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    func setAggregationPeriod(_ period: AggregationPeriod) {
        selectedPeriod = period
        refreshStats()
    }
} 
