import Foundation
import CoreMotion
import Combine

public final class MotionImpactDetector: ObservableObject {
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var currentGForce: Double = 1.0
    @Published public private(set) var lastEvent: MotionAnomalyEvent? = nil
    
    public let onAnomalyDetected = PassthroughSubject<MotionAnomalyEvent, Never>()
    
    private let motionManager = CMMotionManager()
    private let updateQueue = OperationQueue()
    
    // Pattern buffers for freefall and struggle classification
    private var gForceBuffer: [Double] = []
    private var rotationBuffer: [Double] = []
    private var inFreefallWindow: Bool = false
    private var freefallTimestamp: Date? = nil
    
    public init() {
        updateQueue.name = "myself.womensafety.motionQueue"
        updateQueue.qualityOfService = .userInteractive
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.02 // 50 Hz sampling
            motionManager.startDeviceMotionUpdates(to: updateQueue) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else { return }
                self.processDeviceMotion(motion)
            }
        } else if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            motionManager.startAccelerometerUpdates(to: updateQueue) { [weak self] accel, error in
                guard let self = self, let accel = accel, error == nil else { return }
                self.processAccelerometer(accel)
            }
        } else {
            print("CoreMotion device motion & accelerometer unavailable (running on Simulator). Use simulateMotionAnomaly() for testing.")
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
        if motionManager.isAccelerometerAvailable {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    // MARK: - CoreMotion Signal Processing Algorithm
    
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        let ax = motion.userAcceleration.x + motion.gravity.x
        let ay = motion.userAcceleration.y + motion.gravity.y
        let az = motion.userAcceleration.z + motion.gravity.z
        
        let gMag = sqrt(ax * ax + ay * ay + az * az)
        
        let rx = motion.rotationRate.x
        let ry = motion.rotationRate.y
        let rz = motion.rotationRate.z
        let rotMag = sqrt(rx * rx + ry * ry + rz * rz)
        
        DispatchQueue.main.async {
            self.currentGForce = gMag
        }
        
        analyzeMotionData(gMag: gMag, rotMag: rotMag)
    }
    
    private func processAccelerometer(_ accel: CMAccelerometerData) {
        let ax = accel.acceleration.x
        let ay = accel.acceleration.y
        let az = accel.acceleration.z
        let gMag = sqrt(ax * ax + ay * ay + az * az)
        
        DispatchQueue.main.async {
            self.currentGForce = gMag
        }
        
        analyzeMotionData(gMag: gMag, rotMag: 0.0)
    }
    
    private func analyzeMotionData(gMag: Double, rotMag: Double) {
        let now = Date()
        
        // 1. Freefall detection (< 0.35 G)
        if gMag < 0.35 {
            inFreefallWindow = true
            freefallTimestamp = now
        }
        
        // Check freefall expiration window (within 1 second)
        if let ffTime = freefallTimestamp, now.timeIntervalSince(ffTime) > 1.2 {
            inFreefallWindow = false
            freefallTimestamp = nil
        }
        
        // 2. Hard Fall Detection (Freefall followed by > 3.2 G impact)
        if inFreefallWindow && gMag > 3.2 {
            inFreefallWindow = false
            freefallTimestamp = nil
            let event = MotionAnomalyEvent(
                type: .hardFall,
                gForce: gMag,
                rotationRate: rotMag,
                confidence: 0.92,
                detail: String(format: "Freefall followed by %.1fg impact", gMag)
            )
            triggerAnomaly(event)
            return
        }
        
        // 3. High Impact / Vehicle Collision (> 4.5 G impact spike)
        if gMag > 4.5 {
            let event = MotionAnomalyEvent(
                type: .highImpact,
                gForce: gMag,
                rotationRate: rotMag,
                confidence: 0.88,
                detail: String(format: "High G-force impact registered: %.1fg", gMag)
            )
            triggerAnomaly(event)
            return
        }
        
        // 4. Physical Struggle Pattern (High rotation > 6.5 rad/s with high variance)
        rotationBuffer.append(rotMag)
        if rotationBuffer.count > 50 { rotationBuffer.removeFirst() }
        
        if rotMag > 6.5 {
            let avgRot = rotationBuffer.reduce(0, +) / Double(rotationBuffer.count)
            if avgRot > 4.0 {
                let event = MotionAnomalyEvent(
                    type: .physicalStruggle,
                    gForce: gMag,
                    rotationRate: rotMag,
                    confidence: 0.85,
                    detail: String(format: "Violent rotational oscillation detected (%.1f rad/s)", rotMag)
                )
                triggerAnomaly(event)
                rotationBuffer.removeAll()
                return
            }
        }
    }
    
    private func triggerAnomaly(_ event: MotionAnomalyEvent) {
        DispatchQueue.main.async {
            self.lastEvent = event
            self.onAnomalyDetected.send(event)
        }
    }
    
    // MARK: - Simulator Trigger Helpers
    
    public func simulateMotionAnomaly(type: MotionImpactType) {
        let event: MotionAnomalyEvent
        switch type {
        case .hardFall:
            event = MotionAnomalyEvent(
                type: .hardFall,
                gForce: 3.8,
                rotationRate: 4.2,
                confidence: 0.94,
                detail: "Simulated hard fall (0.2g freefall -> 3.8g impact)"
            )
        case .highImpact:
            event = MotionAnomalyEvent(
                type: .highImpact,
                gForce: 5.1,
                rotationRate: 2.1,
                confidence: 0.90,
                detail: "Simulated high impact crash (5.1g force)"
            )
        case .vehicleCollision:
            event = MotionAnomalyEvent(
                type: .vehicleCollision,
                gForce: 4.6,
                rotationRate: 1.5,
                confidence: 0.87,
                detail: "Simulated sudden deceleration / vehicle collision"
            )
        case .physicalStruggle:
            event = MotionAnomalyEvent(
                type: .physicalStruggle,
                gForce: 2.4,
                rotationRate: 7.8,
                confidence: 0.86,
                detail: "Simulated physical struggle gesture pattern"
            )
        }
        
        triggerAnomaly(event)
    }
}
