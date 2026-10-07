import SwiftUI
import MapKit
import CoreLocation

struct LiveMapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var safeZoneViewModel: SafeZoneViewModel
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    @State private var isTrackingUser = true
    @State private var selectedZone: SafeZone? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Interactive MapKit Map showing live user location
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: safeZoneViewModel.safeZones) { zone in
                MapAnnotation(coordinate: zone.coordinate) {
                    Button(action: {
                        selectedZone = zone
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: iconName(for: zone.category))
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .background(color(for: zone.category))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                            
                            Text(zone.name)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.95))
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onChange(of: locationViewModel.currentLocation) { newLocation in
                if let loc = newLocation {
                    safeZoneViewModel.updateSafeZonesForLocation(loc)
                    if isTrackingUser {
                        withAnimation(.easeInOut) {
                            region.center = loc.coordinate
                        }
                    }
                }
            }
            
            // Top Control Bar: Top-Left Back Button & Live Address/Status Title
            HStack {
                TopLeftBackButton(title: "Back") {
                    dismiss()
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(locationViewModel.currentLocation != nil ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(locationViewModel.currentAddress ?? "Live User GPS Location")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.9))
                .clipShape(Capsule())
                .shadow(radius: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Floating Right-Side Map Controls
            VStack(spacing: 12) {
                // Recenter Button
                Button(action: {
                    isTrackingUser = true
                    locationViewModel.requestLocation()
                    if let loc = locationViewModel.currentLocation {
                        withAnimation(.spring()) {
                            region.center = loc.coordinate
                        }
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .foregroundColor(isTrackingUser ? .white : .blue)
                        .padding(12)
                        .background(isTrackingUser ? Color.blue : Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 6)
                }
                
                // Zoom to User Button
                Button(action: {
                    if let loc = locationViewModel.currentLocation {
                        withAnimation(.spring()) {
                            region.span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                            region.center = loc.coordinate
                        }
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 6)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 70)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Selected Safe Zone Detail Sheet Overlay
            if let zone = selectedZone {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: iconName(for: zone.category))
                                    .foregroundColor(color(for: zone.category))
                                Text(zone.name)
                                    .font(.headline.bold())
                            }
                            Text(zone.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            selectedZone = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            openDirections(latitude: zone.coordinate.latitude, longitude: zone.coordinate.longitude)
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                Text("Start Directions from Live Location")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(18)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            locationViewModel.requestLocation()
            if let loc = locationViewModel.currentLocation {
                region.center = loc.coordinate
                safeZoneViewModel.updateSafeZonesForLocation(loc)
            }
        }
    }
    
    private func iconName(for category: SafeZoneCategory) -> String {
        switch category {
        case .all: return "shield.fill"
        case .police: return "shield.checkered"
        case .hospital: return "cross.case.fill"
        case .safeHub: return "house.lodge.fill"
        }
    }
    
    private func color(for category: SafeZoneCategory) -> Color {
        switch category {
        case .all: return .blue
        case .police: return .indigo
        case .hospital: return .red
        case .safeHub: return .green
        }
    }
    
    private func openDirections(latitude: Double, longitude: Double) {
        let mapsURL = "http://maps.apple.com/?daddr=\(latitude),\(longitude)"
        if let url = URL(string: mapsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
