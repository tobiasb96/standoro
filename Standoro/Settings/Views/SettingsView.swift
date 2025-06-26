import SwiftUI
import SwiftData
import EventKit
import Combine
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    let userPrefs: UserPrefs
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var statsService: StatsService
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var selection: SidebarItem?
    
    let initialSelection: SidebarItem?
    
    init(userPrefs: UserPrefs, scheduler: Scheduler, motionService: MotionService, calendarService: CalendarService, statsService: StatsService, initialSelection: SidebarItem? = .standAndFocus) {
        self.userPrefs = userPrefs
        self.scheduler = scheduler
        self.motionService = motionService
        self.calendarService = calendarService
        self.statsService = statsService
        self.initialSelection = initialSelection
        self._selection = State(initialValue: initialSelection)
    }
    
    enum SidebarItem: Hashable {
        case stats, standAndFocus, moveAndRest, keepPosture, general, about, upgrade
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $selection, isProUnlocked: purchaseManager.isProUnlocked)
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
                                .padding(.bottom, 10)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 16)
                }
                // Content
                ScrollView {
                    ZStack {
                        switch selection {
                        case .stats:
                            if purchaseManager.isProUnlocked {
                                StatsContentView(statsService: statsService)
                            } else {
                                ProUpgradeView()
                            }
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
                            if purchaseManager.isProUnlocked {
                                KeepPostureSettingsContentView(
                                    userPrefs: userPrefs,
                                    motionService: motionService,
                                    scheduler: scheduler,
                                    ctx: ctx,
                                    showExplanations: false
                                )
                            } else {
                                ProUpgradeView()
                            }
                        case .general:
                            GeneralSettingsContentView(
                                userPrefs: userPrefs,
                                calendarService: calendarService,
                                scheduler: scheduler,
                                ctx: ctx,
                                showExplanations: false
                            )
                        case .upgrade:
                            ProUpgradeView()
                        case .about:
                            AboutView()
                        case nil:
                            Text("Select a category")
                                .font(.body)
                                .foregroundColor(.settingsSubheader)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .frame(minWidth: 875, idealWidth: 1000, minHeight: 562, idealHeight: 687)
        .background(Color.settingsBackground)
        .foregroundColor(.white)
        .onAppear {
            // Set up calendar service with scheduler
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Set up calendar service with motion service
            motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Set up auto-start setting
            scheduler.setAutoStartEnabled(userPrefs.autoStartEnabledValue)
            
            // Connect scheduler to motion service for posture nudges
            scheduler.setMotionService(motionService)
            
            // Set up posture nudges if enabled
            scheduler.setPostureNudgesEnabled(userPrefs.postureNudgesEnabledValue)
            
            // Set up motion service
            if userPrefs.postureMonitoringEnabledValue {
                motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
            }
            
            // Set model context for stats service
            statsService.setModelContext(ctx)
            
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
        .onChange(of: selection) { _, newSelection in
            if newSelection == .stats {
                statsService.refreshStats()
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
        case .upgrade:
            return purchaseManager.isProUnlocked ? "Thank You" : "Standoro Pro"
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
            return "Customize how Standoro behaves and integrates with your system."
        case .upgrade:
            return purchaseManager.isProUnlocked ? "You have unlocked all Pro features." : "Upgrade once, enjoy forever."
        default:
            return nil
        }
    }
}

#Preview {
    SettingsView(userPrefs: UserPrefs(), scheduler: Scheduler(), motionService: MotionService(), calendarService: CalendarService(), statsService: StatsService(), initialSelection: .standAndFocus)
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 