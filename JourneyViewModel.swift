import Foundation
import SwiftUI
import CoreLocation
import Combine

class JourneyViewModel: ObservableObject {
    @Published var destinationName: String = ""
    @Published var estimatedMinutes: Int = 15
    @Published var isActive: Bool = false
    @Published var remainingSeconds: Int = 0
    @Published var journeyStatus: String = "No active journey"
    @Published var availableRoutes: [RouteOption] = []
    @Published var selectedRoute: RouteOption? = nil
    
    let anomalyDetector = RouteAnomalyDetector()
    private var timer: Timer? = nil
    
    func prepareRoutes(userLocation: CLLocationCoordinate2D, destination: String) {
        self.destinationName = destination
        self.availableRoutes = SafestRoutePlanner.generateRouteOptions(userLocation: userLocation, destinationName: destination)
        self.selectedRoute = availableRoutes.first(where: { $0.isSafestRoute }) ?? availableRoutes.first
    }
    
    func startJourney(destination: String, durationMinutes: Int) {
        self.destinationName = destination
        self.estimatedMinutes = durationMinutes
        self.remainingSeconds = durationMinutes * 60
        self.isActive = true
        self.journeyStatus = "Safe Journey Active"
        
        let waypoints = selectedRoute?.waypoints ?? []
        anomalyDetector.startMonitoring(plannedWaypoints: waypoints)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.timer?.invalidate()
                self.journeyStatus = "ETA Expired - Check-in Required!"
            }
        }
    }
    
    func confirmArrival() {
        timer?.invalidate()
        anomalyDetector.stopMonitoring()
        isActive = false
        journeyStatus = "Arrived Safely 🎉"
    }
    
    func cancelJourney() {
        timer?.invalidate()
        anomalyDetector.stopMonitoring()
        isActive = false
        journeyStatus = "Journey Cancelled"
    }
    
    var timeRemainingString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
