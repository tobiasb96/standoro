import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    let scheduler: Scheduler
    @StateObject private var calendarService = CalendarService()

    private var userPrefs: UserPrefs {
        if let p = prefs.first {
            return p
        } else {
            // This is a fallback, but the view should ideally handle the empty state.
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            return newPrefs
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if prefs.isEmpty {
                VStack {
                    Text("Loading Preferences...")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 24) {
                    IntervalSliderView(
                        label: "Sitting Time",
                        minutes: Binding(
                            get: { self.userPrefs.maxSitMinutes },
                            set: { 
                                self.userPrefs.maxSitMinutes = $0
                                try? ctx.save()
                            }
                        ),
                        quickOptions: [25, 45, 60],
                        context: ctx
                    )

                    IntervalSliderView(
                        label: "Standing Time",
                        minutes: Binding(
                            get: { self.userPrefs.maxStandMinutes },
                            set: { 
                                self.userPrefs.maxStandMinutes = $0
                                try? ctx.save()
                            }
                        ),
                        quickOptions: [5, 10, 15],
                        context: ctx
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Integrations")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Mute alerts during calendar meetings",
                                   isOn: Binding(
                                       get: { self.userPrefs.calendarFilter },
                                       set: { newValue in
                                           self.userPrefs.calendarFilter = newValue
                                           try? ctx.save()
                                           
                                           // Update scheduler with calendar service
                                           scheduler.setCalendarService(calendarService, shouldCheck: newValue)
                                           
                                           // Request calendar access if enabled
                                           if newValue && !calendarService.isAuthorized {
                                               Task {
                                                   await requestCalendarAccess()
                                               }
                                           }
                                       }
                                   ))
                                   .toggleStyle(CustomToggleStyle())
                            
                            if userPrefs.calendarFilter {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: calendarService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .foregroundColor(calendarService.isAuthorized ? .green : .orange)
                                            .font(.caption)
                                        
                                        Text(calendarService.isAuthorized ? "Calendar access granted" : "Calendar access required")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if !calendarService.isAuthorized {
                                            Button("Grant Access") {
                                                Task {
                                                    await requestCalendarAccess()
                                                }
                                            }
                                            .buttonStyle(.borderless)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    if let errorMessage = calendarService.errorMessage {
                                        Text(errorMessage)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.leading, 20)
                                    }
                                    
                                    if !calendarService.isAuthorized {
                                        Text("Status: \(calendarService.getAuthorizationStatusText())")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 20)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Menu Bar Display")
                            .font(.headline)
                            .foregroundColor(.white)
                        Toggle("Show countdown timer in menu bar",
                               isOn: Binding(
                                   get: { self.userPrefs.showMenuBarCountdown },
                                   set: { 
                                       self.userPrefs.showMenuBarCountdown = $0
                                       try? ctx.save()
                                   }
                               ))
                               .toggleStyle(CustomToggleStyle())
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Development")
                            .font(.headline)
                            .foregroundColor(.white)
                        Button("Reset Onboarding") {
                            UserDefaults.standard.removeObject(forKey: "didOnboard")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 480, height: 600)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .onAppear {
            // Set up calendar service with scheduler
            scheduler.setCalendarService(calendarService, shouldCheck: userPrefs.calendarFilter)
        }
        .onDisappear {
            // Save context when the window is closed
            try? ctx.save()
        }
    }
    
    private func requestCalendarAccess() async {
        let granted = await calendarService.requestAccess()
        if granted {
            print("🔔 SettingsView - Calendar access granted successfully")
        } else {
            print("🔔 SettingsView - Calendar access denied")
        }
    }
}

#Preview {
    SettingsView(scheduler: Scheduler())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 