import SwiftUI
import SwiftData
import UserNotifications
import Combine

@main
struct PosturePulseApp: App {
    @State private var settingsWindowController: NSWindowController?
    @StateObject private var scheduler = Scheduler()
    @State private var updateCounter = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        requestNotifAuth()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                scheduler: scheduler,
                onOpenSettings: showSettingsWindow,
                onQuit: {
                    scheduler.stop()
                    NSApp.terminate(nil)
                }
            )
            .modelContainer(for: UserPrefs.self)
        } label: {
            MenuBarLabelView(scheduler: scheduler)
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
    
    private func showSettingsWindow() {
        if settingsWindowController == nil {
            let settingsView = SettingsView(scheduler: scheduler)
                .modelContainer(for: UserPrefs.self)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
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

