import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var currentPage = 0
    @StateObject private var motionService = MotionService()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var permissionManager: PermissionManager
    
    init() {
        let motionService = MotionService()
        let calendarService = CalendarService()
        self._motionService = StateObject(wrappedValue: motionService)
        self._calendarService = StateObject(wrappedValue: calendarService)
        self._permissionManager = StateObject(wrappedValue: PermissionManager(motionService: motionService, calendarService: calendarService))
    }
    
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
                // Page 1: Standing Reminders Setup
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
                    
                    StandingRemindersContentView(
                        userPrefs: userPrefs,
                        scheduler: Scheduler(), // Dummy scheduler for onboarding
                        ctx: ctx,
                        showExplanations: true
                    )
                    
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
                
                // Page 2: General Settings
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("General Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Configure your app preferences")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    GeneralSettingsContentView(
                        userPrefs: userPrefs,
                        calendarService: calendarService,
                        scheduler: Scheduler(), // Dummy scheduler for onboarding
                        ctx: ctx,
                        showExplanations: true
                    )
                    
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
                        
                        Text("Monitor your sitting posture using AirPods to detect when you're slouching or leaning too far. This helps you maintain better posture and reduce neck and back strain.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    PostureSettingsContentView(
                        userPrefs: userPrefs,
                        motionService: motionService,
                        ctx: ctx,
                        showExplanations: true
                    )
                    
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
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
    
    private func completeOnboarding() {
        // Set up posture monitoring if enabled by user
        if userPrefs.postureMonitoringEnabledValue && permissionManager.motionGranted {
            motionService.setPostureThresholds(pitch: userPrefs.postureSensitivityDegreesValue, roll: userPrefs.postureSensitivityDegreesValue, duration: TimeInterval(userPrefs.poorPostureThresholdSecondsValue))
            motionService.startMonitoring()
        }
        
        // Set up calendar service integration
        motionService.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
        
        // Mark onboarding as complete
        didOnboard = true
        
        // Post notification to close onboarding window
        NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
        
        // Post notification to open the popup
        NotificationCenter.default.post(name: NSNotification.Name("OpenPopup"), object: nil)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 