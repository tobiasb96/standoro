import Foundation
import Combine

/// Main orchestrator for motion services
@MainActor
class MotionService: ObservableObject {
    @Published var isEnabled = false
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var errorMessage: String?
    
    // Device status properties
    @Published var isDeviceAvailable = false
    @Published var isDeviceConnected = false
    @Published var isDeviceReceivingData = false
    
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
    }
    
    func requestAccess() async -> Bool {
        // If already authorized, don't request again
        if isAuthorized {
            return true
        }
        
        // Request notification authorization
        let notificationAuthorized = await notificationService.requestAuthorization()
        
        // Request motion provider access (system-level permission only)
        var motionAuthorized = false
        for provider in motionProviders {
            if await provider.requestAccess() {
                motionAuthorized = true
                break
            }
        }
        
        isAuthorized = notificationAuthorized && motionAuthorized
        
        // Only set error message for system-level issues (no providers available at all)
        if !motionAuthorized {
            errorMessage = "No motion providers available. Please ensure you have AirPods connected and are running macOS Sonoma 14.0+"
        } else {
            // Clear any existing error message when access is granted
            errorMessage = nil
        }
        
        return isAuthorized
    }
    
    func startMonitoring() {
        guard isAuthorized else {
            return
        }
        
        // Prevent multiple starts
        if isMonitoring {
            return
        }
        
        // Start all motion providers
        for provider in motionProviders {
            provider.startUpdates()
        }
        
        isMonitoring = true
        isEnabled = true
    }
    
    func stopMonitoring() {
        // Prevent multiple stops
        if !isMonitoring {
            return
        }
        
        // Stop all motion providers
        for provider in motionProviders {
            provider.stopUpdates()
        }
        
        isMonitoring = false
        isEnabled = false
    }
    
    // MARK: - Posture Methods
    
    func startPostureCalibration() {
        guard isDeviceReceivingData else {
            return
        }
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
        
        // Subscribe to device status changes
        if let airPodsProvider = airPodsProvider as? AirPodsMotionProvider {
            airPodsProvider.$isAvailable
                .sink { [weak self] available in
                    self?.isDeviceAvailable = available
                    // Clear error message when device becomes available
                    if available {
                        self?.errorMessage = nil
                    }
                }
                .store(in: &cancellables)
            
            airPodsProvider.$isConnected
                .sink { [weak self] connected in
                    self?.isDeviceConnected = connected
                    // Clear error message when device connects (assuming it's a connection issue)
                    if connected {
                        self?.errorMessage = nil
                    }
                }
                .store(in: &cancellables)
            
            airPodsProvider.$isReceivingData
                .sink { [weak self] receivingData in
                    self?.isDeviceReceivingData = receivingData
                    if !receivingData {
                        // Set posture to noData when not receiving data
                        self?.postureAnalyzer.setNoData()
                    }
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
            .assign(to: \.currentPosture, on: self)
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