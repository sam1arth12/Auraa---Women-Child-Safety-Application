import Foundation
import SwiftUI
import Combine

class DistressDetectionViewModel: ObservableObject {
    @Published var isCheckInActive: Bool = false
    @Published var remainingCheckInSeconds: Int = 10
    @Published var currentDistressEvent: DistressEvent? = nil
    @Published var currentMotionImpactEvent: MotionAnomalyEvent? = nil
    @Published var distressReason: String = "Distress Sound Detected"
    @Published var shouldTriggerSOS: Bool = false
    
    let detector: SoundDistressDetector
    let motionDetector: MotionImpactDetector
    private var cancellables = Set<AnyCancellable>()
    private var checkInTimer: Timer? = nil
    
    init(detector: SoundDistressDetector, motionDetector: MotionImpactDetector = MotionImpactDetector()) {
        self.detector = detector
        self.motionDetector = motionDetector
        setupBindings()
    }
    
    private func setupBindings() {
        detector.$lastDetectedEvent
            .compactMap { $0 }
            .filter { $0.isHighConfidence }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleDetectedDistress(event)
            }
            .store(in: &cancellables)
            
        motionDetector.onAnomalyDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleDetectedMotionImpact(event)
            }
            .store(in: &cancellables)
    }
    
    func handleDetectedDistress(_ event: DistressEvent) {
        guard !isCheckInActive else { return }
        
        self.currentDistressEvent = event
        self.currentMotionImpactEvent = nil
        self.distressReason = "\(event.soundType.rawValue) Detected (\(Int(event.confidence * 100))% confidence)"
        startCheckInCountdown()
    }
    
    func handleDetectedMotionImpact(_ event: MotionAnomalyEvent) {
        guard !isCheckInActive else { return }
        
        self.currentMotionImpactEvent = event
        self.currentDistressEvent = nil
        self.distressReason = "\(event.type.rawValue): \(event.detail)"
        startCheckInCountdown()
    }
    
    private func startCheckInCountdown() {
        self.remainingCheckInSeconds = 10
        self.isCheckInActive = true
        
        checkInTimer?.invalidate()
        checkInTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingCheckInSeconds > 1 {
                self.remainingCheckInSeconds -= 1
            } else {
                self.checkInTimer?.invalidate()
                self.escalateToSOS()
            }
        }
    }
    
    func userConfirmedSafe() {
        checkInTimer?.invalidate()
        withAnimation {
            isCheckInActive = false
            currentDistressEvent = nil
            currentMotionImpactEvent = nil
        }
    }
    
    func escalateToSOS() {
        checkInTimer?.invalidate()
        withAnimation {
            isCheckInActive = false
            shouldTriggerSOS = true
        }
    }
}

