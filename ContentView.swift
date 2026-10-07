import SwiftUI
import Combine
import CoreLocation

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var locationViewModel = LocationViewModel()
    @StateObject private var safeZoneViewModel = SafeZoneViewModel()
    @StateObject private var guardiansViewModel = GuardiansViewModel()
    @StateObject private var journeyViewModel = JourneyViewModel()
    
    var body: some View {
        Group {
            if !authViewModel.isLoggedIn {
                LoginView(authViewModel: authViewModel)
            } else {
                switch authViewModel.currentUser?.role ?? .protectedUser {
                case .protectedUser:
                    ProtectedUserDashboardView(
                        authViewModel: authViewModel,
                        locationViewModel: locationViewModel,
                        safeZoneViewModel: safeZoneViewModel,
                        guardiansViewModel: guardiansViewModel,
                        journeyViewModel: journeyViewModel
                    )
                case .guardian:
                    GuardianDashboardView(
                        authViewModel: authViewModel,
                        locationViewModel: locationViewModel,
                        journeyViewModel: journeyViewModel,
                        safeZoneViewModel: safeZoneViewModel
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
