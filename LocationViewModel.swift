import Foundation
import SwiftUI
import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var isUpdating: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentAddress: String? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var location: CLLocation? {
        get { currentLocation }
        set { currentLocation = newValue }
    }
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        authorizationStatus = locationManager.authorizationStatus
        requestLocation()
    }
    
    func requestLocation() {
        isUpdating = true
        errorMessage = nil
        
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            isUpdating = false
            errorMessage = "Location permission denied. Please enable Location Services in iOS Settings."
            // Fallback location for demo if permission is denied
            setDefaultFallbackIfNeeded()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        // If GPS hardware is slow or simulator location is unselected, set initial default fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            if self.currentLocation == nil {
                self.setDefaultFallbackIfNeeded()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.errorMessage = nil
                self.locationManager.startUpdatingLocation()
                self.locationManager.requestLocation()
            case .denied, .restricted:
                self.isUpdating = false
                self.errorMessage = "Location permission denied. Enable in Settings."
                self.setDefaultFallbackIfNeeded()
            default:
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = newLocation
            self.isUpdating = false
            self.errorMessage = nil
        }
        
        // Reverse geocode live location to street address
        geocoder.reverseGeocodeLocation(newLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                var addressParts: [String] = []
                if let name = placemark.name { addressParts.append(name) }
                if let locality = placemark.locality { addressParts.append(locality) }
                if let administrativeArea = placemark.administrativeArea { addressParts.append(administrativeArea) }
                
                DispatchQueue.main.async {
                    self.currentAddress = addressParts.isEmpty ? "Live GPS Coordinates" : addressParts.joined(separator: ", ")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isUpdating = false
            print("CoreLocation error: \(error.localizedDescription)")
            if self.currentLocation == nil {
                self.setDefaultFallbackIfNeeded()
            }
        }
    }
    
    private func setDefaultFallbackIfNeeded() {
        if currentLocation == nil {
            // Default active location (e.g. San Francisco Civic Center)
            let fallback = CLLocation(latitude: 37.7749, longitude: -122.4194)
            self.currentLocation = fallback
            self.currentAddress = "Market St, San Francisco, CA (Simulated)"
            self.isUpdating = false
        }
    }
}
