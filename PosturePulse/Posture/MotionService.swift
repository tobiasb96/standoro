import Foundation
import Combine

/// Main orchestrator for motion services
@MainActor
class MotionService: ObservableObject {
    @Published var isEnabled = false
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var errorMessage: String?
    
    // Published properties for UI - these will trigger UI updates
    @Published var currentPosture: PostureStatus = .unknown
    @Published var currentPitch: Double = 0.0
    @Published var currentRoll: Double = 0.0
    @Published var pitchDeviation: Double = 0.0
    @Published var rollDeviation: Double = 0.0
    @Published var isStanding: Bool = false
    
    // Motion providers
    private var motionProviders: [MotionProvider] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Feature services
    private let postureAnalyzer = PostureAnalyzer()
    private let standupDetector = StandupDetector()
    private let notificationService = NotificationService()
    
    init() {
        setupMotionProviders()
        setupNotificationHandlers()
        setupPropertyBindings()
    }
    
    // MARK: - Public Methods
    
    func setCalendarService(_ calendarService: CalendarService, shouldCheck: Bool) {
        notificationService.setCalendarService(calendarService, shouldCheck: shouldCheck)
        print("🔔 MotionService - Calendar service set, should check: \(shouldCheck)")
    }
    
    func requestAccess() async -> Bool {
        // Request notification authorization
        let notificationAuthorized = await notificationService.requestAuthorization()
        
        // Request motion provider access
        var motionAuthorized = false
        for provider in motionProviders {
            if await provider.requestAccess() {
                motionAuthorized = true
                break
            }
        }
        
        isAuthorized = notificationAuthorized && motionAuthorized
        
        if !motionAuthorized {
            errorMessage = "No motion providers available. Please ensure you have AirPods connected and are running macOS Sonoma 14.0+"
        }
        
        return isAuthorized
    }
    
    func startMonitoring() {
        guard isAuthorized else {
            print("🔔 MotionService - Not authorized to monitor")
            return
        }
        
        print("🔔 MotionService - Starting monitoring...")
        
        // Start all motion providers
        for provider in motionProviders {
            provider.startUpdates()
        }
        
        isMonitoring = true
        isEnabled = true
    }
    
    func stopMonitoring() {
        print("🔔 MotionService - Stopping monitoring...")
        
        // Stop all motion providers
        for provider in motionProviders {
            provider.stopUpdates()
        }
        
        isMonitoring = false
        isEnabled = false
    }
    
    // MARK: - Posture Methods
    
    func startPostureCalibration() {
        postureAnalyzer.startCalibration()
    }
    
    func completePostureCalibration() {
        postureAnalyzer.completeCalibration()
    }
    
    func setPostureThresholds(pitch: Double, roll: Double, duration: TimeInterval) {
        postureAnalyzer.setPitchThreshold(pitch)
        postureAnalyzer.setRollThreshold(roll)
        postureAnalyzer.setPoorPostureThreshold(duration)
    }
    
    func setPostureUpdateFrequency(_ frequency: TimeInterval) {
        postureAnalyzer.setUpdateFrequency(frequency)
    }
    
    func enablePostureHighFrequencyMode() {
        postureAnalyzer.enableHighFrequencyMode()
    }
    
    func disablePostureHighFrequencyMode() {
        postureAnalyzer.disableHighFrequencyMode()
    }
    
    // MARK: - Standup Methods
    
    func setStandupAccelerationThreshold(_ threshold: Double) {
        standupDetector.setAccelerationThreshold(threshold)
    }
    
    func enableStandupHighFrequencyMode() {
        standupDetector.enableHighFrequencyMode()
    }
    
    func disableStandupHighFrequencyMode() {
        standupDetector.disableHighFrequencyMode()
    }
    
    // MARK: - Private Methods
    
    private func setupMotionProviders() {
        // Add AirPods provider
        let airPodsProvider = AirPodsMotionProvider()
        motionProviders.append(airPodsProvider)
        
        // Subscribe to motion data from all providers
        for provider in motionProviders {
            provider.motionDataPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] motionData in
                    self?.processMotionData(motionData)
                }
                .store(in: &cancellables)
        }
    }
    
    private func setupNotificationHandlers() {
        // Listen for posture threshold reached
        NotificationCenter.default.publisher(for: .postureThresholdReached)
            .sink { [weak self] _ in
                self?.notificationService.sendPostureNotification()
            }
            .store(in: &cancellables)
        
        // Listen for standup detected
        NotificationCenter.default.publisher(for: .standupDetected)
            .sink { [weak self] _ in
                self?.notificationService.sendStandupNotification()
            }
            .store(in: &cancellables)
    }
    
    private func setupPropertyBindings() {
        // Bind posture analyzer properties to published properties
        postureAnalyzer.$currentPosture
            .sink { [weak self] newPosture in
                print("🔔 MotionService - Posture changed to: \(newPosture)")
                self?.currentPosture = newPosture
            }
            .store(in: &cancellables)
        
        postureAnalyzer.$currentPitch
            .assign(to: \.currentPitch, on: self)
            .store(in: &cancellables)
        
        postureAnalyzer.$currentRoll
            .assign(to: \.currentRoll, on: self)
            .store(in: &cancellables)
        
        postureAnalyzer.$pitchDeviation
            .assign(to: \.pitchDeviation, on: self)
            .store(in: &cancellables)
        
        postureAnalyzer.$rollDeviation
            .assign(to: \.rollDeviation, on: self)
            .store(in: &cancellables)
        
        // Bind standup detector properties
        standupDetector.$isStanding
            .assign(to: \.isStanding, on: self)
            .store(in: &cancellables)
    }
    
    private func processMotionData(_ motionData: MotionData) {
        // Process data for all analyzers
        postureAnalyzer.processMotionData(motionData)
        standupDetector.processMotionData(motionData)
    }
}

// MARK: - Type Aliases for Backward Compatibility
typealias PostureStatus = PostureAnalyzer.PostureStatus 