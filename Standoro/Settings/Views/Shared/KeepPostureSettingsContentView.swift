import SwiftUI
import SwiftData
import Combine

struct KeepPostureSettingsContentView: View {
    let userPrefs: UserPrefs
    let motionService: MotionService
    let scheduler: Scheduler
    let ctx: ModelContext
    let showExplanations: Bool
    
    @State private var showAdvancedSettings = false
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showCalibrationDetails = false
    
    // Local state for device status to ensure UI updates
    @State private var localDeviceConnected = false
    @State private var localDeviceReceivingData = false
    @State private var localDeviceAvailable = false
    
    // State to prevent multiple permission requests
    @State private var isRequestingPermission = false
    
    init(userPrefs: UserPrefs, motionService: MotionService, scheduler: Scheduler, ctx: ModelContext, showExplanations: Bool = false) {
        self.userPrefs = userPrefs
        self.motionService = motionService
        self.scheduler = scheduler
        self.ctx = ctx
        self.showExplanations = showExplanations
        
        // Initialize local state
        _localDeviceConnected = State(initialValue: motionService.isDeviceConnected)
        _localDeviceReceivingData = State(initialValue: motionService.isDeviceReceivingData)
        _localDeviceAvailable = State(initialValue: motionService.isDeviceAvailable)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Posture Nudges Card
            SettingsCard(
                icon: "bell.badge",
                header: "Posture Nudges",
                subheader: "Receive gentle reminders to maintain good posture throughout your day. These nudges are especially useful when you don't have AirPods connected for real-time monitoring.",
                iconColor: .settingsAccentGreen,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.postureNudgesEnabledValue },
                        set: { 
                            userPrefs.postureNudgesEnabledValue = $0
                            try? ctx.save()
                            // Connect posture nudges setting to scheduler
                            scheduler.setPostureNudgesEnabled($0)
                        }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                if userPrefs.postureNudgesEnabledValue && showExplanations {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Posture nudges will remind you to:")
                            .font(.subheadline)
                            .foregroundColor(.settingsHeader)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Sit up straight and align your spine")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Keep your shoulders relaxed and level")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Position your screen at eye level")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                            Text("• Take regular breaks to stretch")
                                .font(.caption)
                                .foregroundColor(.settingsSubheader)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            // AirPods Posture Monitoring Card
            SettingsCard(
                icon: "airpods",
                header: "Posture Monitoring",
                subheader: "Monitor your sitting posture using AirPods' motion sensors to detect slouching and provide gentle reminders.",
                iconColor: .settingsAccentGreen,
                showDivider: userPrefs.postureMonitoringEnabledValue,
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { userPrefs.postureMonitoringEnabledValue },
                        set: { newValue in
                            userPrefs.postureMonitoringEnabledValue = newValue
                            try? ctx.save()
                            if newValue && !motionService.isAuthorized && !isRequestingPermission {
                                isRequestingPermission = true
                                Task {
                                    await requestPostureAccess()
                                    // Start monitoring & enable posture tracking once authorized
                                    if motionService.isAuthorized {
                                        motionService.startMonitoring()
                                        motionService.notificationService.enablePostureTracking()
                                    }
                                    isRequestingPermission = false
                                }
                            } else if newValue && motionService.isAuthorized {
                                motionService.startMonitoring()
                                motionService.notificationService.enablePostureTracking()
                            } else if !newValue {
                                motionService.stopMonitoring()
                                motionService.notificationService.disablePostureTracking()
                            }
                        }
                    ))
                    .toggleStyle(CustomToggleStyle())
                )
            ) {
                if userPrefs.postureMonitoringEnabledValue {
                    VStack(alignment: .leading, spacing: 8) {
                        // Permission status
                        HStack {
                            Image(systemName: motionService.isAuthorized ? "checkmark.circle.fill" : 
                                  isRequestingPermission ? "clock.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(motionService.isAuthorized ? .green : 
                                               isRequestingPermission ? .settingsAccentGreen : .orange)
                                .font(.caption)
                            
                            Text(motionService.isAuthorized ? "System permission granted" : 
                                 isRequestingPermission ? "Requesting system permission..." : "System permission required")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !motionService.isAuthorized && !isRequestingPermission {
                                Button("Grant System Permission") {
                                    if !isRequestingPermission {
                                        isRequestingPermission = true
                                        Task {
                                            await requestPostureAccess()
                                            isRequestingPermission = false
                                        }
                                    }
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                                .foregroundColor(.settingsAccentGreen)
                                .disabled(isRequestingPermission)
                            }
                        }
                        
                        // Only show error message for system-level issues, not device connection issues
                        if let errorMessage = motionService.errorMessage, !localDeviceAvailable {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 20)
                        }
                        
                        // Posture status (only show if authorized)
                        if motionService.isAuthorized {
                            // Device status indicator
                            HStack {
                                Image(systemName: deviceStatusIcon)
                                    .foregroundColor(deviceStatusColor)
                                    .font(.caption)
                                
                                Text(deviceStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            // Force UI updates by referencing device status properties
                            let _ = motionService.isDeviceConnected
                            let _ = motionService.isDeviceReceivingData
                            let _ = motionService.isDeviceAvailable
                            
                            // Only show posture status if device is connected and receiving data
                            if localDeviceConnected && localDeviceReceivingData {
                                HStack {
                                    Image(systemName: motionService.currentPosture == .good ? "checkmark.circle.fill" : 
                                          motionService.currentPosture == .poor ? "exclamationmark.triangle.fill" :
                                          motionService.currentPosture == .calibrating ? "clock.fill" : "questionmark.circle.fill")
                                        .foregroundColor(motionService.currentPosture == .good ? .green : 
                                                       motionService.currentPosture == .poor ? .orange :
                                                       motionService.currentPosture == .calibrating ? .settingsAccentGreen : .gray)
                                        .font(.caption)
                                    
                                    Text(motionService.currentPosture == .good ? "Good posture" :
                                         motionService.currentPosture == .poor ? "Poor posture detected" :
                                         motionService.currentPosture == .calibrating ? "Calibrating..." : 
                                         motionService.currentPosture == .noData ? "No data available" : "Unknown")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Recalibrate") {
                                        motionService.startPostureCalibration()
                                        showCalibrationDetails = true
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundColor(.settingsAccentGreen)
                                }
                                .padding(.bottom, 8)
                            }
                            
                            // Show step guidance (only one at a time)
                            if !localDeviceConnected {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Connect AirPods")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("Please connect your AirPods Pro or AirPods Max to continue.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            } else if !localDeviceReceivingData {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Wear AirPods")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("Please wear your AirPods to enable motion detection.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            } else if motionService.currentPosture == .noData && !showCalibrationDetails {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Calibration Required")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("To start monitoring your posture, you need to calibrate the system first. This helps establish your baseline good posture.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Start Calibration") {
                                        motionService.startPostureCalibration()
                                        showCalibrationDetails = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    
                    // Calibration guidance
                    if motionService.currentPosture == .calibrating {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calibration Instructions:")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("1. Sit straight in your chair with your back against the backrest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("2. Look straight ahead at the center of your screen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("3. Keep your head level and your neck relaxed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("4. Hold this position for a few seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Complete Calibration") {
                                motionService.completePostureCalibration()
                                showCalibrationDetails = false
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.top, 16)
                    }

                    // Current angles and deviations in a small card
                    if showCalibrationDetails || showAdvancedSettings {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.settingsAccentGreen)
                                    .font(.caption)
                                
                                Text("Live Motion Data")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                let _ = updateCounter // Force UI update
                                Text("Current angles: Pitch \(String(format: "%.1f", motionService.currentPitch))°, Roll \(String(format: "%.1f", motionService.currentRoll))°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Deviations: Pitch \(String(format: "%.1f", motionService.pitchDeviation))°, Roll \(String(format: "%.1f", motionService.rollDeviation))°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.settingsCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.settingsCardBorder, lineWidth: 0.5)
                        )
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
                            VStack(alignment: .leading, spacing: 20) {
                                // Sensitivity settings using SettingsCard
                                SettingsCard(
                                    icon: "slider.horizontal.3",
                                    header: "Sensitivity",
                                    subheader: "Adjust how sensitive the posture detection should be.",
                                    iconColor: .settingsAccentGreen
                                ) {
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
                                
                                // Poor posture threshold using SettingsCard and IntervalSliderView
                                SettingsCard(
                                    icon: "timer",
                                    header: "Poor Posture Threshold",
                                    subheader: "How long to maintain poor posture before receiving a notification.",
                                    iconColor: .settingsAccentGreen
                                ) {
                                    IntervalSliderView(
                                        label: "Threshold",
                                        value: Binding(
                                            get: { userPrefs.poorPostureThresholdSecondsValue },
                                            set: { 
                                                userPrefs.poorPostureThresholdSecondsValue = $0
                                                motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval($0))
                                                try? ctx.save()
                                            }
                                        ),
                                        range: 10...120,
                                        unit: "s",
                                        quickOptions: [15, 30, 45, 60],
                                        context: ctx
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .onReceive(timer) { _ in
            // Force UI update every 1 second to show live angles when needed
            if motionService.isAuthorized && (showCalibrationDetails || showAdvancedSettings) {
                updateCounter += 1
            }
            
            // Sync local device status with motion service
            localDeviceConnected = motionService.isDeviceConnected
            localDeviceReceivingData = motionService.isDeviceReceivingData
            localDeviceAvailable = motionService.isDeviceAvailable
            
            // Force UI update when device status changes
            if motionService.isAuthorized {
                updateCounter += 1
            }
        }
    }
    
    private func requestPostureAccess() async {
        let granted = await motionService.requestAccess()
        if granted {
            // Start monitoring if posture monitoring is enabled
            if userPrefs.postureMonitoringEnabledValue {
                motionService.startMonitoring()
            }
        }
    }
    
    // MARK: - Device Status Computed Properties
    
    private var deviceStatusIcon: String {
        if !localDeviceConnected {
            return "airpods"
        }
        
        if !localDeviceReceivingData {
            return "airpods.gen3"
        }
        
        return "checkmark.circle.fill"
    }
    
    private var deviceStatusColor: Color {
        if !localDeviceConnected {
            return .orange
        }
        
        if !localDeviceReceivingData {
            return .yellow
        }
        
        return .green
    }
    
    private var deviceStatusText: String {
        if !localDeviceConnected {
            return "Connect AirPods"
        }
        
        if !localDeviceReceivingData {
            return "Wear AirPods"
        }
        
        return "AirPods connected and active"
    }
}

#Preview {
    VStack(spacing: 20) {
        KeepPostureSettingsContentView(
            userPrefs: UserPrefs(),
            motionService: MotionService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        KeepPostureSettingsContentView(
            userPrefs: UserPrefs(),
            motionService: MotionService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 