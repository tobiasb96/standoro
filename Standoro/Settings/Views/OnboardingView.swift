import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var currentPage = 0
    @StateObject private var motionService = MotionService()
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var scheduler: Scheduler
    @StateObject private var permissionManager: PermissionManager
    let userPrefs: UserPrefs
    
    init(userPrefs: UserPrefs, calendarService: CalendarService, scheduler: Scheduler) {
        self.userPrefs = userPrefs
        self.calendarService = calendarService
        self.scheduler = scheduler
        let motionService = MotionService()
        self._motionService = StateObject(wrappedValue: motionService)
        self._permissionManager = StateObject(wrappedValue: PermissionManager(motionService: motionService, calendarService: calendarService))
    }
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 0: Welcome Screen
                ScrollView {
                    VStack(spacing: 40) {
                        // Logo and Welcome
                        VStack(spacing: 24) {
                            Text("Welcome to Standoro")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.settingsHeader)
                        }
                        
                        // Explanation paragraphs
                        VStack(spacing: 20) {
                            Text("Standoro is your intelligent companion for maintaining health and productivity during desk work. We understand that modern work often means long hours at your computer, which can lead to back pain, neck strain, and decreased energy.")
                                .font(.system(size: 16))
                                .foregroundColor(.settingsSubheader)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Our approach is built around three core components that work together to keep you healthy and focused:")
                                .font(.system(size: 16))
                                .foregroundColor(.settingsSubheader)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 20))
                                        .foregroundColor(.settingsAccentGreen)
                                        .frame(width: 24, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Stand + Focus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.settingsHeader)
                                        Text("Alternate between sitting and standing with structured focus sessions using the Pomodoro technique to boost productivity and reduce sedentary time.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.settingsSubheader)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 20))
                                        .foregroundColor(.settingsAccentGreen)
                                        .frame(width: 24, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Move + Rest")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.settingsHeader)
                                        Text("Take regular movement breaks with guided exercises and stretches to keep your body active and prevent stiffness.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.settingsSubheader)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "airpods")
                                        .font(.system(size: 20))
                                        .foregroundColor(.settingsAccentGreen)
                                        .frame(width: 24, alignment: .center)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Keep Posture")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.settingsHeader)
                                        Text("Monitor your sitting posture using AirPods' motion sensors to detect slouching and provide gentle reminders to maintain good posture.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.settingsSubheader)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            
                            Text("In the next steps, you'll configure each of these components to match your work style and preferences. Let's create a personalized experience that helps you stay healthy, focused, and productive!")
                                .font(.system(size: 16))
                                .foregroundColor(.settingsSubheader)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 32)
                        
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
                }
                .tag(0)
                
                // Page 1: Stand + Focus Setup
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Stand + Focus")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Configure your standing reminders and focus sessions. Choose between simple posture timers or structured Pomodoro sessions to boost your productivity while staying active.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            StandAndFocusSettingsContentView(
                                userPrefs: userPrefs,
                                scheduler: scheduler,
                                ctx: ctx,
                                showExplanations: true
                            )
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Footer
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .tag(1)
                
                // Page 2: Move + Rest Setup
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Move + Rest")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Take regular movement breaks with guided exercises and stretches. This feature helps you stay active and prevent stiffness during long work sessions.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            MoveAndRestSettingsContentView(
                                userPrefs: userPrefs,
                                ctx: ctx,
                                showExplanations: true
                            )
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Footer
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .tag(2)
                
                // Page 3: General Settings
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("General Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Configure how Standoro integrates with your system and manages notifications. Set up calendar integration to automatically mute alerts during meetings.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            GeneralSettingsContentView(
                                userPrefs: userPrefs,
                                calendarService: calendarService,
                                scheduler: scheduler,
                                ctx: ctx,
                                showExplanations: true
                            )
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Footer
                    HStack {
                        Button("Back") {
                            currentPage = 2
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Button("Next") {
                            currentPage = 4
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .tag(3)
                
                // Page 4: Keep Posture Setup
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Keep Posture")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Monitor your sitting posture using AirPods to detect when you're slouching or leaning too far. This helps you maintain better posture and reduce neck and back strain throughout your workday.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            KeepPostureSettingsContentView(
                                userPrefs: userPrefs,
                                motionService: motionService,
                                ctx: ctx,
                                showExplanations: true
                            )
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Footer
                    HStack {
                        Button("Back") {
                            currentPage = 3
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Button("Next") {
                            currentPage = 5
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .tag(4)
                
                // Page 5: How to Use Standoro
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                            
                            Text("You're All Set!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.settingsHeader)
                            
                            Text("Standoro is now running in the background. Here's how to access it:")
                                .font(.title3)
                                .foregroundColor(.settingsSubheader)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        
                        
                        // Final Instructions
                        VStack(spacing: 12) {
                            Text("What happens next?")
                                .font(.headline)
                                .foregroundColor(.settingsHeader)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.settingsAccentGreen)
                                        .font(.system(size: 14))
                                    Text("You can start a session by clicking the menu bar icon or the dock icon")
                                        .font(.system(size: 14))
                                        .foregroundColor(.settingsSubheader)
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "bell")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                    Text("You'll receive gentle reminders based on your settings")
                                        .font(.system(size: 14))
                                        .foregroundColor(.settingsSubheader)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "chart.bar")
                                        .foregroundColor(.green)
                                        .font(.system(size: 14))
                                    Text("Track your progress and view statistics in the settings")
                                        .font(.system(size: 14))
                                        .foregroundColor(.settingsSubheader)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.settingsAccentGreen)
                                        .font(.system(size: 14))
                                    Text("Adjust settings anytime through the menu bar or dock icon")
                                        .font(.system(size: 14))
                                        .foregroundColor(.settingsSubheader)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                        }
                        
                        // Get Started Button
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                    .padding(60)
                }
                .tag(5)
                .tabViewStyle(.tabBarOnly)
            }
        }
        .background(Color.settingsBackground)
        .frame(minWidth: 875, idealWidth: 1000, minHeight: 800, idealHeight: 900)
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
    OnboardingView(userPrefs: UserPrefs(), calendarService: CalendarService(), scheduler: Scheduler())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 
