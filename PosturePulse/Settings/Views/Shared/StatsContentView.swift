import SwiftUI
import Charts

struct StatsContentView: View {
    @ObservedObject var statsService: StatsService
    
    private var postureData: [PostureSegment] {
        [
            PostureSegment(label: "Sitting", seconds: statsService.sittingSeconds),
            PostureSegment(label: "Standing", seconds: statsService.standingSeconds)
        ]
    }
    
    private var totalFocusMinutes: Int {
        Int(statsService.focusSeconds / 60)
    }
    
    private var breakCompliance: Double {
        let total = statsService.breaksTaken + statsService.breaksSkipped
        guard total > 0 else { return 1.0 }
        return Double(statsService.breaksTaken) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Period selector
            HStack {
                Text("Time Period:")
                    .font(.headline)
                Picker("Period", selection: $statsService.selectedPeriod) {
                    ForEach(AggregationPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Button("Refresh") {
                    statsService.refreshStats()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 10)
            
            // Stats cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Focus Minutes Card
                StatCard(
                    title: "Focus Minutes",
                    value: "\(totalFocusMinutes)",
                    subtitle: "Total focused time",
                    icon: "brain.head.profile",
                    color: .blue
                )
                
                // Break Compliance Card
                StatCard(
                    title: "Break Compliance",
                    value: "\(Int(breakCompliance * 100))%",
                    subtitle: "\(statsService.breaksTaken) taken / \(statsService.breaksSkipped) skipped",
                    icon: "cup.and.saucer",
                    color: .green
                )
                
                // Challenges Card
                StatCard(
                    title: "Challenges",
                    value: "\(statsService.challengesCompleted)",
                    subtitle: "Completed",
                    icon: "trophy",
                    color: .orange
                )
                
                // Posture Alerts Card
                StatCard(
                    title: "Posture Alerts",
                    value: "\(statsService.postureAlerts)",
                    subtitle: "Reminders sent",
                    icon: "airpods",
                    color: .red
                )
            }
            
            // Posture Chart Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Sitting vs Standing")
                    .font(.headline)
                
                Chart(postureData) { segment in
                    BarMark(
                        x: .value("Minutes", segment.minutes),
                        y: .value("Posture", segment.label)
                    )
                    .foregroundStyle(by: .value("Posture", segment.label))
                }
                .frame(height: 200)
                .chartForegroundStyleScale([
                    "Sitting": Color.blue,
                    "Standing": Color.green
                ])
            }
            .padding(16)
            .background(Color.settingsCard)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            statsService.refreshStats()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .bold()
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.settingsCard)
        .cornerRadius(12)
    }
}

private struct PostureSegment: Identifiable {
    let id = UUID()
    let label: String
    let seconds: TimeInterval
    
    var minutes: Double { seconds / 60.0 }
}

#Preview {
    StatsContentView(statsService: {
        let service = StatsService()
        service.recordPhase(type: .focus, phase: .sitting, seconds: 60*25, skipped: false)
        service.recordPhase(type: .focus, phase: .standing, seconds: 60*15, skipped: false)
        service.breaksTaken = 3
        service.breaksSkipped = 1
        service.recordChallengeCompletion()
        service.recordPostureAlert()
        service.recordPostureAlert()
        return service
    }())
    .background(Color.settingsBackground)
} 