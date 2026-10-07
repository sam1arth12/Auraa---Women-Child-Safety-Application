import SwiftUI
import CoreLocation

struct ProtectedUserDashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var safeZoneViewModel: SafeZoneViewModel
    @ObservedObject var guardiansViewModel: GuardiansViewModel
    @ObservedObject var journeyViewModel: JourneyViewModel
    
    @StateObject private var soundDetector = SoundDistressDetector()
    @StateObject private var motionDetector = MotionImpactDetector()
    @StateObject private var distressViewModel: DistressDetectionViewModel
    
    @State private var selectedTab: Tab = .home
    @State private var showEmergencySheet = false
    
    init(authViewModel: AuthViewModel, locationViewModel: LocationViewModel, safeZoneViewModel: SafeZoneViewModel, guardiansViewModel: GuardiansViewModel, journeyViewModel: JourneyViewModel) {
        self.authViewModel = authViewModel
        self.locationViewModel = locationViewModel
        self.safeZoneViewModel = safeZoneViewModel
        self.guardiansViewModel = guardiansViewModel
        self.journeyViewModel = journeyViewModel
        
        let sound = SoundDistressDetector()
        let motion = MotionImpactDetector()
        _soundDetector = StateObject(wrappedValue: sound)
        _motionDetector = StateObject(wrappedValue: motion)
        _distressViewModel = StateObject(wrappedValue: DistressDetectionViewModel(detector: sound, motionDetector: motion))
    }
    
    enum Tab {
        case home, map, journey, guardians, safety, profile
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView(
                    authViewModel: authViewModel,
                    locationViewModel: locationViewModel,
                    guardiansViewModel: guardiansViewModel,
                    journeyViewModel: journeyViewModel,
                    soundDetector: soundDetector,
                    motionDetector: motionDetector,
                    onTriggerSOS: { showEmergencySheet = true }
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
                
                // Live Map Tab
                LiveMapView(locationViewModel: locationViewModel, safeZoneViewModel: safeZoneViewModel)
                    .tabItem {
                        Label("Live Map", systemImage: "map.fill")
                    }
                    .tag(Tab.map)
                
                // Journey Tab
                JourneyView(journeyViewModel: journeyViewModel, onBack: { selectedTab = .home })
                    .tabItem {
                        Label("Journey", systemImage: "figure.walk.motion")
                    }
                    .tag(Tab.journey)
                
                // Guardians Tab
                GuardiansView(guardiansViewModel: guardiansViewModel, onBack: { selectedTab = .home })
                    .tabItem {
                        Label("Guardians", systemImage: "person.2.fill")
                    }
                    .tag(Tab.guardians)
                
                // Safe Zones Tab
                SafetyView(safeZoneViewModel: safeZoneViewModel, locationViewModel: locationViewModel, onBack: { selectedTab = .home })
                    .tabItem {
                        Label("Safe Zones", systemImage: "shield.lefthalf.filled")
                    }
                    .tag(Tab.safety)
                
                // Profile Tab
                ProfileView(authViewModel: authViewModel, guardiansViewModel: guardiansViewModel, onBack: { selectedTab = .home })
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.profile)
            }
            .accentColor(.red)
            
            // Sleek Floating Emergency SOS Button (Bottom-Right Floating Action Button)
            SleekFloatingSOSButton(action: {
                showEmergencySheet = true
            })
            .padding(.trailing, 20)
            .padding(.bottom, 68)
        }
        .fullScreenCover(isPresented: $showEmergencySheet) {
            EmergencySOSView(
                locationViewModel: locationViewModel,
                guardiansViewModel: guardiansViewModel
            )
        }
        .fullScreenCover(isPresented: $distressViewModel.isCheckInActive) {
            SilentCheckInModalView(viewModel: distressViewModel)
        }
        .onChange(of: distressViewModel.shouldTriggerSOS) { trigger in
            if trigger {
                showEmergencySheet = true
                distressViewModel.shouldTriggerSOS = false
            }
        }
        .onAppear {
            soundDetector.startListening()
            motionDetector.startMonitoring()
        }
    }
}

