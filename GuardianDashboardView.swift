import SwiftUI
import MapKit
import CoreLocation

struct GuardianDashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var journeyViewModel: JourneyViewModel
    @ObservedObject var safeZoneViewModel: SafeZoneViewModel
    
    @State private var protectedPersonName = "Alex (Loved One)"
    @State private var protectedPersonPhone = "+1234567890"
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Bar with Back Button
                HStack {
                    TopLeftBackButton(title: "Switch Role") {
                        authViewModel.switchRole(to: .protectedUser)
                    }
                    Spacer()
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("Sign Out")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Guardian Header Banner
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guardian Mode")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.indigo)
                                Text("Safety Monitoring Hub")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "eye.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.indigo)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Protected Person Status Banner Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.indigo.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "person.shield.fill")
                                        .font(.title3)
                                        .foregroundColor(.indigo)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(protectedPersonName)
                                        .font(.headline.bold())
                                    Text("Live Safety Status: NORMAL")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.18))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                            
                            Divider()
                            
                            // Live Address
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENT LIVE LOCATION")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                
                                if let address = locationViewModel.currentAddress {
                                    Text(address)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                } else if let loc = locationViewModel.currentLocation {
                                    Text("Lat: \(loc.coordinate.latitude, specifier: "%.4f"), Long: \(loc.coordinate.longitude, specifier: "%.4f")")
                                        .font(.subheadline.weight(.semibold))
                                } else {
                                    Text("Connecting to live GPS...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal)
                        
                        // Mini Map Tracker Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Live Location Map")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            LiveMapView(locationViewModel: locationViewModel, safeZoneViewModel: safeZoneViewModel)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)
                        }
                        
                        // Journey Monitor Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.walk.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(journeyViewModel.isActive ? .green : .gray)
                                Text("Active Trip Tracker")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            if journeyViewModel.isActive {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Destination: \(journeyViewModel.destinationName)")
                                        .font(.subheadline.bold())
                                    HStack {
                                        Text("ETA Remaining:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(journeyViewModel.timeRemainingString)
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                }
                            } else {
                                Text("No active trip right now. You will be alerted automatically if a trip starts.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(18)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                callNumber(phone: protectedPersonPhone)
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call \(protectedPersonName)")
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AuraTheme.guardianIndigoGradient)
                                .clipShape(Capsule())
                                .shadow(color: Color.indigo.opacity(0.3), radius: 8, y: 4)
                            }
                            
                            if let loc = locationViewModel.currentLocation {
                                Button(action: {
                                    openDirections(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        Text("Get Directions to Loved One")
                                            .font(.headline.bold())
                                    }
                                    .foregroundColor(.indigo)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.indigo.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 36)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func callNumber(phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanPhone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openDirections(latitude: Double, longitude: Double) {
        let mapsURL = "http://maps.apple.com/?daddr=\(latitude),\(longitude)"
        if let url = URL(string: mapsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
