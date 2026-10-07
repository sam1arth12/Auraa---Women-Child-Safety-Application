import SwiftUI
import CoreLocation

struct EmergencySOSView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationViewModel: LocationViewModel
    @ObservedObject var guardiansViewModel: GuardiansViewModel
    
    @State private var countdown = 3
    @State private var sosTriggered = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color(sosTriggered ? .systemRed : .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar with Back Button
                HStack {
                    TopLeftBackButton(title: "Cancel & Exit") {
                        cancelSOS()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                if !sosTriggered {
                    // Countdown Screen
                    VStack(spacing: 28) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 130, height: 130)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 8) {
                            Text("EMERGENCY SOS")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Alerting primary guardians & emergency services in:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // Circular Countdown Unit
                        ZStack {
                            Circle()
                                .stroke(Color.red.opacity(0.18), lineWidth: 14)
                                .frame(width: 170, height: 170)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(countdown) / 3.0)
                                .stroke(
                                    LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                )
                                .frame(width: 170, height: 170)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.9), value: countdown)
                            
                            Text("\(countdown)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 14) {
                            Button(action: {
                                triggerSOSNow()
                            }) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                    Text("TRIGGER IMMEDIATELY")
                                        .font(.headline.weight(.heavy))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .shadow(color: Color.red.opacity(0.4), radius: 10, y: 4)
                            }
                            .padding(.horizontal, 32)
                            
                            Button(action: {
                                cancelSOS()
                            }) {
                                Text("CANCEL SOS")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 10)
                            }
                        }
                        
                        Spacer()
                    }
                    .onAppear {
                        startTimer()
                    }
                } else {
                    // Active SOS Alert Screen
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            Image(systemName: "bell.badge.circle.fill")
                                .font(.system(size: 84))
                                .foregroundColor(.white)
                        }
                        
                        Text("SOS SIREN ACTIVE")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("Broadcasting Live GPS Coordinates:")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.9))
                            
                            if let address = locationViewModel.currentAddress {
                                Text(address)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else if let loc = locationViewModel.currentLocation {
                                Text("Lat: \(loc.coordinate.latitude, specifier: "%.4f"), Long: \(loc.coordinate.longitude, specifier: "%.4f")")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 14) {
                            // Call Emergency Services Button
                            Button(action: {
                                callNumber(phone: "112")
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Emergency Helpline (112)")
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(radius: 6)
                            }
                            
                            // Call Primary Guardian
                            if let primary = guardiansViewModel.primaryGuardian() {
                                Button(action: {
                                    callNumber(phone: primary.phone)
                                }) {
                                    HStack {
                                        Image(systemName: "person.fill.checkmark")
                                        Text("Call \(primary.name) (\(primary.phone))")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            
                            // Send SMS Alert
                            Button(action: {
                                sendSMSAlert()
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("SMS Live Location to Guardians")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("I am safe now (Deactivate SOS)")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                triggerSOSNow()
            }
        }
    }
    
    private func triggerSOSNow() {
        timer?.invalidate()
        withAnimation {
            sosTriggered = true
        }
    }
    
    private func cancelSOS() {
        timer?.invalidate()
        dismiss()
    }
    
    private func callNumber(phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanPhone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendSMSAlert() {
        var bodyText = "EMERGENCY SOS ALERT! I need urgent assistance."
        if let address = locationViewModel.currentAddress {
            bodyText += " My location: \(address)."
        } else if let loc = locationViewModel.currentLocation {
            bodyText += " Coordinates: \(loc.coordinate.latitude), \(loc.coordinate.longitude)."
        }
        
        let primaryPhone = guardiansViewModel.primaryGuardian()?.phone ?? ""
        let cleanPhone = primaryPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let smsString = "sms:\(cleanPhone)&body=\(bodyText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: smsString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
