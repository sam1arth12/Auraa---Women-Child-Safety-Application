import Foundation
import CoreLocation
import Combine

class RouteAnomalyDetector: ObservableObject {
    @Published var activeAnomaly: LocationAnomaly? = nil
    @Published var isMonitoring: Bool = false
    @Published var currentRiskScore: Double = 1.2 // Low risk baseline
    
    private var plannedWaypoints: [CLLocationCoordinate2D] = []
    private var lastLocation: CLLocation?
    private var stopStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    func startMonitoring(plannedWaypoints: [CLLocationCoordinate2D]) {
        self.plannedWaypoints = plannedWaypoints
        self.isMonitoring = true
        self.activeAnomaly = nil
        self.stopStartTime = nil
    }
    
    func stopMonitoring() {
        self.isMonitoring = false
        self.activeAnomaly = nil
        self.stopStartTime = nil
    }
    
    func processNewLocation(_ location: CLLocation) {
        guard isMonitoring else { return }
        
        // 1. Check Route Deviation
        if !plannedWaypoints.isEmpty {
            let minDistance = distanceFromRoute(location.coordinate, waypoints: plannedWaypoints)
            if minDistance > 150.0 { // 150 meters threshold
                let anomaly = LocationAnomaly(
                    type: .routeDeviation,
                    severity: .high,
                    confidenceScore: 0.89,
                    details: String(format: "You are %.0fm off your planned safe journey route.", minDistance)
                )
                triggerAnomaly(anomaly)
                return
            }
        }
        
        // 2. Check Unusual Extended Stop
        if let last = lastLocation {
            let speed = location.speed > 0 ? location.speed : 0
            if speed < 0.5 { // Less than 0.5 m/s (~1.8 km/h)
                if stopStartTime == nil {
                    stopStartTime = Date()
                } else if let start = stopStartTime, Date().timeIntervalSince(start) > 240 { // 4 minutes
                    let anomaly = LocationAnomaly(
                        type: .unusualStop,
                        severity: .medium,
                        confidenceScore: 0.82,
                        details: "Stationary stop detected for over 4 minutes in an unexpected area."
                    )
                    triggerAnomaly(anomaly)
                    return
                }
            } else {
                stopStartTime = nil
            }
        }
        
        self.lastLocation = location
    }
    
    // Simulator trigger for testing
    func simulateRouteDeviation() {
        let anomaly = LocationAnomaly(
            type: .routeDeviation,
            severity: .high,
            confidenceScore: 0.92,
            details: "Simulated: Vehicle deviated 280 meters from expected trajectory."
        )
        triggerAnomaly(anomaly)
    }
    
    func clearAnomaly() {
        DispatchQueue.main.async {
            self.activeAnomaly = nil
        }
    }
    
    private func triggerAnomaly(_ anomaly: LocationAnomaly) {
        DispatchQueue.main.async {
            self.activeAnomaly = anomaly
            self.currentRiskScore = 7.8
        }
    }
    
    private func distanceFromRoute(_ point: CLLocationCoordinate2D, waypoints: [CLLocationCoordinate2D]) -> Double {
        guard waypoints.count >= 2 else { return 0.0 }
        
        var minDistance = Double.greatestFiniteMagnitude
        let userLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
        
        for way in waypoints {
            let wayLoc = CLLocation(latitude: way.latitude, longitude: way.longitude)
            let dist = userLoc.distance(from: wayLoc)
            if dist < minDistance {
                minDistance = dist
            }
        }
        
        return minDistance
    }
}
