import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var currentPage = 0
    @StateObject private var motionService = MotionService()
    @ObservedObject var calendarService: CalendarService
    @StateObject private var permissionManager: PermissionManager
    
    init(calendarService: CalendarService) {
        self.calendarService = calendarService
        let motionService = MotionService()
        self._motionService = StateObject(wrappedValue: motionService)
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
                // Page 0: Welcome Screen
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo and Welcome
                    VStack(spacing: 24) {
                        // App Icon/Logo placeholder
                        Image(systemName: "figure.stand.line.dotted.figure.stand")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to PosturePulse")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Explanation paragraphs
                    VStack(spacing: 20) {
                        Text("PosturePulse is your intelligent posture companion that helps you maintain healthy sitting habits and reduce the physical strain of long work sessions.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        Text("With smart reminders to stand up regularly and real-time posture monitoring using your AirPods, PosturePulse helps you build better habits for long-term health and comfort.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Start Setup Button
                    Button("Start Setup") {
                        currentPage = 1
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                }
                .padding(40)
                .tag(0)
                
                // Page 1: Standing Reminders Setup (previously page 0)
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Standing Reminders")
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
                
                // Page 2: General Settings (previously page 1)
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
                            currentPage = 1
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Button("Next") {
                            currentPage = 3
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                }
                .padding(32)
                .tag(2)
                
                // Page 3: Posture Tracking (previously page 2)
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
                            currentPage = 2
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
                .tag(3)
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
    OnboardingView(calendarService: CalendarService())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 