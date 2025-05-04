import Foundation
import Speech
import AVFoundation
import SwiftUI
import Translation             // ➊ Apple’s Translation framework :contentReference[oaicite:6]{index=6}

final class SpeechTranslationViewModel: ObservableObject {
    // MARK: - Speech Recognition
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizerEN: SFSpeechRecognizer?
    private var speechRecognizerZH: SFSpeechRecognizer?

    @Published var recognizedText: String = ""
    @Published var translatedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    init() {
        // Configure speech recognizers
        speechRecognizerEN = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizerZH = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        requestSpeechPermissions()
    }

    private func requestSpeechPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self.errorMessage = String(localized: "Speech recognition not authorized.")  // ➋ Localizable string :contentReference[oaicite:7]{index=7}
                }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // MARK: - Recording
    func startRecording(sourceLanguage: String) {
        isRecording = true
        recognizedText = ""
        translatedText = ""
        errorMessage = nil

        guard let recognizer = (sourceLanguage == "English") ? speechRecognizerEN : speechRecognizerZH,
              recognizer.isAvailable else {
            errorMessage = String(localized: "\(sourceLanguage) recognizer not available.")
            isRecording = false
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = false
        request.taskHint = .dictation
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = String(localized: "Audio session config failed: \(error.localizedDescription)")
            isRecording = false
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = String(localized: "Audio engine start failed: \(error.localizedDescription)")
            isRecording = false
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Recognition error:", error)
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let result = result else { return }
            
            DispatchQueue.main.async {
                self.recognizedText = result.bestTranscription.formattedString
                
                if result.isFinal {
                    print("📝 Final recognition result: \(self.recognizedText)")
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        // Ensure clean stop of audio engine
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        // End recognition task gracefully
        recognitionTask?.finish()
        recognitionTask = nil
        
        // Update state
        isRecording = false
        
        print("🎙 Recording stopped with text: \(recognizedText)")
    }

    func checkAndRequestPermission() async -> Bool {
        let status = await SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
