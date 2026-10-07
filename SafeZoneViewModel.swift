import Foundation
import SwiftUI
import CoreLocation
import Combine

enum SafeZoneCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case police = "Police"
    case hospital = "Hospital"
    case safeHub = "Safe Hub"
    
    var id: String { rawValue }
}

struct SafeZone: Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: SafeZoneCategory
    var address: String
    var phone: String
    var coordinate: CLLocationCoordinate2D
    var is24_7: Bool = true
    
    func distanceFormatted(from currentLocation: CLLocation?) -> String {
        guard let currentLocation = currentLocation else { return "Unknown distance" }
        let zoneLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceMeters = currentLocation.distance(from: zoneLocation)
        if distanceMeters < 1000 {
            return String(format: "%.0f m away", distanceMeters)
        } else {
            return String(format: "%.1f km away", distanceMeters / 1000.0)
        }
    }
}

class SafeZoneViewModel: ObservableObject {
    @Published var selectedCategory: SafeZoneCategory = .all
    @Published var safeZones: [SafeZone] = []
    
    init() {
        loadDefaultSafeZones()
    }
    
    func filteredZones() -> [SafeZone] {
        if selectedCategory == .all {
            return safeZones
        } else {
            return safeZones.filter { $0.category == selectedCategory }
        }
    }
    
    func updateSafeZonesForLocation(_ location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        safeZones = [
            SafeZone(
                name: "Central Women Police Station",
                category: .police,
                address: "Emergency Response Hub",
                phone: "112",
                coordinate: CLLocationCoordinate2D(latitude: lat + 0.0035, longitude: lon - 0.0025),
                is24_7: true
            ),
            SafeZone(
                name: "City Hospital (24/7 ER)",
                category: .hospital,
                address: "Medical Center Emergency Gate",
                phone: "+18005550199",
                coordinate: CLLocationCoordinate2D(latitude: lat - 0.0040, longitude: lon + 0.0030),
                is24_7: true
            ),
            SafeZone(
                name: "AURA Community Safe Shelter",
                category: .safeHub,
                address: "Civic Protection Plaza",
                phone: "+18005550123",
                coordinate: CLLocationCoordinate2D(latitude: lat + 0.0020, longitude: lon + 0.0045),
                is24_7: true
            ),
            SafeZone(
                name: "Metro Transit Police Post",
                category: .police,
                address: "Central Station Concourse",
                phone: "+18005550177",
                coordinate: CLLocationCoordinate2D(latitude: lat - 0.0025, longitude: lon - 0.0035),
                is24_7: true
            )
        ]
    }
    
    private func loadDefaultSafeZones() {
        safeZones = [
            SafeZone(
                name: "Central Women Police Station",
                category: .police,
                address: "Park Street, Sector 12",
                phone: "112",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                is24_7: true
            ),
            SafeZone(
                name: "City General Hospital (ER Emergency)",
                category: .hospital,
                address: "500 Medical Center Blvd",
                phone: "+18005550199",
                coordinate: CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167),
                is24_7: true
            ),
            SafeZone(
                name: "AURA 24/7 Community Safe Haven",
                category: .safeHub,
                address: "Civic Plaza Mall, Gate 3",
                phone: "+18005550123",
                coordinate: CLLocationCoordinate2D(latitude: 37.7690, longitude: -122.4225),
                is24_7: true
            )
        ]
    }
}
