# Standoro

A macOS menu bar application that helps you maintain good posture and productivity through intelligent reminders, motion detection, and focus sessions.

## 🎯 Overview

Standoro is a comprehensive wellness and productivity app that combines:

- **Posture Monitoring**: Uses AirPods motion data to detect poor posture and provide gentle reminders
- **Stand/Desk Reminders**: Alternates between sitting and standing periods to reduce sedentary behavior
- **Focus Sessions**: Pomodoro timer with customizable intervals
- **Calendar Integration**: Automatically mutes reminders during meetings
- **Activity Challenges**: Gamified movement prompts to keep you active
- **Statistics Tracking**: Monitor your wellness habits over time

<div style="display: flex; overflow-x: auto; gap: 12px; padding-bottom: 8px;">
  <img width="400" alt="Standoro_Timer" src="https://github.com/user-attachments/assets/c2278436-392f-4270-a6ed-a91748dde369" />
  <img width="400" alt="Standoro_Stats" src="https://github.com/user-attachments/assets/42449aa5-6e15-48c1-bee8-447fed35204e" />
  <img width="400" alt="Standoro_Settings" src="https://github.com/user-attachments/assets/de9a879d-fd71-44e6-9428-82505a5ad523" />
  <img width="400" alt="Standoro_Movement" src="https://github.com/user-attachments/assets/2b445a58-d758-4bea-afd2-8be9561aef7c" />
</div>

<sub><i>Scroll horizontally to view more screenshots.</i></sub>

## 🏗️ Architecture

The app follows a modular architecture with clear separation of concerns:

### Core Services
- **`MotionService`**: Orchestrates motion detection and posture analysis
- **`Scheduler`**: Manages timing for stand/desk cycles and focus sessions
- **`CalendarService`**: Handles calendar integration and meeting detection
- **`StatsService`**: Tracks and aggregates user activity data
- **`NotificationService`**: Manages all app notifications

### Feature Modules
- **`Posture/`**: Motion detection and posture analysis
- **`Focus/`**: Timer and scheduling functionality
- **`Settings/`**: User preferences and configuration
- **`Move/`**: Activity challenges and gamification
- **`Stats/`**: Data collection and analytics

## 🚀 Setup & Installation

### Prerequisites

- **macOS 14.0+ (Sonoma)**: Required for AirPods motion data access
- **Xcode 15.0+**: For development and building
- **AirPods**: For posture monitoring (optional but recommended)
- **Calendar Access**: For meeting detection (optional)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Standoro
   ```

2. **Open in Xcode**
   ```bash
   open Standoro.xcodeproj
   ```

3. **Build and Run**
   - Select your target device (Mac)
   - Press `Cmd+R` to build and run
   - The app will appear in your menu bar

### Production Build

1. **Configure signing**
   - Open project settings in Xcode
   - Select your development team
   - Update bundle identifier if needed

2. **Archive and distribute**
   - Select "Any Mac" as target
   - Product → Archive
   - Follow App Store Connect or direct distribution process

## 🔐 Permissions & Entitlements

### Required Permissions

The app requires several system permissions to function properly:

#### 1. Motion & Fitness
- **Purpose**: Access AirPods motion data for posture detection
- **Usage**: Detects head position and movement patterns
- **Request**: Automatically requested on first use
- **Entitlement**: `com.apple.security.device.motion`

#### 2. Calendar Access
- **Purpose**: Detect meetings and mute notifications during calls
- **Usage**: Checks calendar events to avoid interrupting meetings
- **Request**: Requested during onboarding
- **Entitlement**: `com.apple.security.personal-information.calendars`

#### 3. Notifications
- **Purpose**: Send posture reminders and session notifications
- **Usage**: Local notifications for posture alerts and timer completion
- **Request**: Automatically requested on app launch
- **System**: Uses `UNUserNotificationCenter`

#### 4. Apple Events
- **Purpose**: Calendar integration and system automation
- **Usage**: Access calendar data and control system behavior
- **Entitlement**: `com.apple.security.automation.apple-events`

### Sandbox Configuration

The app runs in a sandboxed environment with the following entitlements:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.device.motion</key>
<true/>
<key>com.apple.security.personal-information.calendars</key>
<true/>
```

