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
                TabButton(title: "Intervals", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Permissions", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "Posture", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Tab content
            TabView(selection: $selectedTab) {
                IntervalsTabView(userPrefs: userPrefs, scheduler: scheduler, ctx: ctx)
                    .tag(0)
                
                PermissionsTabView(userPrefs: userPrefs, calendarService: calendarService, scheduler: scheduler, ctx: ctx)
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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct IntervalsTabView: View {
    let userPrefs: UserPrefs
    let scheduler: Scheduler
    let ctx: ModelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sitting Interval")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(userPrefs.maxSitMinutes) },
                                set: { 
                                    userPrefs.maxSitMinutes = Int($0)
                                    scheduler.sittingInterval = TimeInterval($0 * 60)
                                    try? ctx.save()
                                }
                            ),
                            in: 15...120,
                            step: 5
                        )
                        
                        Text("\(userPrefs.maxSitMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Standing Interval")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(userPrefs.maxStandMinutes) },
                                set: { 
                                    userPrefs.maxStandMinutes = Int($0)
                                    scheduler.standingInterval = TimeInterval($0 * 60)
                                    try? ctx.save()
                                }
                            ),
                            in: 5...60,
                            step: 5
                        )
                        
                        Text("\(userPrefs.maxStandMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Menu Bar")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Toggle("Show countdown in menu bar",
                           isOn: Binding(
                               get: { userPrefs.showMenuBarCountdown },
                               set: { 
                                   userPrefs.showMenuBarCountdown = $0
                                   try? ctx.save()
                               }
                           ))
                           .toggleStyle(CustomToggleStyle())
                }
            }
            .padding()
        }
    }
}

