import Foundation
import AVFoundation
import SoundAnalysis
import Combine

class SoundDistressDetector: ObservableObject {
    @Published var isListening: Bool = false
    @Published var lastDetectedEvent: DistressEvent? = nil
    @Published var audioLevel: Float = 0.0
    
    private var audioEngine: AVAudioEngine?
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.aura.soundanalysis", qos: .userInitiated)
    private var resultsObserver: DistressSoundObserver?
    
    init() {
        self.resultsObserver = DistressSoundObserver { [weak self] event in
            DispatchQueue.main.async {
                self?.lastDetectedEvent = event
            }
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        #if targetEnvironment(simulator)
        // Simulator fallback mode
        DispatchQueue.main.async {
            self.isListening = true
        }
        print("[SoundDistressDetector] Running in Simulator mode (Mock SoundAnalysis active).")
        #else
        setupAudioEngine()
        #endif
    }
    
    func stopListening() {
        #if !targetEnvironment(simulator)
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        #endif
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    // Simulator trigger for testing
    func simulateDistressDetection(soundType: DistressSoundType = .scream, confidence: Double = 0.88) {
        let event = DistressEvent(soundType: soundType, confidence: confidence)
        DispatchQueue.main.async {
            self.lastDetectedEvent = event
        }
    }
    
    private func setupAudioEngine() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[SoundDistressDetector] AVAudioSession error: \(error.localizedDescription)")
            return
        }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        streamAnalyzer = SNAudioStreamAnalyzer(format: format)
        
        if let observer = resultsObserver, let request = try? SNClassifySoundRequest(classifierIdentifier: .version1) {
            try? streamAnalyzer?.add(request, withObserver: observer)
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            self.analysisQueue.async {
                self.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        do {
            try engine.start()
            audioEngine = engine
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            print("[SoundDistressDetector] Engine start failed: \(error.localizedDescription)")
        }
    }
}

// Dedicated observer conforming to SNResultsObserving protocol
class DistressSoundObserver: NSObject, SNResultsObserving {
    private let onDetected: (DistressEvent) -> Void
    
    init(onDetected: @escaping (DistressEvent) -> Void) {
        self.onDetected = onDetected
        super.init()
    }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        
        if let topClassification = classificationResult.classifications.first {
            let identifier = topClassification.identifier.lowercased()
            let confidence = topClassification.confidence
            
            var detectedType: DistressSoundType? = nil
            if identifier.contains("screaming") || identifier.contains("shout") || identifier.contains("yell") {
                detectedType = .scream
            } else if identifier.contains("glass") || identifier.contains("shatter") {
                detectedType = .glassBreak
            }
            
            if let type = detectedType, confidence >= 0.70 {
                let event = DistressEvent(soundType: type, confidence: confidence)
                onDetected(event)
            }
        }
    }
}
