import SwiftUI
import SwiftData
import EventKit
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @ObservedObject var calendarService: CalendarService
    
    @State private var selection: SidebarItem? = .standAndFocus
    
    enum SidebarItem: Hashable {
        case stats, standAndFocus, moveAndRest, keepPosture, general, about
    }
    
    private var userPrefs: UserPrefs {
        if let p = prefs.first {
            return p
        } else {
            // This is a fallback, but the view should ideally handle the empty state.
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            return newPrefs
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection)
                .frame(width: 220)
            
            Divider()

            VStack(spacing: 0) {
                // Header
                if let sectionTitle = title(for: selection), !sectionTitle.isEmpty {
                    VStack(spacing: 8) {
                        Text(sectionTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.settingsHeader)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if let subheader = subheader(for: selection) {
                            Text(subheader)
                                .font(.system(size: 13))
                                .foregroundColor(.settingsSubheader)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 18)
                        }
                    }
                    .padding(.top, 16)
                }
                // Content
                ScrollView {
                    ZStack {
                        switch selection {
                        case .stats:
                            Text("Stats (Coming Soon)")
                                .font(.body)
                                .foregroundColor(.settingsSubheader)
                        case .standAndFocus:
                            StandAndFocusSettingsContentView(
                                userPrefs: userPrefs,
                                scheduler: scheduler,
                                ctx: ctx,
                                showExplanations: false
                            )
                        case .moveAndRest:
                            MoveAndRestSettingsContentView(
                                userPrefs: userPrefs,
                                ctx: ctx,
                                showExplanations: false
                            )
                        case .keepPosture:
                            KeepPostureSettingsContentView(
                                userPrefs: userPrefs,
                                motionService: motionService,
                                ctx: ctx,
                                showExplanations: false
                            )
                        case .general:
                            GeneralSettingsContentView(
                                userPrefs: userPrefs,
                                calendarService: calendarService,
                                scheduler: scheduler,
                                ctx: ctx,
                                showExplanations: false
                            )
                        case .about:
                            Text("About PosturePulse (Coming Soon)")
                                .font(.body)
                                .foregroundColor(.settingsSubheader)
                        case nil:
                            Text("Select a category")
                                .font(.body)
                                .foregroundColor(.settingsSubheader)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .frame(minWidth: 875, idealWidth: 1000, minHeight: 562, idealHeight: 687)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .foregroundColor(.white)
        .onAppear {
            // Set up calendar service with scheduler
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Set up calendar service with motion service
            motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Set up auto-start setting
            scheduler.setAutoStartEnabled(userPrefs.autoStartEnabledValue)
            
            // Set up motion service
            if userPrefs.postureMonitoringEnabledValue {
                motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
            }
            
            // Always enable high frequency mode when settings are opened
            // This allows users to see real-time angles even if posture monitoring is disabled
            if motionService.isAuthorized {
                motionService.enablePostureHighFrequencyMode()
                
                // Start monitoring if not already active, so we can show real-time angles
                if !motionService.isMonitoring {
                    motionService.startMonitoring()
                }
            }
        }
        .onDisappear {
            // Save context when the window is closed
            try? ctx.save()
            
            // Always disable high frequency mode when settings are closed
            if motionService.isAuthorized {
                motionService.disablePostureHighFrequencyMode()
                
                // Stop monitoring if it was started just for the settings window
                // and posture monitoring is disabled in preferences
                if motionService.isMonitoring && !userPrefs.postureMonitoringEnabledValue {
                    motionService.stopMonitoring()
                }
            }
        }
    }
    
    private func title(for item: SidebarItem?) -> String? {
        switch item {
        case .stats:
            return "Stats"
        case .standAndFocus:
            return "Stand + Focus"
        case .moveAndRest:
            return "Move + Rest"
        case .keepPosture:
            return "Keep Posture"
        case .general:
            return "General Settings"
        case .about:
            return "About"
        case nil:
            return nil
        }
    }
    
    private func subheader(for item: SidebarItem?) -> String? {
        switch item {
        case .standAndFocus:
            return "Configure your standing reminders and focus sessions. Choose between simple posture timers or structured Pomodoro sessions to boost your productivity while staying active."
        case .moveAndRest:
            return "Take regular movement breaks with guided exercises and stretches. This feature helps you stay active and prevent stiffness during long work sessions."
        case .keepPosture:
            return "Monitor your sitting posture using AirPods to detect when you're slouching or leaning too far. This helps you maintain better posture and reduce neck and back strain."
        case .general:
            return "Customize how PosturePulse behaves and integrates with your system."
        default:
            return nil
        }
    }
}

#Preview {
    SettingsView(scheduler: Scheduler(), motionService: MotionService(), calendarService: CalendarService())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 