struct PermissionsTabView: View {
    let userPrefs: UserPrefs
    let calendarService: CalendarService
    let scheduler: Scheduler
    let ctx: ModelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calendar Integration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Mute alerts during calendar meetings",
                               isOn: Binding(
                                   get: { userPrefs.calendarFilter },
                                   set: { newValue in
                                       userPrefs.calendarFilter = newValue
                                       try? ctx.save()
                                       
                                       // Update scheduler with calendar service
                                       scheduler.setCalendarService(calendarService, shouldCheck: newValue)
                                       
                                       // Request calendar access if enabled
                                       if newValue && !calendarService.isAuthorized {
                                           Task {
                                               await requestCalendarAccess()
                                           }
                                       }
                                   }
                               ))
                               .toggleStyle(CustomToggleStyle())
                        
                        if userPrefs.calendarFilter {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: calendarService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(calendarService.isAuthorized ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(calendarService.isAuthorized ? "Calendar access granted" : "Calendar access required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !calendarService.isAuthorized {
                                        Button("Grant Access") {
                                            Task {
                                                await requestCalendarAccess()
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func requestCalendarAccess() async {
        _ = await calendarService.requestAccess()
    }
}

struct PostureTabView: View {
    let userPrefs: UserPrefs
    let motionService: MotionService
    let ctx: ModelContext
    @State private var showAdvancedSettings = false
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Posture Monitoring")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Monitor posture using AirPods",
                               isOn: Binding(
                                   get: { userPrefs.postureMonitoringEnabledValue },
                                   set: { newValue in
                                       userPrefs.postureMonitoringEnabledValue = newValue
                                       try? ctx.save()
                                       
                                       // Update motion service
                                       if newValue {
                                           Task {
                                               await requestPostureAccess()
                                           }
                                       } else {
                                           motionService.stopMonitoring()
                                       }
                                   }
                               ))
                               .toggleStyle(CustomToggleStyle())
                        
                        if userPrefs.postureMonitoringEnabledValue {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: motionService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(motionService.isAuthorized ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(motionService.isAuthorized ? "Motion access granted" : "Motion access required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !motionService.isAuthorized {
                                        Button("Grant Access") {
                                            Task {
                                                await requestPostureAccess()
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                                
                                if let errorMessage = motionService.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 20)
                                }
                                
                                if motionService.isAuthorized {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: motionService.currentPosture == .good ? "checkmark.circle.fill" : 
                                                  motionService.currentPosture == .poor ? "exclamationmark.triangle.fill" :
                                                  motionService.currentPosture == .calibrating ? "clock.fill" : "questionmark.circle.fill")
                                                .foregroundColor(motionService.currentPosture == .good ? .green : 
                                                               motionService.currentPosture == .poor ? .orange :
                                                               motionService.currentPosture == .calibrating ? .blue : .gray)
                                                .font(.caption)
                                            
                                            Text(motionService.currentPosture == .good ? "Good posture" :
                                                 motionService.currentPosture == .poor ? "Poor posture detected" :
                                                 motionService.currentPosture == .calibrating ? "Calibrating..." : 
                                                 motionService.currentPosture == .noData ? "Wear AirPods for posture detection" : "Unknown")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Button("Recalibrate") {
                                                motionService.startPostureCalibration()
                                            }
                                            .buttonStyle(.borderless)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        // Live angle display
                                        VStack(alignment: .leading, spacing: 2) {
                                            let _ = updateCounter // Force UI update
                                            Text("Current angles: Pitch \(String(format: "%.1f", motionService.currentPitch))°, Roll \(String(format: "%.1f", motionService.currentRoll))°")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text("Deviations: Pitch \(String(format: "%.1f", motionService.pitchDeviation))°, Roll \(String(format: "%.1f", motionService.rollDeviation))°")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                            .padding(.leading, 20)
                            
                            // Calibration guidance
                            if motionService.currentPosture == .calibrating {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Calibration Instructions:")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("1. Sit straight in your chair")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("2. Look at the center of your screen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("3. Keep your head level")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 20)
                                    
                                    Button("Complete Calibration") {
                                        motionService.completePostureCalibration()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .padding(.leading, 20)
                                }
                                .padding(.leading, 20)
                            }
                            
                            // Posture monitoring settings
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Poor Posture Threshold")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Slider(
                                        value: Binding(
                                            get: { Double(userPrefs.poorPostureThresholdSecondsValue) },
                                            set: { 
                                                userPrefs.poorPostureThresholdSecondsValue = Int($0)
                                                motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval($0))
                                                try? ctx.save()
                                            }
                                        ),
                                        in: 10...120,
                                        step: 5
                                    )
                                    
                                    Text("\(userPrefs.poorPostureThresholdSecondsValue)s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                
                                // Advanced settings collapsible
                                VStack(alignment: .leading, spacing: 8) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showAdvancedSettings.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("Advanced Settings")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if showAdvancedSettings {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Sensitivity")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 12) {
                                                SensitivityButton(
                                                    title: "Low",
                                                    degrees: 20.0,
                                                    isSelected: userPrefs.postureSensitivityDegreesValue == 20.0,
                                                    action: {
                                                        userPrefs.postureSensitivityDegreesValue = 20.0
                                                        motionService.setPostureThresholds(pitch: 20.0, roll: 20.0, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
                                                        try? ctx.save()
                                                    }
                                                )
                                                
                                                SensitivityButton(
                                                    title: "Medium",
                                                    degrees: 14.0,
                                                    isSelected: userPrefs.postureSensitivityDegreesValue == 14.0,
                                                    action: {
                                                        userPrefs.postureSensitivityDegreesValue = 14.0
                                                        motionService.setPostureThresholds(pitch: 14.0, roll: 14.0, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
                                                        try? ctx.save()
                                                    }
                                                )
                                                
                                                SensitivityButton(
                                                    title: "High",
                                                    degrees: 8.0,
                                                    isSelected: userPrefs.postureSensitivityDegreesValue == 8.0,
                                                    action: {
                                                        userPrefs.postureSensitivityDegreesValue = 8.0
                                                        motionService.setPostureThresholds(pitch: 8.0, roll: 8.0, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
                                                        try? ctx.save()
                                                    }
                                                )
                                            }
                                        }
                                        .padding(.leading, 20)
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding()
        }
        .onReceive(timer) { _ in
            // Force UI update every 1 second to show live angles
            if motionService.isAuthorized {
                updateCounter += 1
            }
        }
    }
    
    private func requestPostureAccess() async {
        let granted = await motionService.requestAccess()
        if granted {
            motionService.startMonitoring()
        }
    }
}

struct SensitivityButton: View {
    let title: String
    let degrees: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(degrees))°")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .white : .secondary)
    }
}

#Preview {
    SettingsView(scheduler: Scheduler(), motionService: MotionService())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 
