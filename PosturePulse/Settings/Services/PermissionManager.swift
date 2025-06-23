import Foundation
import UserNotifications
import Combine

@MainActor
class PermissionManager: ObservableObject {
    @Published var notificationsGranted = false
    @Published var calendarGranted = false
    @Published var motionGranted = false
    
    private let motionService: MotionService
    private let calendarService: CalendarService
    
    init(motionService: MotionService, calendarService: CalendarService) {
        self.motionService = motionService
        self.calendarService = calendarService
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        checkNotificationPermission()
        checkCalendarPermission()
        checkMotionPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func checkCalendarPermission() {
        calendarGranted = calendarService.isAuthorized
    }
    
    private func checkMotionPermission() {
        motionGranted = motionService.isAuthorized
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                self.notificationsGranted = granted
            }
            return granted
        } catch {
            print("🔔 PermissionManager - Notification authorization error: \(error)")
            return false
        }
    }
    
    func requestCalendarPermission() async -> Bool {
        let granted = await calendarService.requestAccess()
        await MainActor.run {
            self.calendarGranted = granted
        }
        return granted
    }
    
    func requestMotionPermission() async -> Bool {
        let granted = await motionService.requestAccess()
        await MainActor.run {
            self.motionGranted = granted
        }
        return granted
    }
    
    // Convenience method for onboarding flow
    func requestAllPermissions() async {
        _ = await requestNotificationPermission()
        _ = await requestCalendarPermission()
        _ = await requestMotionPermission()
    }
} 