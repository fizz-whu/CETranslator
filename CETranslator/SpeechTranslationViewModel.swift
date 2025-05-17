import Foundation
import Speech
import AVFoundation
import SwiftUI
import Translation

final class SpeechTranslationViewModel: ObservableObject {
    // MARK: - Speech Recognition
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
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
                    self.errorMessage = NSLocalizedString("speech_recognition_not_authorized", 
                        comment: "Please enable microphone access in Settings to use voice recognition")
                }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    private func getLocalizedErrorMessage(for errorType: String, language: String) -> String {
        switch errorType {
        case "no_speech_detected":
            switch language {
            case "zh-Hans":
                return "让我们再试一次！请按住麦克风并靠近设备说话 🎤"
            case "ja-JP":
                return "もう一度試してみましょう！マイクを長押しして、デバイスに近づいて話してください 🎤"
            case "es-ES":
                return "¡Intentémoslo de nuevo! Por favor, mantén presionado el micrófono y habla más cerca del dispositivo 🎤"
            case "it-IT":
                return "Riproviamo! Tieni premuto il microfono e parla più vicino al dispositivo 🎤"
            case "ko-KR":
                return "다시 시도해 보겠습니다! 마이크를 길게 누르고 기기에 더 가까이 대고 말씀해 주세요 🎤"
            case "fr-FR":
                return "Essayons à nouveau ! Maintenez le micro appuyé et parlez plus près de l'appareil 🎤"
            case "pt-PT":
                return "Vamos tentar novamente! Mantenha pressionado o microfone e fale mais perto do dispositivo 🎤"
            default:
                return "Let's try that again! Please press and hold the microphone and speak a little closer to your device 🎤"
            }
        case "recognition_error":
            switch language {
            case "zh-Hans":
                return "抱歉，我没有听清楚。请按住麦克风，说慢一点，说得更清晰一些 🎤"
            case "ja-JP":
                return "申し訳ありません、聞き取れませんでした。マイクを長押しして、もう少しゆっくり、はっきりと話してください 🎤"
            case "es-ES":
                return "Lo siento, no pude entender bien. Por favor, mantén presionado el micrófono y habla más despacio y claro 🎤"
            case "it-IT":
                return "Mi dispiace, non ho capito bene. Per favore, tieni premuto il microfono e parla più lentamente e chiaramente 🎤"
            case "ko-KR":
                return "죄송합니다. 잘 알아듣지 못했어요. 마이크를 길게 누르고, 좀 더 천천히, 명확하게 말씀해 주시겠어요? 🎤"
            case "fr-FR":
                return "Désolé, je n'ai pas bien compris. Pourriez-vous maintenir le micro appuyé et parler plus lentement et plus clairement ? 🎤"
            case "pt-PT":
                return "Desculpe, não entendi bem. Por favor, mantenha pressionado o microfone e fale mais devagar e claramente 🎤"
            default:
                return "Sorry, I didn't catch that. Could you please press and hold the microphone and speak more slowly and clearly? 🎤"
            }
        default:
            return "An error occurred"
        }
    }

    func startRecording(sourceLanguage: String) {
        isRecording = true
        recognizedText = ""
        errorMessage = nil // Clear previous errors at the start

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
            self.errorMessage = String(format: NSLocalizedString("recognizer_not_available_for_language", 
                comment: "Voice recognition is not available for %@. Please check your internet connection or try another language"), sourceLanguage)
            isRecording = false
            return
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = self.recognitionRequest else {
            self.errorMessage = NSLocalizedString("failed_to_create_recognition_request", 
                comment: "Unable to start voice recognition. Please try again")
            isRecording = false
            return
        }
        // Consider setting requiresOnDeviceRecognition based on availability if needed
        // request.requiresOnDeviceRecognition = selectedRecognizer.supportsOnDeviceRecognition
        request.requiresOnDeviceRecognition = false // Keep as false for now
        request.taskHint = .dictation

        // Add this line to request punctuation
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = String(format: NSLocalizedString("audio_session_config_failed_details", 
                comment: "Unable to access the microphone. Please check your device settings"), error.localizedDescription)
            isRecording = false
            return
        }

        let inputNode = audioEngine.inputNode
        guard inputNode.inputFormat(forBus: 0).channelCount > 0 else {
             self.errorMessage = NSLocalizedString("audio_input_node_unavailable", 
                 comment: "Microphone not found. Please make sure your microphone is connected and working")
             isRecording = false
             return
         }
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("🎙️ Audio engine started for \(sourceLanguage)")
        } catch {
            self.errorMessage = String(format: NSLocalizedString("audio_engine_start_failed_details", 
                comment: "Unable to start recording. Please check your microphone connection"), error.localizedDescription)
            isRecording = false
            audioEngine.inputNode.removeTap(onBus: 0)
            return
        }

        // Then update the error handling code in recognitionTask:
        recognitionTask = selectedRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
    
            if let error = error {
                let nsError = error as NSError
                print("🔴 Recognition error for \(sourceLanguage): \(error.localizedDescription), Code: \(nsError.code), Domain: \(nsError.domain)")
                DispatchQueue.main.async {
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                        self.errorMessage = self.getLocalizedErrorMessage(for: "no_speech_detected", language: sourceLanguage)
                    } else {
                        self.errorMessage = self.getLocalizedErrorMessage(for: "recognition_error", language: sourceLanguage)
                    }
                }
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest?.endAudio()
                self.isRecording = false
                self.recognitionTask = nil
                self.recognitionRequest = nil
                return
            }
    
            guard let result = result else { return }
    
            DispatchQueue.main.async {
                let newText = result.bestTranscription.formattedString
                if self.recognizedText != newText {
                    self.recognizedText = newText
                    print("👂 Recognized (\(sourceLanguage)): \(self.recognizedText)")
                }
                self.errorMessage = nil // Clear error on successful partial or final result
    
                if result.isFinal {
                    print("✅ Final recognition result (\(sourceLanguage)): \(self.recognizedText)")
                }
            }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            print("🛑 Audio engine stopped.")
        } else {
            print("⚠️ Audio engine was not running.")
        }

        if recognitionTask != nil {
            recognitionTask?.finish()
            recognitionTask = nil
            print("🏁 Recognition task finished.")
        } else {
            print("⚠️ Recognition task was already nil.")
        }
        
        recognitionRequest = nil

        if isRecording {
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
                 self.errorMessage = NSLocalizedString("speech_permission_denied_or_restricted_check_settings", 
                     comment: "Voice recognition is disabled. Please enable it in your device Settings")
             }
            return false
        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = NSLocalizedString("unknown_speech_permission_status", 
                    comment: "Unable to determine voice recognition permissions. Please check your device Settings")
            }
            return false
        }
    }
}
