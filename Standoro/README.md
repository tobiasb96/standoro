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

## 🧪 Testing

### Unit Tests
- Service layer testing
- Data model validation
- Timer accuracy verification

### Integration Tests
- Motion detection pipeline
- Calendar integration
- Notification delivery

### Manual Testing
- Permission flows
- UI responsiveness
- Real-world usage scenarios

## 🚀 Deployment

### App Store Distribution

#### Prerequisites
- Apple Developer Account ($99/year)
- App Store Connect access
- Xcode 15.0+ with proper signing certificates

#### Step-by-Step Publication Process

1. **Prepare App Store Connect**
   - Log into [App Store Connect](https://appstoreconnect.apple.com)
   - Create a new app record
   - Set bundle ID: `com.standoro.app`
   - Choose category: Health & Fitness
   - Set age rating: 4+

2. **Configure App Information**
   - App name: Standoro
   - Subtitle: Health & Productivity Companion
   - Keywords: posture,standing desk,health,productivity,pomodoro,focus,ergonomics,airpods,motion,wellness
   - Description: [See AppStoreMetadata.md for full description]
   - Privacy policy URL: https://standoro.app/privacy
   - Support URL: https://standoro.app/support

3. **Prepare Screenshots**
   - Take screenshots of key app features
   - Resolution: 1280 x 800 pixels minimum
   - Format: PNG or JPEG
   - File size: Under 2MB each
   - Required screenshots:
     - Main settings window
     - Onboarding flow
     - Menu bar integration
     - Posture monitoring settings
     - Statistics view
     - Focus sessions
     - Calendar integration
     - About screen

4. **Build and Archive**
   ```bash
   # In Xcode:
   # 1. Select "Any Mac" as target
   # 2. Product → Archive
   # 3. Wait for archive to complete
   ```

5. **Upload to App Store Connect**
   - In Organizer, select your archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow the upload process
   - Wait for processing to complete

6. **Submit for Review**
   - In App Store Connect, go to your app
   - Fill in all required metadata
   - Upload screenshots
   - Set pricing (Free)
   - Submit for review

#### App Store Review Process
- **Typical duration**: 1-3 days
- **Review criteria**: 
  - App functionality
  - Privacy compliance
  - User interface quality
  - Performance and stability
- **Common issues to avoid**:
  - Missing privacy policy
  - Incomplete app description
  - Poor quality screenshots
  - App crashes or bugs

#### Post-Publication
- Monitor app performance
- Respond to user reviews
- Track download statistics
- Plan future updates

### Direct Distribution (Alternative)

For distribution outside the App Store:

1. **Archive the project**
   ```bash
   # In Xcode:
   # Product → Archive
   ```

2. **Export as Developer ID-signed app**
   - Choose "Developer ID Distribution"
   - Sign with your Developer ID certificate

3. **Notarize with Apple**
   ```bash
   xcrun notarytool submit Standoro.app \
     --apple-id "your-apple-id@example.com" \
     --password "app-specific-password" \
     --team-id "YOUR_TEAM_ID"
   ```

4. **Staple the notarization ticket**
   ```bash
   xcrun stapler staple Standoro.app
   ```

5. **Distribute via direct download**

### Release Checklist

#### Before Submission
- [ ] App builds successfully in Release mode
- [ ] All required screenshots are prepared
- [ ] Privacy policy is published and accessible
- [ ] App icon meets App Store requirements
- [ ] App is tested on different macOS versions
- [ ] All permissions are properly configured
- [ ] App handles permission denials gracefully
- [ ] No placeholder content remains
- [ ] App metadata is complete and accurate

#### App Store Connect
- [ ] App record is created
- [ ] Bundle ID matches project
- [ ] Version and build numbers are set
- [ ] App description is uploaded
- [ ] Screenshots are uploaded
- [ ] App icon is uploaded
- [ ] Privacy policy URL is set
- [ ] Support URL is set
- [ ] Marketing URL is set
- [ ] Age rating is configured
- [ ] App review information is complete

#### Final Steps
- [ ] Archive app in Xcode
- [ ] Upload to App Store Connect
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Respond to any review feedback

### Version Management

#### Version Numbering
- **Format**: Major.Minor.Patch (e.g., 1.0.0)
- **Major**: Breaking changes or major features
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes and minor improvements

#### Update Process
1. Increment version numbers in Xcode
2. Update build number
3. Test thoroughly
4. Archive and upload
5. Submit for review

### Marketing and Promotion

#### App Store Optimization (ASO)
- **Keywords**: Research and optimize keywords
- **Description**: Clear, compelling app description
- **Screenshots**: High-quality, feature-focused screenshots
- **Reviews**: Encourage positive user reviews

#### External Promotion
- **Website**: Create a landing page
- **Social Media**: Share app features and updates
- **Press Kit**: Prepare media assets for journalists
- **User Feedback**: Collect and respond to user feedback

## 🤝 Contributing

### Development Guidelines
- Follow SwiftUI best practices
- Maintain modular architecture
- Add tests for new features
- Update documentation

### Code Style
- Use SwiftLint for consistency
- Follow Apple's Human Interface Guidelines
- Maintain accessibility standards

## 📄 License

[Add your license information here]

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

### Contact
[Add contact information for support]

---

**Standoro** - Your intelligent companion for better posture and productivity. 