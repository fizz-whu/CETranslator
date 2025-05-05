import Foundation
import Speech
import AVFoundation
import SwiftUI
import Translation

final class SpeechTranslationViewModel: ObservableObject {
    // MARK: - Speech Recognition
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    // Add recognizers for supported languages
    private var speechRecognizerEN: SFSpeechRecognizer?
    private var speechRecognizerZH: SFSpeechRecognizer?
    private var speechRecognizerJA: SFSpeechRecognizer?
    private var speechRecognizerES: SFSpeechRecognizer?
    private var speechRecognizerIT: SFSpeechRecognizer? // Added IT recognizer
    private var speechRecognizerKO: SFSpeechRecognizer? // Added KO recognizer
    private var speechRecognizerFR: SFSpeechRecognizer? // Added FR recognizer
    private var speechRecognizerPT: SFSpeechRecognizer? // Added PT recognizer

    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    init() {
        // Configure speech recognizers
        speechRecognizerEN = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizerZH = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
        speechRecognizerJA = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        speechRecognizerES = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
        speechRecognizerIT = SFSpeechRecognizer(locale: Locale(identifier: "it-IT"))   // Initialize IT recognizer
        speechRecognizerKO = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))   // Initialize KO recognizer
        speechRecognizerFR = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))   // Initialize FR recognizer
        speechRecognizerPT = SFSpeechRecognizer(locale: Locale(identifier: "pt-PT"))   // Initialize PT recognizer
        requestSpeechPermissions()
    }

    private func requestSpeechPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self.errorMessage = String(localized: "Speech recognition not authorized.")
                }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }


    // MARK: - Recording
    func startRecording(sourceLanguage: String) {
        isRecording = true
        recognizedText = ""
        errorMessage = nil

        // Select the correct recognizer based on sourceLanguage
        let recognizer: SFSpeechRecognizer?
        switch sourceLanguage {
        case "en-US":
            recognizer = speechRecognizerEN
        case "zh-Hans":
            recognizer = speechRecognizerZH
        case "ja-JP":
            recognizer = speechRecognizerJA
        case "es-ES":
            recognizer = speechRecognizerES
        case "it-IT": // Add case for Italian
            recognizer = speechRecognizerIT
        case "ko-KR": // Add case for Korean
            recognizer = speechRecognizerKO
        case "fr-FR": // Add case for French
            recognizer = speechRecognizerFR
        case "pt-PT": // Add case for Portuguese
            recognizer = speechRecognizerPT
        default:
            print("🔴 Unsupported language code: \(sourceLanguage)")
            recognizer = nil
        }


        guard let selectedRecognizer = recognizer, selectedRecognizer.isAvailable else {
            // Update error message to reflect the actual language code used
            errorMessage = String(localized: "\(sourceLanguage) recognizer not available.")
            isRecording = false
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        // Consider setting requiresOnDeviceRecognition based on availability if needed
        // request.requiresOnDeviceRecognition = selectedRecognizer.supportsOnDeviceRecognition
        request.requiresOnDeviceRecognition = false // Keep as false for now
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
        // Ensure inputNode is available
        guard inputNode.inputFormat(forBus: 0).channelCount > 0 else {
             errorMessage = String(localized: "Audio input node not available or has no channels.")
             isRecording = false
             // Attempt to reset audio engine if needed, or guide user
             // audioEngine.stop() // Ensure stopped if partially started
             return
         }
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0) // Ensure no previous tap exists
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("🎙️ Audio engine started for \(sourceLanguage)")
        } catch {
            errorMessage = String(localized: "Audio engine start failed: \(error.localizedDescription)")
            isRecording = false
            // Clean up tap on failure
            audioEngine.inputNode.removeTap(onBus: 0)
            return
        }

        // Use the selected recognizer
        recognitionTask = selectedRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                 // Check for specific errors like "recognizer unavailable" which might occur mid-task
                 print("🔴 Recognition error for \(sourceLanguage):", error)
                 DispatchQueue.main.async {
                     // Provide more context in the error message
                     self.errorMessage = "Recognition error (\(sourceLanguage)): \(error.localizedDescription)"
                     // Consider stopping recording on certain errors
                     // self.stopRecording()
                 }
                 // Don't necessarily return immediately, maybe the task can recover?
                 // Check error code if needed: (error as NSError).code
                 // If error code indicates session ended, then stop.
                 return // Keep return for now
             }

             guard let result = result else { return }

             DispatchQueue.main.async {
                 let newText = result.bestTranscription.formattedString
                 // Only update if text changed to avoid unnecessary UI refreshes
                 if self.recognizedText != newText {
                     self.recognizedText = newText
                     print("👂 Recognized (\(sourceLanguage)): \(self.recognizedText)")
                 }

                 if result.isFinal {
                     print("✅ Final recognition result (\(sourceLanguage)): \(self.recognizedText)")
                     // Don't stop recording automatically here, let the View handle it on button release
                     // self.stopRecording()
                 }
             }
        }
    }

    func stopRecording() {
        // Check if audio engine is running before stopping
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0) // Remove tap after stopping
            print("🛑 Audio engine stopped.")
        } else {
             print("⚠️ Audio engine was not running.")
         }

        // Check if task exists before finishing
        if recognitionTask != nil {
            recognitionTask?.finish() // Finish task first
            recognitionTask = nil     // Then set to nil
            print("🏁 Recognition task finished.")
        } else {
             print("⚠️ Recognition task was already nil.")
         }

        // Deactivate audio session (optional, depends on app lifecycle)
        // do {
        //     try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        // } catch {
        //     print("🔴 Failed to deactivate audio session: \(error.localizedDescription)")
        // }


        // Update state only if it was recording
        if isRecording {
            DispatchQueue.main.async { // Ensure UI updates on main thread
                self.isRecording = false
                print("🎙 Recording stopped state updated. Final text: \(self.recognizedText)")
            }
        }
    }

    func checkAndRequestPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()

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
            // Optionally set an error message here to guide the user
            DispatchQueue.main.async {
                 self.errorMessage = String(localized: "Speech recognition permission denied or restricted. Please check Settings.")
             }
            return false
        @unknown default:
            return false
        }
    }

}
