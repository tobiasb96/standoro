import SwiftUI
import SwiftData
import EventKit
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @ObservedObject var scheduler: Scheduler
    @ObservedObject var postureService: PostureService
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
                
                PostureTabView(userPrefs: userPrefs, postureService: postureService, ctx: ctx)
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
            
            // Set up posture service
            if userPrefs.postureMonitoringEnabledValue {
                postureService.setPoorPostureThreshold(TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
                postureService.setPitchThreshold(userPrefs.postureSensitivityDegreesValue)
                postureService.setRollThreshold(userPrefs.postureSensitivityDegreesValue)
            }
            
            // Always enable high frequency mode when settings are opened
            // This allows users to see real-time angles even if posture monitoring is disabled
            if postureService.isAuthorized {
                postureService.enableHighFrequencyMode()
                
                // Start monitoring if not already active, so we can show real-time angles
                if !postureService.isMonitoring {
                    postureService.startMonitoring()
                }
            }
        }
        .onDisappear {
            // Save context when the window is closed
            try? ctx.save()
            
            // Always disable high frequency mode when settings are closed
            if postureService.isAuthorized {
                postureService.disableHighFrequencyMode()
                
                // Stop monitoring if it was started just for the settings window
                // and posture monitoring is disabled in preferences
                if postureService.isMonitoring && !userPrefs.postureMonitoringEnabledValue {
                    postureService.stopMonitoring()
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
    let postureService: PostureService
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
                                       
                                       // Update posture service
                                       if newValue {
                                           Task {
                                               await requestPostureAccess()
                                           }
                                       } else {
                                           postureService.stopMonitoring()
                                       }
                                   }
                               ))
                               .toggleStyle(CustomToggleStyle())
                        
                        if userPrefs.postureMonitoringEnabledValue {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: postureService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(postureService.isAuthorized ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(postureService.isAuthorized ? "Motion access granted" : "Motion access required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !postureService.isAuthorized {
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
                                
                                if let errorMessage = postureService.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 20)
                                }
                                
                                if postureService.isAuthorized {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: postureService.currentPosture == .good ? "checkmark.circle.fill" : 
                                                  postureService.currentPosture == .poor ? "exclamationmark.triangle.fill" :
                                                  postureService.currentPosture == .calibrating ? "clock.fill" : "questionmark.circle.fill")
                                                .foregroundColor(postureService.currentPosture == .good ? .green : 
                                                               postureService.currentPosture == .poor ? .orange :
                                                               postureService.currentPosture == .calibrating ? .blue : .gray)
                                                .font(.caption)
                                            
                                            Text(postureService.currentPosture == .good ? "Good posture" :
                                                 postureService.currentPosture == .poor ? "Poor posture detected" :
                                                 postureService.currentPosture == .calibrating ? "Calibrating..." : 
                                                 postureService.currentPosture == .noAirPods ? "Wear AirPods for posture detection" : "Unknown")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Button("Recalibrate") {
                                                postureService.startCalibration()
                                            }
                                            .buttonStyle(.borderless)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        // Live angle display
                                        VStack(alignment: .leading, spacing: 2) {
                                            let _ = updateCounter // Force UI update
                                            Text("Current angles: Pitch \(String(format: "%.1f", postureService.currentPitch))°, Roll \(String(format: "%.1f", postureService.currentRoll))°")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text("Deviations: Pitch \(String(format: "%.1f", postureService.pitchDeviation))°, Roll \(String(format: "%.1f", postureService.rollDeviation))°")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                            .padding(.leading, 20)
                            
                            // Calibration guidance
                            if postureService.currentPosture == .calibrating {
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
                                        postureService.completeCalibration()
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
                                                postureService.setPoorPostureThreshold(TimeInterval($0))
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
                                                        postureService.setPitchThreshold(20.0)
                                                        postureService.setRollThreshold(20.0)
                                                        try? ctx.save()
                                                    }
                                                )
                                                
                                                SensitivityButton(
                                                    title: "Medium",
                                                    degrees: 14.0,
                                                    isSelected: userPrefs.postureSensitivityDegreesValue == 14.0,
                                                    action: {
                                                        userPrefs.postureSensitivityDegreesValue = 14.0
                                                        postureService.setPitchThreshold(14.0)
                                                        postureService.setRollThreshold(14.0)
                                                        try? ctx.save()
                                                    }
                                                )
                                                
                                                SensitivityButton(
                                                    title: "High",
                                                    degrees: 8.0,
                                                    isSelected: userPrefs.postureSensitivityDegreesValue == 8.0,
                                                    action: {
                                                        userPrefs.postureSensitivityDegreesValue = 8.0
                                                        postureService.setPitchThreshold(8.0)
                                                        postureService.setRollThreshold(8.0)
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
            if postureService.isAuthorized {
                updateCounter += 1
            }
        }
    }
    
    private func requestPostureAccess() async {
        let granted = await postureService.requestAccess()
        if granted {
            postureService.startMonitoring()
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
    SettingsView(scheduler: Scheduler(), postureService: PostureService())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 
