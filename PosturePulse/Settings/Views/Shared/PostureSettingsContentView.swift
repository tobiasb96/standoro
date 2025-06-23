import SwiftUI
import SwiftData
import Combine

struct PostureSettingsContentView: View {
    let userPrefs: UserPrefs
    let motionService: MotionService
    let ctx: ModelContext
    let showExplanations: Bool
    
    @State private var showAdvancedSettings = false
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showCalibrationDetails = false
    
    init(userPrefs: UserPrefs, motionService: MotionService, ctx: ModelContext, showExplanations: Bool = false) {
        self.userPrefs = userPrefs
        self.motionService = motionService
        self.ctx = ctx
        self.showExplanations = showExplanations
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Posture Monitoring")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showExplanations {
                    Text("Monitor your sitting posture using AirPods to detect when you're slouching or leaning too far. This helps you maintain better posture and reduce neck and back strain.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Monitor posture using AirPods",
                           isOn: Binding(
                               get: { userPrefs.postureMonitoringEnabledValue },
                               set: { newValue in
                                   userPrefs.postureMonitoringEnabledValue = newValue
                                   try? ctx.save()
                                   
                                   // Only request permission when enabling and not already authorized
                                   if newValue && !motionService.isAuthorized {
                                       Task {
                                           await requestPostureAccess()
                                       }
                                   } else if newValue && motionService.isAuthorized {
                                       // Start monitoring if already authorized
                                       motionService.startMonitoring()
                                   } else if !newValue {
                                       motionService.stopMonitoring()
                                   }
                               }
                           ))
                           .toggleStyle(CustomToggleStyle())
                    
                    if userPrefs.postureMonitoringEnabledValue {
                        VStack(alignment: .leading, spacing: 12) {
                            // Permission status
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
                            
                            // Posture status (only show if authorized)
                            if motionService.isAuthorized {
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
                                        showCalibrationDetails = true
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                // Show calibration guidance if not calibrated and not currently calibrating
                                if motionService.currentPosture == .noData && !showCalibrationDetails {
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
                                    .padding(.leading, 20)
                                    .padding(.top, 8)
                                }
                                
                                // Only show angles when calibrating or in advanced settings
                                if showCalibrationDetails || showAdvancedSettings {
                                    VStack(alignment: .leading, spacing: 2) {
                                        let _ = updateCounter // Force UI update
                                        Text("Current angles: Pitch \(String(format: "%.1f", motionService.currentPitch))°, Roll \(String(format: "%.1f", motionService.currentRoll))°")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Deviations: Pitch \(String(format: "%.1f", motionService.pitchDeviation))°, Roll \(String(format: "%.1f", motionService.rollDeviation))°")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 20)
                                    .padding(.top, 4)
                                }
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
                                .padding(.leading, 20)
                                
                                Button("Complete Calibration") {
                                    motionService.completePostureCalibration()
                                    showCalibrationDetails = false
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .padding(.leading, 20)
                            }
                            .padding(.leading, 20)
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
                                VStack(alignment: .leading, spacing: 24) {
                                    // Sensitivity settings
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Sensitivity")
                                            .font(.headline)
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
                                    
                                    // Poor posture threshold (moved to advanced section)
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Poor Posture Threshold")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            Text("Seconds")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(userPrefs.poorPostureThresholdSecondsValue)s")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color(red: 0.2, green: 0.4, blue: 0.9))
                                                .cornerRadius(10)
                                        }
                                        
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
                                        .tint(Color(red: 0.2, green: 0.4, blue: 0.9))
                                        .controlSize(.large)

                                        HStack(spacing: 8) {
                                            ForEach([15, 30, 45, 60], id: \.self) { option in
                                                Button("\(option)s") {
                                                    userPrefs.poorPostureThresholdSecondsValue = option
                                                    motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(option))
                                                    try? ctx.save()
                                                }
                                                .buttonStyle(.plain)
                                                .foregroundColor(userPrefs.poorPostureThresholdSecondsValue == option ? .white : .secondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(userPrefs.poorPostureThresholdSecondsValue == option ? Color(red: 0.2, green: 0.4, blue: 0.9) : Color(red: 0.16, green: 0.16, blue: 0.18))
                                                .cornerRadius(8)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 20)
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            // Force UI update every 1 second to show live angles when needed
            if motionService.isAuthorized && (showCalibrationDetails || showAdvancedSettings) {
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

#Preview {
    VStack(spacing: 20) {
        PostureSettingsContentView(
            userPrefs: UserPrefs(),
            motionService: MotionService(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        PostureSettingsContentView(
            userPrefs: UserPrefs(),
            motionService: MotionService(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 