import Foundation
import CoreLocation

enum AnomalyType: String, Codable, CaseIterable, Identifiable {
    case routeDeviation = "Route Deviation Detected"
    case unusualStop = "Unusual Extended Stop"
    case suddenSpeedChange = "Sudden Speed Anomaly"
    case unfamiliarTimePlace = "Unfamiliar Place & Time"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .routeDeviation: return "arrow.triangle.branch"
        case .unusualStop: return "timer.square"
        case .suddenSpeedChange: return "gauge.badge.exclamationmark"
        case .unfamiliarTimePlace: return "mappin.and.ellipse"
        }
    }
}

enum AnomalySeverity: String, Codable {
    case low = "Low Risk"
    case medium = "Moderate Risk"
    case high = "High Risk - Immediate Action Needed"
}

struct LocationAnomaly: Identifiable, Codable {
    var id: UUID = UUID()
    var type: AnomalyType
    var severity: AnomalySeverity
    var confidenceScore: Double // 0.0 to 1.0
    var timestamp: Date = Date()
    var details: String
}

struct RouteOption: Identifiable {
    var id: UUID = UUID()
    var name: String
    var distanceKm: Double
    var estimatedMinutes: Int
    var mlPredictedETA: String
    var riskScore: Double // 0.0 (Safest) to 10.0 (High Risk)
    var isSafestRoute: Bool = false
    var highlights: [String]
    var waypoints: [CLLocationCoordinate2D]
}
