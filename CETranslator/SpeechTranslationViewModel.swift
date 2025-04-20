import Foundation
import Speech
import AVFoundation
import SwiftUI
import LLM   // Ensure this is added via Swift Package Manager (eastriverlee/LLM.swift)

final class SpeechTranslationViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published var recognizedText: String = ""
    @Published var translatedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    // MARK: - Speech Recognition
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizerEN: SFSpeechRecognizer?
    private var speechRecognizerZH: SFSpeechRecognizer?

    // MARK: - Translation Model
    private var translatorModel: LLM?

    // MARK: - Text-to-Speech
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Audio Monitoring
    private var hasDetectedSound = false
    private var silenceTimer: Timer?
    private var recognitionTimeout: Timer?
    private var autoStopTimer: Timer?          // New timer to auto-stop after speech
    private let silenceThreshold: Float = -70.0 
    private let autoStopInterval: TimeInterval = 2.0 // seconds after first speech

    init() {
        speechRecognizerEN = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizerZH = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        printPermissions()
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    self.errorMessage = "Speech recognition not authorized."
                }
            }
        }
        loadMiniCPMModel()
    }

    private func printPermissions() {
        let micPerm = AVAudioSession.sharedInstance().recordPermission
        print("Mic permission: \(micPerm)")
        let speechAuth = SFSpeechRecognizer.authorizationStatus()
        print("Speech auth: \(speechAuth)")
    }

    private func loadMiniCPMModel() {
        guard let url = Bundle.main.url(forResource: "minimcp_model_q4", withExtension: "gguf") else {
            self.errorMessage = "Model file not found in bundle."
            print("❌ minimcp_model_q4.gguf missing")
            return
        }
        do {
            translatorModel = try LLM(from: url)
            print("✅ Translator model loaded.")
        } catch {
            self.errorMessage = "Failed to load model: \(error.localizedDescription)"
            print("❌ Model load error: \(error)")
        }
    }

    // MARK: - Recording
    func startRecording(sourceLanguage: String) {
        print("🏁 startRecording hit for \(sourceLanguage)")
        isRecording = true
        recognizedText = ""
        translatedText = ""
        errorMessage = nil
        cancelAutoStop()

        guard let recognizer = (sourceLanguage == "English") ? speechRecognizerEN : speechRecognizerZH,
              recognizer.isAvailable else {
            errorMessage = "\(sourceLanguage) recognizer not available."
            isRecording = false
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = false
        recognizer.defaultTaskHint = .dictation

        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            errorMessage = "Mic access denied."
            isRecording = false
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio,
                                     options: [.allowBluetoothA2DP, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session config failed: \(error.localizedDescription)"
            print("❌ Session error: \(error)")
            isRecording = false
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let level = self.calculateAudioLevel(buffer)
            if level > -15 || level > self.silenceThreshold {
                self.hasDetectedSound = true
                self.scheduleAutoStop()   // start/refresh auto-stop
                if level > -15 { print("🔊 Strong: \(level) dB") }
                else if level > -30 { print("🔉 Medium: \(level) dB") }
                else { print("🔈 Weak: \(level) dB") }
            } else {
                print("🤫 Silence: \(level) dB")
            }
            request.append(buffer)
        }

        logAndEnforceBuiltInMic(session)

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("✅ Audio engine started.")
        } catch {
            errorMessage = "Audio engine start failed: \(error.localizedDescription)"
            print("❌ Engine start error: \(error)")
            isRecording = false
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let error = error as NSError?, error.code == 1110 {
                print("⚠️ No speech detected (ignored)")
                return
            } else if let error = error {
                print("❌ Recognition error: \(error)")
                return
            }
            guard let result = result else { return }
            DispatchQueue.main.async { self.recognizedText = result.bestTranscription.formattedString }
            if result.isFinal {
                self.translate(sourceLanguage: sourceLanguage, text: result.bestTranscription.formattedString)
                self.stopRecording()
            }
        }

        startSilenceMonitor()
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        cancelSilenceMonitor()
        cancelAutoStop()
        isRecording = false
        print("Recording stopped.")
    }

    // MARK: - Auto-stop Logic
    private func scheduleAutoStop() {
        autoStopTimer?.invalidate()
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: autoStopInterval, repeats: false) { _ in
            self.stopRecording()
        }
    }

    private func cancelAutoStop() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
    }

    // MARK: - Silence Monitor
    private func startSilenceMonitor() {
        hasDetectedSound = false
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.hasDetectedSound { print("⚠️ No audio in last 0.5s") }
            self.hasDetectedSound = false
        }
    }

    private func cancelSilenceMonitor() {
        silenceTimer?.invalidate()
        recognitionTimeout?.invalidate()
        silenceTimer = nil
    }

    // MARK: - Audio Routing
    private func logAndEnforceBuiltInMic(_ session: AVAudioSession) {
        let inputs = session.currentRoute.inputs.map { $0.portType }
        print("🛣️ Audio Route Inputs: \(inputs)")
        if !inputs.contains(.builtInMic) {
            do {
                try session.overrideOutputAudioPort(.none)
                print("🔄 Forced to built-in mic: \(session.currentRoute.inputs.map { $0.portType })")
            } catch {
                print("❌ Failed to override audio port: \(error)")
            }
        }
    }

    // MARK: - Translation Helpers
    private func translate(sourceLanguage: String, text: String) {
        if sourceLanguage == "English" { translateEnglishToChinese(text) }
        else { translateChineseToEnglish(text) }
    }

    private func translateEnglishToChinese(_ text: String) {
        let prompt = """
Translate the following English text to simplified Chinese:
English: \(text)
Chinese:
"""
        generateTranslation(prompt: prompt, langCode: "zh-CN")
    }

    private func translateChineseToEnglish(_ text: String) {
        let prompt = """
Translate the following simplified Chinese text to English:
Chinese: \(text)
English:
"""
        generateTranslation(prompt: prompt, langCode: "en-US")
    }

    private func generateTranslation(prompt: String, langCode: String) {
        guard let model = translatorModel else { return }
        DispatchQueue.main.async { self.translatedText = "Translating..."; self.errorMessage = nil }
        Task.detached {
            do {
                let output = try await model.getCompletion(from: prompt)
                let clean = output.trimmingCharacters(in: .whitespacesAndNewlines)
                DispatchQueue.main.async {
                    self.translatedText = clean
                    if !clean.isEmpty { self.speak(text: clean, langCode: langCode) }
                    else { self.errorMessage = "Empty translation" }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Translation error: \(error.localizedDescription)"
                }
                print("❌ Translation error: \(error)")
            }
        }
    }

    // MARK: - TTS
    private func speak(text: String, langCode: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: langCode) ?? utt.voice
        utt.rate = AVSpeechUtteranceDefaultSpeechRate
        utt.volume = 1.0
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ TTS session error: \(error)")
            self.errorMessage = "TTS setup failed"
            return
        }
        synthesizer.speak(utt)
    }

    // MARK: - Audio Level Calculation
    private func calculateAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return -160.0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(count))
        return 20 * log10(rms)
    }
}
