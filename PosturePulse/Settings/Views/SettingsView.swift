import SwiftUI
import SwiftData
import EventKit
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var motionService: MotionService
    @StateObject private var calendarService = CalendarService()
    
    @State private var selectedTab = 0
    
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
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Standing", icon: "figure.stand", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "Posture", icon: "airpods", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Tab content
            TabView(selection: $selectedTab) {
                GeneralTabView(userPrefs: userPrefs, calendarService: calendarService, scheduler: scheduler, ctx: ctx)
                    .tag(0)
                
                StandingRemindersTabView(userPrefs: userPrefs, scheduler: scheduler, ctx: ctx)
                    .tag(1)
                
                PostureTabView(userPrefs: userPrefs, motionService: motionService, ctx: ctx)
                    .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 450, height: 600)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .foregroundColor(.white)
        .onAppear {
            // Set up calendar service with scheduler
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
            // Set up calendar service with motion service
            motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
            
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
}

#Preview {
    SettingsView(scheduler: Scheduler(), motionService: MotionService())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 