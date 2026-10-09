# 🛡 AURA Safety — Proactive ML-Powered Personal Safety Platform for iOS

**AURA Safety** is a next-generation, proactive, on-device ML safety iOS application built with **SwiftUI**, **Core ML**, **SoundAnalysis**, **CoreMotion**, **CoreLocation**, and **MapKit**. 

Unlike traditional reactive safety apps, AURA Safety uses continuous sensor telemetry and on-device machine learning to detect distress sounds, high-G impacts, falls, and route deviations *before* an emergency escalates — automatically initiating silent check-ins and emergency siren protocols.

---

## ✨ Key Features

### 1. 🎙 On-Device ML Audio Distress Shield (`SoundAnalysis`)
* **Continuous Audio Monitoring**: Uses Apple's `SoundAnalysis` framework (`SNClassifySoundRequest` / `SNResultsObserving`) to detect screams, aggressive shouting, and glass breaking locally on-device.
* **10-Second Silent Check-in**: Displays a glassmorphic countdown modal ("ARE YOU OK?") with haptic feedback.
* **Auto-Escalation**: If unanswered within 10 seconds, automatically triggers an Emergency SOS alert and broadcasts live location to guardians.

### 2. 🧭 Route-Deviation Anomaly Engine & Safest Route Planner
* **Safest Route Scoring**: Calculates safety indices by evaluating lighting quality, crowd density, crime statistics, and distance.
* **Corridor Deviation Detection**: Alerts if the user strays $> 150\text{m}$ off their intended route corridor.
* **Unusual Stop Detector**: Identifies stationary delays ($> 4\text{ mins}$) outside designated safe zones.

### 3. 📉 CoreMotion Fall, Impact & Struggle Classifier (`CoreMotion`)
* **Real-Time Telemetry Math**: Analyzes 50 Hz 3-axis accelerometer and gyroscope vectors:
  $$G = \sqrt{a_x^2 + a_y^2 + a_z^2}$$
* **Hard Fall Detection**: Identifies a freefall phase ($G < 0.35g$) followed by violent impact ($G > 3.2g$).
* **High Impact / Crash**: Detects sudden high deceleration spikes ($G > 4.5g$).
* **Physical Struggle Pattern**: Recognizes violent rotational oscillation ($> 6.5\text{ rad/s}$) over rolling sample windows.

### 4. 👥 Dual-Role Design Architecture
* **Protected Person Dashboard**:
  * Quick-access SOS emergency siren button.
  * Live GPS tracking with MapKit integration.
  * Safe Journey timer with ETA updates and "I Arrived Safely" check-ins.
  * Guardian Manager & Verified Safe Zones list.
* **Guardian Monitoring Hub**:
  * Status monitoring (`NORMAL` vs `SOS ACTIVE`).
  * Live address feed & active trip progress.
  * One-tap calling & Apple Maps turn-by-turn directions to the protected person's location.

---

## 🛠 Tech Stack & Architecture

* **UI Framework**: SwiftUI (iOS 16+) with custom glassmorphism design system (`AuraTheme`) & Crimson/Indigo gradients.
* **Architecture**: Clean MVVM (Model-View-ViewModel) with reactive `Combine` pipelines.
* **Machine Learning & Signal Processing**: `SoundAnalysis`, `Core ML`, `CoreMotion`.
* **Location & Mapping**: `CoreLocation`, `MapKit` with custom map overlays.
* **Hardware Telemetry**: `CMMotionManager` (`CMDeviceMotion` / `CMAccelerometerData`).


---

## 🚀 Getting Started

### Requirements
* macOS 13.0 or later
* Xcode 14.3 / 15.0 / 16.0+
* iOS 16.0+ Deployment Target

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/womensafety.git
   cd womensafety
