# App Store Publication Checklist

## ✅ Completed Tasks

### Code Changes
- [x] Fixed bundle identifier format (`com.standoro.app`)
- [x] Added required App Store metadata to Info.plist
- [x] Created comprehensive privacy policy
- [x] Added About view with privacy policy links
- [x] Updated SettingsView to include About view
- [x] Created App Store metadata documentation
- [x] Updated README with publication instructions

### App Store Requirements
- [x] App sandboxing enabled
- [x] Hardened runtime enabled
- [x] Proper entitlements configured
- [x] Privacy descriptions added
- [x] App category set (Health & Fitness)
- [x] Age rating determined (4+)

## 🔄 Remaining Tasks

### Before App Store Connect Setup

#### 1. Domain and Website Setup
- [ ] Register domain: `standoro.app`
- [ ] Create website with privacy policy page
- [ ] Create support page
- [ ] Set up contact email addresses

#### 2. App Store Connect Preparation
- [ ] Ensure Apple Developer Account is active
- [ ] Verify App Store Connect access
- [ ] Prepare app screenshots (8 required)
- [ ] Create app icon in all required sizes
- [ ] Write compelling app description
- [ ] Research and finalize keywords

#### 3. Final Testing
- [ ] Test app on macOS 14.0+
- [ ] Test app on macOS 15.0+
- [ ] Verify all permissions work correctly
- [ ] Test app with and without AirPods
- [ ] Test calendar integration
- [ ] Verify notification system
- [ ] Test app in Release mode
- [ ] Check for any console errors

### App Store Connect Setup

#### 1. Create App Record
- [ ] Log into App Store Connect
- [ ] Create new app
- [ ] Set bundle ID: `com.standoro.app`
- [ ] Choose platform: macOS
- [ ] Set app name: Standoro
- [ ] Set subtitle: Health & Productivity Companion
- [ ] Choose category: Health & Fitness
- [ ] Set age rating: 4+

#### 2. App Information
- [ ] Upload app description
- [ ] Set keywords
- [ ] Add promotional text
- [ ] Set privacy policy URL
- [ ] Set support URL
- [ ] Set marketing URL
- [ ] Add app review information

#### 3. App Store Assets
- [ ] Upload app icon (1024x1024)
- [ ] Upload screenshots (1280x800 minimum)
- [ ] Add app preview video (optional)
- [ ] Set app store artwork

### Build and Submit

#### 1. Archive App
- [ ] Open project in Xcode
- [ ] Select "Any Mac" target
- [ ] Set build configuration to Release
- [ ] Product → Archive
- [ ] Wait for archive to complete

#### 2. Upload to App Store Connect
- [ ] In Organizer, select archive
- [ ] Click "Distribute App"
- [ ] Choose "App Store Connect"
- [ ] Follow upload process
- [ ] Wait for processing (can take 30+ minutes)

#### 3. Submit for Review
- [ ] In App Store Connect, go to app
- [ ] Verify all metadata is complete
- [ ] Set pricing to Free
- [ ] Set availability to all countries
- [ ] Submit for review

### Post-Submission

#### 1. Monitor Review Process
- [ ] Check review status daily
- [ ] Respond to any review feedback
- [ ] Fix issues if app is rejected
- [ ] Resubmit if necessary

#### 2. After Approval
- [ ] Set release type (manual or automatic)
- [ ] Monitor app performance
- [ ] Respond to user reviews
- [ ] Track download statistics

## 📋 Screenshot Requirements

### Required Screenshots (8 total)
1. **Main Settings Window** - Show sidebar and main settings
2. **Onboarding Welcome** - First onboarding screen
3. **Menu Bar Popup** - Menu bar icon and popup interface
4. **Posture Monitoring** - AirPods integration settings
5. **Statistics View** - Activity tracking and insights
6. **Focus Sessions** - Pomodoro timer interface
7. **Calendar Integration** - Meeting detection settings
8. **About Screen** - App information and privacy policy

### Screenshot Specifications
- **Resolution**: 1280 x 800 pixels minimum
- **Format**: PNG or JPEG
- **Color Space**: sRGB
- **File Size**: Under 2MB each
- **Content**: Must show actual app functionality

## 🔧 Technical Requirements

### Build Settings
- **Deployment Target**: macOS 14.0+
- **Architectures**: Apple Silicon, Intel
- **Code Signing**: Automatic (with Developer Team)
- **App Sandbox**: Enabled
- **Hardened Runtime**: Enabled

### Entitlements (Already Configured)
- `com.apple.security.app-sandbox`
- `com.apple.security.network.client`
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.automation.apple-events`
- `com.apple.security.device.motion`
- `com.apple.security.personal-information.calendars`
- `com.apple.security.device.audio-input`
- `com.apple.security.device.audio-output`

## 📝 App Store Metadata

### App Description (Use from AppStoreMetadata.md)
- Compelling introduction
- Feature highlights
- Target audience
- Call to action

### Keywords (100 characters max)
```
posture,standing desk,health,productivity,pomodoro,focus,ergonomics,airpods,motion,wellness
```

### Promotional Text (170 characters max)
```
Transform your desk work with intelligent health reminders and posture monitoring using AirPods.
```

## 🚨 Common Rejection Reasons

### Technical Issues
- App crashes during review
- Missing required permissions
- Incomplete functionality
- Poor performance

### Content Issues
- Missing privacy policy
- Incomplete app description
- Poor quality screenshots
- Misleading information

### Policy Violations
- Inappropriate content
- Copyright violations
- Spam or misleading behavior
- Incomplete app functionality

## 📞 Support Resources

### Apple Developer Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [macOS App Distribution](https://developer.apple.com/distribute/macos/)

### Contact Information
- **Apple Developer Support**: https://developer.apple.com/contact/
- **App Store Connect Support**: https://appstoreconnect.apple.com/contact

---

**Status**: Ready for App Store Connect setup
**Next Step**: Register domain and create website
**Estimated Time to Publication**: 1-2 weeks 