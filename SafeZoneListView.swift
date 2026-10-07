import SwiftUI
import CoreLocation

struct SafeZoneListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SafeZoneViewModel
    @ObservedObject var locationViewModel: LocationViewModel
    
    var showBackButton: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Bar with Top-Left Back Button
            HStack {
                if showBackButton {
                    TopLeftBackButton(title: "Back") {
                        dismiss()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safe Zones")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text("Verified 24/7 safe locations & emergency posts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Filter Chips Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SafeZoneCategory.allCases) { category in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedCategory = category
                            }
                        }) {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedCategory == category ?
                                        Color.blue : Color(.tertiarySystemFill)
                                )
                                .foregroundColor(
                                    viewModel.selectedCategory == category ?
                                        .white : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Safe Zones List
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.filteredZones()) { zone in
                        SafeZoneCard(zone: zone, currentLocation: locationViewModel.currentLocation)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 90)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct SafeZoneCard: View {
    let zone: SafeZone
    let currentLocation: CLLocation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: iconName(for: zone.category))
                            .foregroundColor(color(for: zone.category))
                        Text(zone.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Text(zone.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Text(zone.distanceFormatted(from: currentLocation))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            HStack(spacing: 12) {
                // Call Button
                Button(action: {
                    callNumber(phone: zone.phone)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call Post")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Get Directions Button
                Button(action: {
                    openDirections(latitude: zone.coordinate.latitude, longitude: zone.coordinate.longitude)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
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
