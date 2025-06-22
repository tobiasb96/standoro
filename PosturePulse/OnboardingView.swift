import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [UserPrefs]
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var currentPage = 0
    @State private var standGoal = 15
    @State private var maxSitBlock = 45
    @State private var notificationsGranted = false
    @State private var calendarGranted = false
    
    private var userPrefs: UserPrefs {
        if let p = prefs.first {
            return p
        } else {
            let newPrefs = UserPrefs()
            ctx.insert(newPrefs)
            try? ctx.save()
            return newPrefs
        }
    }
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Goals Setup
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Welcome to PosturePulse")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Let's set up your posture goals")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Standing Goal")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("How long would you like to stand for each session?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            IntervalSliderView(
                                label: "Minutes",
                                minutes: $standGoal,
                                quickOptions: [5, 10, 15, 20],
                                context: ctx
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Maximum Sitting Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("How long can you sit before needing a break?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            IntervalSliderView(
                                label: "Minutes",
                                minutes: $maxSitBlock,
                                quickOptions: [25, 45, 60, 90],
                                context: ctx
                            )
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button("Next") {
                            currentPage = 1
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .padding(32)
                .tag(0)
                
                // Page 2: Permissions
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Permissions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("PosturePulse needs a few permissions to work effectively")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 24) {
                        PermissionCard(
                            title: "Notifications",
                            description: "Get reminded when it's time to stand or sit",
                            icon: "bell.fill",
                            isGranted: $notificationsGranted,
                            onRequest: requestNotificationPermission
                        )
                        
                        PermissionCard(
                            title: "Calendar Access",
                            description: "Mute alerts during calendar meetings",
                            icon: "calendar",
                            isGranted: $calendarGranted,
                            onRequest: requestCalendarPermission
                        )
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button("Get Started") {
                            savePreferences()
                            didOnboard = true
                            NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .padding(32)
                .tag(1)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 500, height: 700)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .overlay(
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color(red: 0.2, green: 0.4, blue: 0.9) : Color.gray.opacity(0.4))
                            .frame(width: 12, height: 12)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
            }
        )
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        // Check notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // Check calendar permission
        let calendarService = CalendarService()
        calendarGranted = calendarService.isAuthorized
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsGranted = granted
            }
        }
    }
    
    private func requestCalendarPermission() {
        Task {
            let calendarService = CalendarService()
            let granted = await calendarService.requestAccess()
            DispatchQueue.main.async {
                calendarGranted = granted
            }
        }
    }
    
    private func savePreferences() {
        userPrefs.maxStandMinutes = standGoal
        userPrefs.maxSitMinutes = maxSitBlock
        userPrefs.calendarFilter = calendarGranted
        try? ctx.save()
        
        // Send congratulatory notification
        sendCongratulatoryNotification()
    }
    
    private func sendCongratulatoryNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                content.title = "🎉 Welcome to PosturePulse!"
                content.body = "Great decision to work on your posture! Your first reminder will come in \(maxSitBlock) minutes."
                content.sound = .default
                
                let req = UNNotificationRequest(
                    identifier: "onboarding-complete",
                    content: content,
                    trigger: nil
                )
                
                UNUserNotificationCenter.current().add(req) { error in
                    if let error = error {
                        print("🔔 Congratulatory notification error: \(error)")
                    } else {
                        print("🔔 Congratulatory notification sent successfully")
                    }
                }
            }
        }
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant") {
                    onRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserPrefs.self, inMemory: true)
} 