import SwiftUI
import SwiftData
import UserNotifications
import Combine

@main
struct PosturePulseApp: App {
    @StateObject private var scheduler = Scheduler()
    private var postureService = PostureService()
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        requestNotifAuth()
    }

    var body: some Scene {
        MenuBarExtra {
            AppContentView(scheduler: scheduler, postureService: postureService)
                .modelContainer(for: UserPrefs.self)
        } label: {
            MenuBarLabelView(scheduler: scheduler, postureService: postureService)
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
    let postureService: PostureService
    
    var body: some View {
        MenuBarView(
            scheduler: scheduler,
            postureService: postureService,
            onOpenSettings: showSettingsWindow,
            onQuit: {
                scheduler.stop()
                postureService.stopMonitoring()
                NSApp.terminate(nil)
            }
        )
        .onAppear {
            if !didOnboard {
                showOnboardingWindow()
            }
        }
    }
    
    private func showOnboardingWindow() {
        if onboardingWindowController == nil {
            let onboardingView = OnboardingView()
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
            let settingsView = SettingsView(scheduler: scheduler, postureService: postureService)
                .modelContainer(for: UserPrefs.self)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "PosturePulse Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

