import SwiftUI
import SwiftData

struct GeneralSettingsContentView: View {
    let userPrefs: UserPrefs
    let calendarService: CalendarService
    let scheduler: Scheduler
    let ctx: ModelContext
    let showExplanations: Bool
    
    init(userPrefs: UserPrefs, calendarService: CalendarService, scheduler: Scheduler, ctx: ModelContext, showExplanations: Bool = false) {
        self.userPrefs = userPrefs
        self.calendarService = calendarService
        self.scheduler = scheduler
        self.ctx = ctx
        self.showExplanations = showExplanations
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Menu Bar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showExplanations {
                    Text("Show the countdown timer in your menu bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Show countdown in menu bar",
                       isOn: Binding(
                           get: { userPrefs.showMenuBarCountdown },
                           set: { 
                               userPrefs.showMenuBarCountdown = $0
                               try? ctx.save()
                           }
                       ))
                       .toggleStyle(CustomToggleStyle())
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Calendar Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if showExplanations {
                    Text("Automatically mute alerts when you're in calendar meetings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Mute alerts during calendar meetings",
                           isOn: Binding(
                               get: { userPrefs.calendarFilter },
                               set: { newValue in
                                   userPrefs.calendarFilter = newValue
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
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            #if DEBUG
            VStack(alignment: .leading, spacing: 16) {
                Text("Development")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button("Reset Onboarding") {
                    UserDefaults.standard.set(false, forKey: "didOnboard")
                    NotificationCenter.default.post(name: NSNotification.Name("ResetOnboarding"), object: nil)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
            }
            #endif
        }
    }
    
    private func requestCalendarAccess() async {
        _ = await calendarService.requestAccess()
    }
}

#Preview {
    VStack(spacing: 20) {
        GeneralSettingsContentView(
            userPrefs: UserPrefs(),
            calendarService: CalendarService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: true
        )
        
        GeneralSettingsContentView(
            userPrefs: UserPrefs(),
            calendarService: CalendarService(),
            scheduler: Scheduler(),
            ctx: try! ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext,
            showExplanations: false
        )
    }
    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    .padding()
} 