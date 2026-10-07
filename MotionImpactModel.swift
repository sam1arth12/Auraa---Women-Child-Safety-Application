import Foundation

public enum MotionImpactType: String, Codable, CaseIterable {
    case hardFall = "Hard Fall"
    case highImpact = "High Impact"
    case vehicleCollision = "Sudden Deceleration"
    case physicalStruggle = "Physical Struggle"
    
    public var iconName: String {
        switch self {
        case .hardFall: return "figure.fall"
        case .highImpact: return "bolt.shield.fill"
        case .vehicleCollision: return "car.side.fill"
        case .physicalStruggle: return "waveform.path.ecg.page"
        }
    }
}

public struct MotionAnomalyEvent: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: MotionImpactType
    public let gForce: Double
    public let rotationRate: Double
    public let confidence: Double
    public let detail: String
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), type: MotionImpactType, gForce: Double, rotationRate: Double, confidence: Double, detail: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.gForce = gForce
        self.rotationRate = rotationRate
        self.confidence = confidence
        self.detail = detail
    }
}