## 📱 User Interface

### Menu Bar Integration
- **Persistent Menu Bar Item**: Shows current status and countdown
- **Quick Actions**: Start/stop, pause, and settings access
- **Status Indicators**: Visual feedback for posture and session state

### Main Window
- **Onboarding**: First-time setup and permission requests
- **Settings Panel**: Comprehensive configuration options
- **Statistics View**: Activity tracking and progress visualization

### Popup Interface
- **Session Controls**: Timer controls and phase information
- **Quick Settings**: Essential configuration options
- **Status Overview**: Current posture and session details

## ⚙️ Configuration

### User Preferences

The app stores all settings in a `UserPrefs` model with the following key options:

#### Timing Settings
- **Sit Duration**: Maximum sitting time (default: 45 minutes)
- **Stand Duration**: Standing break duration (default: 15 minutes)
- **Auto-start**: Automatically start sessions on app launch

#### Posture Monitoring
- **Enable Monitoring**: Toggle posture detection
- **Sensitivity**: Adjust detection sensitivity (degrees)
- **Threshold**: Poor posture duration before alert
- **Nudges**: Enable gentle posture reminders

#### Focus Sessions
- **Pomodoro Mode**: Enable traditional Pomodoro timing
- **Focus Interval**: Work session duration (default: 25 minutes)
- **Short Break**: Short break duration (default: 5 minutes)
- **Long Break**: Long break duration (default: 15 minutes)

#### Calendar Integration
- **Meeting Detection**: Mute notifications during calendar events
- **Calendar Filter**: Enable/disable calendar integration

## 🔧 Technical Details

### Dependencies

#### System Frameworks
- **SwiftUI**: Modern UI framework
- **SwiftData**: Local data persistence
- **Combine**: Reactive programming
- **UserNotifications**: Local notification system
- **EventKit**: Calendar integration
- **CoreMotion**: Motion data access (via AirPods)

#### macOS Requirements
- **macOS 14.0+**: Required for AirPods motion data
- **Swift 5.9+**: Language version
- **Xcode 15.0+**: Development environment

### Data Models

#### UserPrefs (SwiftData Model)
```swift
@Model
class UserPrefs {
    var maxSitMinutes: Int
    var maxStandMinutes: Int
    var calendarFilter: Bool
    var postureMonitoringEnabled: Bool?
    var pomodoroModeEnabled: Bool?
    // ... additional properties
}
```

#### ActivityRecord (Statistics)
```swift
struct ActivityRecord {
    let date: Date
    let focusSeconds: TimeInterval
    let sittingSeconds: TimeInterval
    let standingSeconds: TimeInterval
    let breaksTaken: Int
    let postureAlerts: Int
}
```

### Motion Detection Architecture

The motion detection system uses a modular architecture:

1. **Motion Providers**: Abstract data sources (AirPods, iPhone, etc.)
2. **Analyzers**: Feature-specific analysis (posture, standup detection)
3. **Notification Service**: Centralized notification management
4. **Motion Service**: Main orchestrator coordinating all components

### Performance Considerations

- **Battery Optimization**: Motion detection uses efficient sampling rates
- **Memory Management**: In-memory statistics with planned persistence
- **CPU Usage**: Minimal background processing
- **Network**: No external network dependencies

## 🆘 Support

### Troubleshooting

#### Common Issues

1. **Motion Detection Not Working**
   - Ensure AirPods are connected
   - Check motion permissions in System Preferences
   - Verify macOS 14.0+ requirement

2. **Calendar Integration Issues**
   - Grant calendar access in System Preferences
   - Check sandbox entitlements
   - Verify calendar app permissions

3. **Notifications Not Appearing**
   - Check notification permissions
   - Verify Do Not Disturb settings
   - Check notification center settings

#### Debug Information
- Check Console.app for detailed logs
- Enable debug logging in app settings
- Verify entitlements and permissions

---

**Standoro** - Your intelligent companion for better posture and productivity. 
