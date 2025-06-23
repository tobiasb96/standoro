import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var currentPage = 0
    @State private var standGoal = 15
    @State private var maxSitBlock = 45
    @State private var notificationsGranted = false
    @State private var calendarGranted = false
    @State private var postureEnabled = false
    @State private var postureGranted = false
    @StateObject private var motionService = MotionService()
    
    private var userPrefs: UserPrefs {
        if let p = prefs.first {
            return p
        } else {
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            return newPrefs
        }
    }
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Goals Setup
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Welcome to PosturePulse")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Let's set up your posture goals")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Standing Goal")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("How long would you like to stand for each session?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            IntervalSliderView(
                                label: "Minutes",
                                minutes: $standGoal,
                                quickOptions: [5, 10, 15, 20],
                                context: ctx
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maximum Sitting Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("How long can you sit before needing a break?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            IntervalSliderView(
                                label: "Minutes",
                                minutes: $maxSitBlock,
                                quickOptions: [25, 45, 60, 90],
                                context: ctx
                            )
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button("Next") {
                            currentPage = 1
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .padding(32)
                .tag(0)
                
                // Page 2: Permissions
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Permissions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("PosturePulse needs a few permissions to work effectively")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 24) {
                        PermissionCard(
                            title: "Notifications",
                            description: "Get reminded when it's time to stand or sit",
                            icon: "bell.fill",
                            isGranted: $notificationsGranted,
                            onRequest: requestNotificationPermission
                        )
                        
                        PermissionCard(
                            title: "Calendar Access",
                            description: "Mute alerts during calendar meetings",
                            icon: "calendar",
                            isGranted: $calendarGranted,
                            onRequest: requestCalendarPermission
                        )
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Back") {
                            currentPage = 0
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Button("Next") {
                            currentPage = 2
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                }
                .padding(32)
                .tag(1)
                
                // Page 3: Posture Tracking
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Posture Tracking")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Monitor your sitting posture using AirPods")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "airpods")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AirPods Motion Detection")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Uses your AirPods to detect if you're sitting with good posture")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $postureEnabled)
                                    .toggleStyle(CustomToggleStyle())
                            }
                            
                            if postureEnabled {
                                VStack(alignment: .leading, spacing: 12) {
                                    AsyncPermissionCard(
                                        title: "Motion Access",
                                        description: "Access AirPods motion data for posture detection",
                                        icon: "figure.stand",
                                        isGranted: $postureGranted,
                                        onRequest: requestPosturePermission
                                    )
                                    
                                    if postureGranted {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text("Motion access granted")
                                                    .foregroundColor(.green)
                                            }
                                            
                                            HStack {
                                                Image(systemName: motionService.currentPosture == .good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                                    .foregroundColor(motionService.currentPosture == .good ? .green : .orange)
                                                Text(motionService.currentPosture == .good ? "Good posture detected" : "Calibrating posture...")
                                                    .foregroundColor(motionService.currentPosture == .good ? .green : .orange)
                                            }
                                        }
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Back") {
                            currentPage = 1
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                }
                .padding(32)
                .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .background(Color(red: 0.0, green: 0.2, blue: 0.6))
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        // Check notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // Check calendar permission
        // This would need to be implemented based on your calendar service
        calendarGranted = false
        
        // Check posture permission
        postureGranted = motionService.isAuthorized
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsGranted = granted
            }
        }
    }
    
    private func requestCalendarPermission() {
        // This would need to be implemented based on your calendar service
        calendarGranted = true
    }
    
    private func requestPosturePermission() async {
        let granted = await motionService.requestAccess()
        await MainActor.run {
            postureGranted = granted
        }
    }
    
    private func completeOnboarding() {
        // Save user preferences
        userPrefs.maxStandMinutes = standGoal
        userPrefs.maxSitMinutes = maxSitBlock
        userPrefs.postureMonitoringEnabledValue = postureEnabled
        
        // Set up posture monitoring if enabled
        if postureEnabled && postureGranted {
            motionService.setPostureThresholds(pitch: 15.0, roll: 15.0, duration: 30)
            motionService.startMonitoring()
        }
        
        // Mark onboarding as complete
        didOnboard = true
        
        // Post notification to close onboarding window
        NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant") {
                    onRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
    }
}

struct AsyncPermissionCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    let onRequest: () async -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant") {
                    Task {
                        await onRequest()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 