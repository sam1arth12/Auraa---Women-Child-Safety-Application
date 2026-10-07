import Foundation

enum DistressSoundType: String, Codable, CaseIterable, Identifiable {
    case scream = "Scream / Yell"
    case shouting = "Aggressive Shouting"
    case glassBreak = "Glass Breaking"
    case voiceTrigger = "AURA Help (Custom Phrase)"
    case duressCode = "Duress Code Word"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .scream: return "waveform.path.badge.exclamationmark"
        case .shouting: return "speaker.wave.3.fill"
        case .glassBreak: return "shield.slash.fill"
        case .voiceTrigger: return "mic.badge.plus"
        case .duressCode: return "lock.shield.fill"
        }
    }
}

struct DistressEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var soundType: DistressSoundType
    var confidence: Double // 0.0 to 1.0
    var timestamp: Date = Date()
    
    var isHighConfidence: Bool {
        return confidence >= 0.70
    }
}
