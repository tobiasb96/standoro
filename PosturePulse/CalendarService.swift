import Foundation
import EventKit
import Combine

@MainActor
class CalendarService: ObservableObject {
    private let store = EKEventStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = authorizationStatus == .fullAccess
        print("🔔 CalendarService - Authorization status: \(authorizationStatus.rawValue), isAuthorized: \(isAuthorized)")
        
        // Clear error message if we have proper authorization
        if isAuthorized {
            errorMessage = nil
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
                        self.errorMessage = "Calendar access requires app sandbox configuration. Please contact the developer or try running the app outside of sandbox mode."
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
    
    func isInMeeting(hoursToCheck: Int = 4) -> Bool {
        guard isAuthorized else {
            print("🔔 CalendarService - Not authorized, skipping meeting check")
            return false
        }
        
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .hour, value: hoursToCheck, to: now) else {
            print("🔔 CalendarService - Could not calculate end date")
            return false
        }
        
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: predicate)
        
        // Filter for events that are currently happening and have attendees (meetings)
        let currentMeetings = events.filter { event in
            let isCurrentlyHappening = event.startDate <= now && event.endDate > now
            let hasAttendees = event.hasAttendees
            return isCurrentlyHappening && hasAttendees
        }
        
        let inMeeting = !currentMeetings.isEmpty
        if inMeeting {
            print("🔔 CalendarService - Currently in meeting: \(currentMeetings.map { $0.title ?? "Untitled" })")
        } else {
            print("🔔 CalendarService - Not currently in any meetings")
        }
        
        return inMeeting
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
} 