// MARK: - Sleek Floating Emergency SOS Button
private struct SleekFloatingSOSButton: View {
    var action: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing Ring
                Circle()
                    .stroke(Color.red.opacity(0.35), lineWidth: 4)
                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.8)
                    .frame(width: 62, height: 62)
                
                // Main SOS Circular Button
                Circle()
                    .fill(AuraTheme.primaryRedGradient)
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.red.opacity(0.45), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 1) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("SOS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - HomeView
private struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var guardiansViewModel: GuardiansViewModel
    @ObservedObject var journeyViewModel: JourneyViewModel
    @ObservedObject var soundDetector: SoundDistressDetector
    @ObservedObject var motionDetector: MotionImpactDetector
    var onTriggerSOS: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome, \(authViewModel.currentUser?.name ?? "Protected Person")")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.red)
                            Text("Safety Dashboard")
                                .font(.title.bold())
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "shield.checkered")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Action SOS Card Banner
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Emergency SOS Alert")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                Text("Broadcast location & notify all guardians instantly")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                        }
                        
                        Button(action: onTriggerSOS) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                Text("Activate Emergency Siren")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(18)
                    .background(AuraTheme.primaryRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.red.opacity(0.25), radius: 8, y: 4)
                    .padding(.horizontal)
                    
                    // ML Audio Distress Shield Card (SoundAnalysis)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "waveform.path.badge.exclamationmark")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text("ML Audio Distress Shield")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(soundDetector.isListening ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                Text(soundDetector.isListening ? "ACTIVE" : "OFF")
                                    .font(.caption2.bold())
                                    .foregroundColor(soundDetector.isListening ? .green : .gray)
                            }
                        }
                        
                        Text("On-device SoundAnalysis continuously monitors for screams, aggressive shouting, or glass breaking.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            soundDetector.simulateDistressDetection(soundType: .scream, confidence: 0.89)
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Simulate Audio Scream Detection")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                    .padding(.horizontal)
                    
                    // CoreMotion Fall & Impact Sensor Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "figure.fall")
                                .font(.title3)
                                .foregroundColor(.red)
                            Text("CoreMotion Impact & Fall Shield")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(motionDetector.isMonitoring ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                Text(motionDetector.isMonitoring ? "ACTIVE" : "OFF")
                                    .font(.caption2.bold())
                                    .foregroundColor(motionDetector.isMonitoring ? .green : .gray)
                            }
                        }
                        
                        Text("Real-time accelerometer & gyroscope telemetry vector math detects hard falls, collision impacts, and struggle gestures.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Button(action: {
                                    motionDetector.simulateMotionAnomaly(type: .hardFall)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "figure.fall")
                                        Text("Simulate Hard Fall")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    motionDetector.simulateMotionAnomaly(type: .highImpact)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bolt.shield.fill")
                                        Text("Simulate High Impact")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    motionDetector.simulateMotionAnomaly(type: .physicalStruggle)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "waveform.path.ecg.page")
                                        Text("Simulate Struggle")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                    .padding(.horizontal)
                    
                    // Live Location Card
                    LocationCard(viewModel: locationViewModel)
                        .padding(.horizontal)
                    
                    // Primary Guardian Status Card
                    if let primary = guardiansViewModel.primaryGuardian() {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Primary Guardian Active")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                Text(primary.name)
                                    .font(.headline)
                                Text(primary.phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Active Journey Status Summary
                    if journeyViewModel.isActive {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ACTIVE JOURNEY")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                Text("Destination: \(journeyViewModel.destinationName)")
                                    .font(.headline)
                                Text("ETA Remaining: \(journeyViewModel.timeRemainingString)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - JourneyView
private struct JourneyView: View {
    @ObservedObject var journeyViewModel: JourneyViewModel
    var onBack: () -> Void
    
    @State private var destination: String = ""
    @State private var durationMinutes: Int = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Navigation Bar with Back Button
            HStack {
                TopLeftBackButton(title: "Home") {
                    onBack()
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            ScrollView {
                VStack(spacing: 20) {
                    if !journeyViewModel.isActive {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Safe Journey")
                                    .font(.title2.bold())
                                Text("Select your destination. AURA ML will calculate the safest route with verified safe zones and monitor route deviations.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Destination")
                                    .font(.headline)
                                TextField("e.g. Home, Office, Metro Station", text: $destination)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onChange(of: destination) { newValue in
                                        if !newValue.isEmpty {
                                            journeyViewModel.prepareRoutes(
                                                userLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                                                destination: newValue
                                            )
                                        }
                                    }
                            }
                            
                            // Safest vs Fastest Route Option Selector
                            if !journeyViewModel.availableRoutes.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("ML Route Recommendation")
                                        .font(.headline)
                                    
                                    ForEach(journeyViewModel.availableRoutes) { route in
                                        Button(action: {
                                            withAnimation {
                                                journeyViewModel.selectedRoute = route
                                                journeyViewModel.estimatedMinutes = route.estimatedMinutes
                                            }
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(route.name)
                                                            .font(.subheadline.bold())
                                                            .foregroundColor(.primary)
                                                        if route.isSafestRoute {
                                                            Text("SAFEST")
                                                                .font(.caption2.bold())
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.green.opacity(0.2))
                                                                .foregroundColor(.green)
                                                                .clipShape(Capsule())
                                                        }
                                                    }
                                                    Text("\(route.distanceKm, specifier: "%.1f") km • \(route.mlPredictedETA)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    ForEach(route.highlights, id: \.self) { highlight in
                                                        Text(highlight)
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                
                                                VStack {
                                                    Text("Risk Score")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                    Text("\(route.riskScore, specifier: "%.1f")")
                                                        .font(.headline.bold())
                                                        .foregroundColor(route.isSafestRoute ? .green : .orange)
                                                }
                                            }
                                            .padding(14)
                                            .background(Color(.systemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(journeyViewModel.selectedRoute?.id == route.id ? (route.isSafestRoute ? Color.green : Color.orange) : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Estimated Duration: \(durationMinutes) min")
                                    .font(.headline)
                                Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 5...180, step: 5)
                            }
                            
                            Button(action: {
                                guard !destination.isEmpty else { return }
                                journeyViewModel.startJourney(destination: destination, durationMinutes: durationMinutes)
                            }) {
                                Text("Start Safe Journey Tracking")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(destination.isEmpty ? Color.gray : Color.green)
                                    .clipShape(Capsule())
                            }
                            .disabled(destination.isEmpty)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                    } else {
                        // Active Journey Screen
                        VStack(spacing: 20) {
                            Image(systemName: "figure.walk.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(.green)
                            
                            Text("Safe Journey in Progress")
                                .font(.title.bold())
                            
                            VStack(spacing: 6) {
                                Text("Destination: \(journeyViewModel.destinationName)")
                                    .font(.headline)
                                Text("Time Remaining: \(journeyViewModel.timeRemainingString)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            
                            // Route Anomaly Alert Banner
                            if let anomaly = journeyViewModel.anomalyDetector.activeAnomaly {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(anomaly.type.rawValue)
                                            .font(.headline.bold())
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    Text(anomaly.details)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Button(action: {
                                        journeyViewModel.anomalyDetector.clearAnomaly()
                                    }) {
                                        Text("I'm OK (Dismiss Alert)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(16)
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                )
                            } else {
                                Button(action: {
                                    journeyViewModel.anomalyDetector.simulateRouteDeviation()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.branch")
                                        Text("Simulate Route Deviation Alert")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    journeyViewModel.confirmArrival()
                                }) {
                                    Text("I Arrived Safely 🎉")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    journeyViewModel.cancelJourney()
                                }) {
                                    Text("Cancel Journey")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 90)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - GuardiansView
private struct GuardiansView: View {
    @ObservedObject var guardiansViewModel: GuardiansViewModel
    var onBack: () -> Void
    
    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newRelation = "Friend"
    @State private var isPrimary = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Navigation Bar with Back Button
            HStack {
                TopLeftBackButton(title: "Home") {
                    onBack()
                }
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Text("Trusted Guardians")
                .font(.title2.bold())
                .padding(.horizontal)
            
            List {
                Section(header: Text("Guardians Network (\(guardiansViewModel.guardians.count))")) {
                    ForEach(guardiansViewModel.guardians) { guardian in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(guardian.name)
                                        .font(.headline)
                                    if guardian.isPrimary {
                                        Text("PRIMARY")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("\(guardian.relationship) • \(guardian.phone)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Button(action: {
                                guardiansViewModel.togglePrimary(guardian: guardian)
                            }) {
                                Image(systemName: guardian.isPrimary ? "star.fill" : "star")
                                    .foregroundColor(guardian.isPrimary ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: guardiansViewModel.deleteGuardian)
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Contact Details")) {
                        TextField("Full Name", text: $newName)
                        TextField("Phone Number", text: $newPhone)
                            .keyboardType(.phonePad)
                        TextField("Relationship (e.g. Mom, Sister)", text: $newRelation)
                        Toggle("Set as Primary Guardian", isOn: $isPrimary)
                    }
                }
                .navigationTitle("Add Guardian")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard !newName.isEmpty, !newPhone.isEmpty else { return }
                            guardiansViewModel.addGuardian(name: newName, phone: newPhone, relationship: newRelation, isPrimary: isPrimary)
                            newName = ""
                            newPhone = ""
                            showAddSheet = false
                        }
                        .disabled(newName.isEmpty || newPhone.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - SafetyView
private struct SafetyView: View {
    @ObservedObject var safeZoneViewModel: SafeZoneViewModel
    @ObservedObject var locationViewModel: LocationViewModel
    var onBack: () -> Void

    var body: some View {
        SafeZoneListView(viewModel: safeZoneViewModel, locationViewModel: locationViewModel, showBackButton: true)
    }
}

// MARK: - ProfileView
private struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var guardiansViewModel: GuardiansViewModel
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Navigation Bar with Back Button
            HStack {
                TopLeftBackButton(title: "Home") {
                    onBack()
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Text("Profile & Settings")
                .font(.title2.bold())
                .padding(.horizontal)
            
            List {
                Section(header: Text("User Profile")) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "User Profile")
                                .font(.headline)
                            Text("Role: Protected Person")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Switch Account Role")) {
                    Button(action: {
                        authViewModel.switchRole(to: .guardian)
                    }) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Switch to Guardian Interface")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Account Actions")) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - LocationCard
private struct LocationCard: View {
    @ObservedObject var viewModel: LocationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Live Location Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if viewModel.isUpdating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let location = viewModel.currentLocation {
                if let address = viewModel.currentAddress {
                    Text(address)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
                HStack(spacing: 12) {
                    Text("Lat: \(location.coordinate.latitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Long: \(location.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.isUpdating {
                Text("Fetching live GPS coordinates...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else {
                Text("Location unavailable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }
}
