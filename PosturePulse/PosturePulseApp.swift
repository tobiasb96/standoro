import SwiftUI
import SwiftData
import UserNotifications
import Combine

@main
struct PosturePulseApp: App {
    @StateObject private var scheduler = Scheduler()
    @StateObject private var motionService = MotionService()
    @StateObject private var calendarService = CalendarService()
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        requestNotifAuth()
    }

    var body: some Scene {
        MenuBarExtra {
            AppContentView(scheduler: scheduler, motionService: motionService, calendarService: calendarService)
                .modelContainer(for: UserPrefs.self)
        } label: {
            MenuBarLabelView(scheduler: scheduler, motionService: motionService)
                .modelContainer(for: UserPrefs.self)
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
}

struct AppContentView: View {
    @State private var settingsWindowController: NSWindowController?
    @State private var onboardingWindowController: NSWindowController?
    @AppStorage("didOnboard") private var didOnboard = false
    let scheduler: Scheduler
    let motionService: MotionService
    let calendarService: CalendarService
    
    var body: some View {
        MenuBarView(
            scheduler: scheduler,
            motionService: motionService,
            calendarService: calendarService,
            onOpenSettings: showSettingsWindow,
            onQuit: {
                scheduler.stop()
                motionService.stopMonitoring()
                NSApp.terminate(nil)
            }
        )
        .onAppear {
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
    }
    
    private func showOnboardingWindow() {
        if onboardingWindowController == nil {
            let onboardingView = OnboardingView(calendarService: calendarService)
                .modelContainer(for: UserPrefs.self)
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
            window.title = "Welcome to PosturePulse"
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
            let settingsView = SettingsView(scheduler: scheduler, motionService: motionService, calendarService: calendarService)
                .modelContainer(for: UserPrefs.self)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = ""
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

