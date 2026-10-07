import SwiftUI

struct SilentCheckInModalView: View {
    @ObservedObject var viewModel: DistressDetectionViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Detected Anomaly Badge
                if let event = viewModel.currentDistressEvent {
                    HStack(spacing: 8) {
                        Image(systemName: event.soundType.iconName)
                            .font(.title3)
                            .foregroundColor(.orange)
                        Text("\(event.soundType.rawValue) Detected (\(Int(event.confidence * 100))% confidence)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
                } else if let motionEvent = viewModel.currentMotionImpactEvent {
                    HStack(spacing: 8) {
                        Image(systemName: motionEvent.type.iconName)
                            .font(.title3)
                            .foregroundColor(.red)
                        Text("\(motionEvent.type.rawValue): \(motionEvent.detail)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.25))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.red.opacity(0.6), lineWidth: 1)
                    )
                }
                
                VStack(spacing: 8) {
                    Text("ARE YOU OK?")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Safety anomaly detected (\(viewModel.distressReason)). If you do not respond in \(viewModel.remainingCheckInSeconds) seconds, emergency SOS will be triggered automatically.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                // Animated Ring Timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 14)
                        .frame(width: 170, height: 170)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.remainingCheckInSeconds) / 10.0)
                        .stroke(
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: viewModel.remainingCheckInSeconds)
                    
                    Text("\(viewModel.remainingCheckInSeconds)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 14) {
                    // Safe Confirmation Button
                    Button(action: {
                        viewModel.userConfirmedSafe()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("I AM SAFE (CANCEL)")
                                .font(.headline.weight(.heavy))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(radius: 8)
                    }
                    .padding(.horizontal, 32)
                    
                    // Immediate Escalation Override Button
                    Button(action: {
                        viewModel.escalateToSOS()
                    }) {
                        Text("Trigger Emergency SOS Now")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .padding(.vertical, 10)
                    }
                }
                
                Spacer()
            }
        }
    }
}
