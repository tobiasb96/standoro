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
                        Image(systemName: "figure.stand.line.dotted.figure.stand")
                            .font(.system(size: 90))
                            .foregroundColor(.settingsAccentBlue)
                        
                        Text("Welcome to PosturePulse")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.settingsHeader)
                    }
                    
                    // Explanation paragraphs
                    VStack(spacing: 20) {
                        Text("PosturePulse is your intelligent posture companion, designed to help you build healthier work habits and reduce the aches and fatigue that come from long hours at your desk. Modern work often means sitting for extended periods, which can lead to back pain, neck strain, and decreased energy.")
                            .font(.system(size: 16))
                            .foregroundColor(.settingsSubheader)
                            .multilineTextAlignment(.center)
                        Text("With PosturePulse, you'll receive gentle reminders to stand up and move, as well as real-time posture feedback using your AirPods' motion sensors. Our goal is to help you stay active, maintain good posture, and feel your best throughout the day.")
                            .font(.system(size: 16))
                            .foregroundColor(.settingsSubheader)
                            .multilineTextAlignment(.center)
                        Text("In the next steps, you'll set your standing and sitting goals, configure posture monitoring, and grant the necessary permissions. Let's get started on your journey to a healthier, more comfortable workday!")
                            .font(.system(size: 16))
                            .foregroundColor(.settingsSubheader)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
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
                .padding(60)
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
        .background(Color.settingsBackground)
        .frame(minWidth: 875, idealWidth: 1000, minHeight: 700, idealHeight: 800)
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