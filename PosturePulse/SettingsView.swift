import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    let scheduler: Scheduler

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Integrations")
                            .font(.headline)
                            .foregroundColor(.white)
                        Toggle("Mute alerts during calendar meetings",
                               isOn: Binding(
                                   get: { self.userPrefs.calendarFilter },
                                   set: { 
                                       self.userPrefs.calendarFilter = $0
                                       try? ctx.save()
                                   }
                               ))
                               .toggleStyle(CustomToggleStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
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
                }
            }
        }
        .padding(32)
        .frame(width: 480, height: 450)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .onDisappear {
            // Save context when the window is closed
            try? ctx.save()
        }
    }
}

#Preview {
    SettingsView(scheduler: Scheduler())
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 