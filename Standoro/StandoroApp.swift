import SwiftUI
import SwiftData
import UserNotifications
import Combine

// Single source of truth for UserPrefs
class UserPrefsManager: ObservableObject {
    @Published var userPrefs: UserPrefs?
    private var modelContext: ModelContext?
    
    func initialize(with context: ModelContext) {
        self.modelContext = context
        loadOrCreateUserPrefs()
    }
    
    private func loadOrCreateUserPrefs() {
        guard let ctx = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPrefs>()
        if let prefs = try? ctx.fetch(descriptor), let first = prefs.first {
            self.userPrefs = first
        } else {
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            self.userPrefs = newPrefs
        }
    }
}

@main
struct StandoroApp: App {
    // Create a single, persistent model container for the entire app
    let modelContainer: ModelContainer
    
    @StateObject private var scheduler = Scheduler()
    @StateObject private var motionService = MotionService()
    @StateObject private var calendarService = CalendarService()
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject private var statsService = StatsService()
    @State private var settingsSelection: SettingsView.SidebarItem? = .standAndFocus
    @StateObject private var userPrefsManager = UserPrefsManager()
    @State private var showMainWindow = false

    init() {
        // Create a persistent model container that includes all our models
        do {
            let schema = Schema([
                UserPrefs.self,
                ActivityRecord.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        requestNotifAuth()
    }

    var body: some Scene {
        // Main window that appears when dock icon is clicked
        Window("Standoro", id: "main") {
            MainWindowView(
                userPrefsManager: userPrefsManager,
                scheduler: scheduler,
                motionService: motionService,
                calendarService: calendarService,
                statsService: statsService
            )
            .modelContainer(modelContainer)
            .onAppear {
                // Wire stats service after view is installed
                scheduler.setStatsService(statsService)
                motionService.setStatsService(statsService)
                setupDockClickHandler()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 687)
        .windowToolbarStyle(.unified)
        
        // Menu bar extra for quick access
        MenuBarExtra {
            AppContentView(
                modelContainer: modelContainer,
                userPrefsManager: userPrefsManager,
                scheduler: scheduler, 
                motionService: motionService, 
                calendarService: calendarService, 
                statsService: statsService
            )
            .modelContainer(modelContainer)
            .onAppear {
                // Wire stats service after view is installed
                scheduler.setStatsService(statsService)
                motionService.setStatsService(statsService)
            }
        } label: {
            MenuBarLabelView(
                userPrefs: userPrefsManager.userPrefs ?? UserPrefs(),
                scheduler: scheduler, 
                motionService: motionService
            )
            .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func requestNotifAuth() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
    }
    
    private func setupDockClickHandler() {
        // Set activation policy to regular (shows in dock)
        NSApp.setActivationPolicy(.regular)
        
        // Use a more reliable method to detect dock clicks
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Check if we have any visible windows
            let visibleWindows = NSApp.windows.filter { $0.isVisible }
            
            // If no windows are visible and app became active, it was likely a dock click
            if visibleWindows.isEmpty {
                // Show the main window
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}

// Main window content view - shows onboarding first, then settings
struct MainWindowView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("didOnboard") private var didOnboard = false
    let userPrefsManager: UserPrefsManager
    let scheduler: Scheduler
    let motionService: MotionService
    let calendarService: CalendarService
    let statsService: StatsService
    
    private var userPrefs: UserPrefs {
        userPrefsManager.userPrefs ?? UserPrefs()
    }
    
    var body: some View {
        Group {
            if !didOnboard {
                // Show onboarding first
                OnboardingView(userPrefs: userPrefs, motionService: motionService, calendarService: calendarService, scheduler: scheduler)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
                        didOnboard = true
                    }
            } else {
                // Show settings after onboarding
                SettingsView(
                    userPrefs: userPrefs,
                    scheduler: scheduler, 
                    motionService: motionService, 
                    calendarService: calendarService, 
                    statsService: statsService,
                    initialSelection: .standAndFocus
                )
            }
        }
        .onAppear {
            // Initialize userPrefsManager with the model context
            userPrefsManager.initialize(with: ctx)
            // Set model context for stats service
            statsService.setModelContext(ctx)
            // Set UserPrefs for scheduler state persistence
            if let prefs = userPrefsManager.userPrefs {
                scheduler.setUserPrefs(prefs)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetOnboarding"))) { _ in
            didOnboard = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPopup"))) { _ in
            // Focus the app and ensure the menu bar popup is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SaveUserPrefs"))) { _ in
            // Save UserPrefs when scheduler state changes
            try? ctx.save()
        }
    }
}

struct AppContentView: View {
    @Environment(\.modelContext) private var ctx
    @State private var settingsWindowController: NSWindowController?
    @State private var onboardingWindowController: NSWindowController?
    @State private var settingsSelection: SettingsView.SidebarItem? = .standAndFocus
    @AppStorage("didOnboard") private var didOnboard = false
    let modelContainer: ModelContainer
    let userPrefsManager: UserPrefsManager
    let scheduler: Scheduler
    let motionService: MotionService
    let calendarService: CalendarService
    let statsService: StatsService
    
    private var userPrefs: UserPrefs {
        userPrefsManager.userPrefs ?? UserPrefs()
    }
    
    var body: some View {
        MenuBarView(
            userPrefs: userPrefs,
            scheduler: scheduler,
            motionService: motionService,
            calendarService: calendarService,
            statsService: statsService,
            onOpenSettings: showSettingsWindow,
            onQuit: {
                scheduler.stop()
                motionService.stopMonitoring()
                NSApp.terminate(nil)
            }
        )
        .onAppear {
            // Initialize userPrefsManager with the model context
            userPrefsManager.initialize(with: ctx)
            // Set model context for stats service
            statsService.setModelContext(ctx)
            // Set UserPrefs for scheduler state persistence
            if let prefs = userPrefsManager.userPrefs {
                scheduler.setUserPrefs(prefs)
            }
            
            if !didOnboard {
                showOnboardingWindow()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetOnboarding"))) { _ in
            showOnboardingWindow()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPopup"))) { _ in
            // Focus the app and ensure the menu bar popup is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SaveUserPrefs"))) { _ in
            // Save UserPrefs when scheduler state changes
            try? ctx.save()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenStats"))) { _ in
            settingsSelection = .stats
            // Close existing settings window if open to force recreation with new selection
            settingsWindowController?.close()
            settingsWindowController = nil
            // Open settings window with stats tab
            showSettingsWindow()
        }
    }
    
    private func showOnboardingWindow() {
        if onboardingWindowController == nil {
            let onboardingView = OnboardingView(userPrefs: userPrefs, motionService: motionService, calendarService: calendarService, scheduler: scheduler)
                .modelContainer(modelContainer)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
                    onboardingWindowController?.close()
                    onboardingWindowController = nil
                }
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Welcome to Standoro"
            window.contentView = NSHostingView(rootView: onboardingView)
            window.center()
            window.isMovableByWindowBackground = false
            
            onboardingWindowController = NSWindowController(window: window)
        }
        
        onboardingWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showSettingsWindow() {
        if settingsWindowController == nil {
            let settingsView = SettingsView(
                userPrefs: userPrefs,
                scheduler: scheduler, 
                motionService: motionService, 
                calendarService: calendarService, 
                statsService: statsService,
                initialSelection: settingsSelection
            )
            .modelContainer(modelContainer)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 687),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = ""
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            if let titlebarView = window.standardWindowButton(.closeButton)?.superview {
                titlebarView.wantsLayer = true
                titlebarView.layer?.backgroundColor = NSColor(Color.settingsSidebar).cgColor
            }
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
