import Foundation
import EventKit
import Combine

@MainActor
class CalendarService: ObservableObject {
    private let store = EKEventStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isInMeeting = false
    @Published var currentMeetingTitle: String?
    
    // Busy ranges caching
    private var busyRanges: [DateInterval] = []
    private var lastCacheUpdate: Date?
    private var cacheTimer: Timer?
    private let cacheRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    
    init() {
        checkAuthorizationStatus()
        startCacheTimer()
        
        // Log sandbox status for debugging
        if isRunningInSandbox() {
            print("🔔 CalendarService - App is running in sandbox mode")
        } else {
            print("🔔 CalendarService - App is running outside sandbox mode")
        }
    }
    
    deinit {
        cacheTimer?.invalidate()
    }
    
    private func isRunningInSandbox() -> Bool {
        return ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = authorizationStatus == .fullAccess
        print("🔔 CalendarService - Authorization status: \(authorizationStatus.rawValue), isAuthorized: \(isAuthorized)")
        
        // Clear error message if we have proper authorization
        if isAuthorized {
            errorMessage = nil
            // Refresh cache immediately when authorized
            Task {
                await refreshBusyRanges()
            }
        }
    }
    
    func requestAccess() async -> Bool {
        print("🔔 CalendarService - Requesting calendar access...")
        errorMessage = nil
        
        do {
            let granted = try await store.requestFullAccessToEvents()
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .fullAccess : .denied
                if !granted {
                    self.errorMessage = "Calendar access was denied. Please enable it in System Preferences > Privacy & Security > Calendars."
                }
            }
            print("🔔 CalendarService - Access granted: \(granted)")
            
            // Refresh cache if access was granted
            if granted {
                await refreshBusyRanges()
            }
            
            return granted
        } catch {
            print("🔔 CalendarService - Error requesting access: \(error)")
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationStatus = .denied
                
                // Provide specific error messages based on the error
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case 4099: // Sandbox restriction
                        self.errorMessage = "Calendar access requires proper app permissions. Please ensure the app has calendar access enabled in System Preferences > Privacy & Security > Calendars, or try running the app outside of sandbox mode for development."
                    default:
                        self.errorMessage = "Failed to access calendar: \(nsError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Failed to access calendar: \(error.localizedDescription)"
                }
            }
            return false
        }
    }
    
    private func startCacheTimer() {
        cacheTimer?.invalidate()
        cacheTimer = Timer.scheduledTimer(withTimeInterval: cacheRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshBusyRanges()
            }
        }
    }
    
    private func refreshBusyRanges() async {
        guard isAuthorized else {
            print("🔔 CalendarService - Not authorized, skipping busy ranges refresh")
            return
        }
        
        print("🔔 CalendarService - Refreshing busy ranges...")
        
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .hour, value: 4, to: now) else {
            print("🔔 CalendarService - Could not calculate end date")
            return
        }
        
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: predicate)
        
        // Filter for non-all-day events and create date intervals manually
        busyRanges = events
            .filter { !$0.isAllDay }
            .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        
        lastCacheUpdate = now
        
        // Update current meeting status
        updateCurrentMeetingStatus()
        
        print("🔔 CalendarService - Cached \(busyRanges.count) busy ranges, next refresh in \(cacheRefreshInterval/60) minutes")
    }
    
    private func updateCurrentMeetingStatus() {
        let now = Date()
        
        // Find current meeting
        let currentMeeting = busyRanges.first { range in
            range.contains(now)
        }
        
        isInMeeting = currentMeeting != nil
        currentMeetingTitle = currentMeeting?.description ?? nil
        
        if isInMeeting {
            print("🔔 CalendarService - Currently in meeting")
        } else {
            print("🔔 CalendarService - Not currently in any meetings")
        }
    }
    
    func isInMeeting(hoursToCheck: Int = 4) -> Bool {
        // Use cached busy ranges for better performance
        let now = Date()
        return busyRanges.contains { range in
            range.contains(now)
        }
    }
    
    func isCurrentlyBusy() -> Bool {
        return isInMeeting
    }
    
    func getUpcomingMeetings(hoursToCheck: Int = 4) -> [EKEvent] {
        guard isAuthorized else {
            print("🔔 CalendarService - Not authorized, cannot fetch meetings")
            return []
        }
        
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .hour, value: hoursToCheck, to: now) else {
            print("🔔 CalendarService - Could not calculate end date")
            return []
        }
        
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: predicate)
        
        // Filter for events with attendees (meetings)
        let meetings = events.filter { $0.hasAttendees }
        
        print("🔔 CalendarService - Found \(meetings.count) upcoming meetings in next \(hoursToCheck) hours")
        return meetings
    }
    
    func getAuthorizationStatusText() -> String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .fullAccess:
            return "Full access"
        case .writeOnly:
            return "Write only"
        @unknown default:
            return "Unknown"
        }
    }
    
    // Force refresh for immediate updates (e.g., when settings change)
    func forceRefresh() async {
        await refreshBusyRanges()
    }
} 