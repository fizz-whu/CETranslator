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
    private var speechRecognizerAR: SFSpeechRecognizer? // Added AR recognizer
    private var speechRecognizerDE: SFSpeechRecognizer? // Added DE recognizer
    private var speechRecognizerHI: SFSpeechRecognizer? // Added HI recognizer
    private var speechRecognizerRU: SFSpeechRecognizer? // Added RU recognizer
    private var speechRecognizerTH: SFSpeechRecognizer? // Added TH recognizer
    private var speechRecognizerVI: SFSpeechRecognizer? // Added VI recognizer

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
        speechRecognizerAR = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))   // Initialize AR recognizer
        speechRecognizerDE = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))   // Initialize DE recognizer
        speechRecognizerHI = SFSpeechRecognizer(locale: Locale(identifier: "hi-IN"))   // Initialize HI recognizer
        speechRecognizerRU = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))   // Initialize RU recognizer
        speechRecognizerTH = SFSpeechRecognizer(locale: Locale(identifier: "th-TH"))   // Initialize TH recognizer
        speechRecognizerVI = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))   // Initialize VI recognizer
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
                return "没有检测到语音\n请长按麦克风并清晰说话 🎤"
            case "ja-JP":
                return "音声が検出されませんでした\nマイクを長押しして、はっきりと話してください 🎤"
            case "es-ES":
                return "No se detectó voz\nMantén presionado el micrófono y habla claramente 🎤"
            case "it-IT":
                return "Nessuna voce rilevata\nTieni premuto il microfono e parla chiaramente 🎤"
            case "ko-KR":
                return "음성이 감지되지 않았습니다\n마이크를 길게 누르고 명확하게 말씀하세요 🎤"
            case "fr-FR":
                return "Aucune voix détectée\nMaintenez le micro et parlez clairement 🎤"
            case "pt-PT":
                return "Nenhuma voz detectada\nMantenha pressionado o microfone e fale claramente 🎤"
            case "ar-SA":
                return "لم يتم اكتشاف صوت\nاضغط مع الاستمرار على الميكروفون وتحدث بوضوح 🎤"
            case "de-DE":
                return "Keine Sprache erkannt\nMikrofon gedrückt halten und deutlich sprechen 🎤"
            case "hi-IN":
                return "कोई आवाज़ नहीं मिली\nमाइक्रोफ़ोन दबाए रखें और साफ़ बोलें 🎤"
            case "ru-RU":
                return "Речь не обнаружена\nУдерживайте микрофон и говорите четко 🎤"
            case "th-TH":
                return "ไม่พบเสียงพูด\nกดค้างไมโครโฟนและพูดให้ชัดเจน 🎤"
            case "vi-VN":
                return "Không phát hiện giọng nói\nNhấn giữ micrô và nói rõ ràng 🎤"
            default:
                return "No speech detected\nPress & hold microphone and speak clearly 🎤"
            }
        case "recognition_error":
            switch language {
            case "zh-Hans":
                return "无法识别语音\n请长按麦克风，说得更清楚一些 🎤"
            case "ja-JP":
                return "音声を認識できませんでした\nマイクを長押しして、もう少しはっきりと話してください 🎤"
            case "es-ES":
                return "Error de reconocimiento\nMantén presionado el micrófono y habla más claro 🎤"
            case "it-IT":
                return "Errore di riconoscimento\nTieni premuto il microfono e parla più chiaramente 🎤"
            case "ko-KR":
                return "음성 인식 오류\n마이크를 길게 누르고 더 명확하게 말씀하세요 🎤"
            case "fr-FR":
                return "Erreur de reconnaissance\nMaintenez le micro et parlez plus clairement 🎤"
            case "pt-PT":
                return "Erro de reconhecimento\nMantenha pressionado o microfone e fale mais claramente 🎤"
            case "ar-SA":
                return "خطأ في التعرف على الصوت\nاضغط مع الاستمرار على الميكروفون وتحدث بوضوح أكثر 🎤"
            case "de-DE":
                return "Spracherkennungsfehler\nMikrofon gedrückt halten und deutlicher sprechen 🎤"
            case "hi-IN":
                return "आवाज़ पहचानने में त्रुटि\nमाइक्रोफ़ोन दबाए रखें और अधिक स्पष्ट बोलें 🎤"
            case "ru-RU":
                return "Ошибка распознавания речи\nУдерживайте микрофон и говорите четче 🎤"
            case "th-TH":
                return "ข้อผิดพลาดในการรู้จำเสียง\nกดค้างไมโครโฟนและพูดให้ชัดเจนกว่านี้ 🎤"
            case "vi-VN":
                return "Lỗi nhận dạng giọng nói\nNhấn giữ micrô và nói rõ ràng hơn 🎤"
            default:
                return "Speech recognition error\nPress & hold microphone and speak more clearly 🎤"
            }
        default:
            return "An error occurred"
        }
    }

    func startRecording(sourceLanguage: String) {
        isRecording = true
        recognizedText = ""
        errorMessage = nil // Clear previous errors at the start
        
        print("🎤 Starting recording for \(sourceLanguage)")
        print("🧹 Cleared previous state - recognizedText: '\(recognizedText)', errorMessage: \(errorMessage?.description ?? "nil")")

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
        case "ar-SA": // Add case for Arabic
            recognizer = speechRecognizerAR
        case "de-DE": // Add case for German
            recognizer = speechRecognizerDE
        case "hi-IN": // Add case for Hindi
            recognizer = speechRecognizerHI
        case "ru-RU": // Add case for Russian
            recognizer = speechRecognizerRU
        case "th-TH": // Add case for Thai
            recognizer = speechRecognizerTH
        case "vi-VN": // Add case for Vietnamese
            recognizer = speechRecognizerVI
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
                
                // Only show "no speech detected" error if we truly have no speech AND we're still recording
                DispatchQueue.main.async {
                    // Don't show error if we already have recognized text (speech was detected)
                    if !self.recognizedText.isEmpty {
                        print("📝 Ignoring error because we already have recognized text: '\(self.recognizedText)'")
                        return
                    }
                    
                    // Only show errors for actual problems, not normal completion
                    switch nsError.code {
                    case 1110: // No speech detected - only show if no text was recognized
                        if self.recognizedText.isEmpty && self.isRecording {
                            self.errorMessage = self.getLocalizedErrorMessage(for: "no_speech_detected", language: sourceLanguage)
                        }
                    case 216: // Recognition service unavailable
                        self.errorMessage = "Speech recognition service unavailable. Please check your internet connection."
                    case 301: // Audio recording problem
                        self.errorMessage = "Audio recording problem. Please check microphone permissions."
                    case 1107: // Connection was interrupted
                        if self.recognizedText.isEmpty {
                            self.errorMessage = "Connection interrupted. Please try again."
                        }
                    case 203, 209: // Normal completion codes - don't show errors
                        print("📝 Normal recognition completion, not showing error")
                    default:
                        if self.recognizedText.isEmpty {
                            self.errorMessage = self.getLocalizedErrorMessage(for: "recognition_error", language: sourceLanguage)
                        }
                    }
                    self.isRecording = false
                }
                
                // Clean up resources safely
                if self.audioEngine.isRunning {
                    self.audioEngine.stop()
                    do {
                        self.audioEngine.inputNode.removeTap(onBus: 0)
                    } catch {
                        print("⚠️ Error removing audio tap during error cleanup: \(error.localizedDescription)")
                    }
                }
                self.recognitionRequest?.endAudio()
                self.recognitionTask = nil
                self.recognitionRequest = nil
                return
            }
    
            guard let result = result else { 
                print("⚠️ Received nil result without error")
                return 
            }
    
            DispatchQueue.main.async {
                let newText = result.bestTranscription.formattedString
                if self.recognizedText != newText {
                    self.recognizedText = newText
                    print("👂 Recognized (\(sourceLanguage)): \(self.recognizedText)")
                }
                
                // Clear any previous error messages when we get successful recognition
                if !newText.isEmpty {
                    self.errorMessage = nil
                }
    
                if result.isFinal {
                    print("✅ Final recognition result (\(sourceLanguage)): \(self.recognizedText)")
                    // Don't auto-cleanup on final result, let user manually stop
                    self.isRecording = false
                }
            }
        }
    }

    func stopRecording() {
        // Cancel recognition task first to prevent callbacks
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
            print("🏁 Recognition task cancelled.")
        }
        
        // Clean up audio engine safely
        if audioEngine.isRunning {
            audioEngine.stop()
            
            // Remove tap safely with error handling
            do {
                audioEngine.inputNode.removeTap(onBus: 0)
                print("🛑 Audio engine stopped and tap removed.")
            } catch {
                print("⚠️ Error removing audio tap: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Audio engine was not running.")
        }

        // End audio request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Clean up audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("🔊 Audio session deactivated.")
        } catch {
            print("⚠️ Error deactivating audio session: \(error.localizedDescription)")
        }

        // Update recording state on main thread
        DispatchQueue.main.async {
            self.isRecording = false
            // Clear error message if we have recognized text (successful recording)
            if !self.recognizedText.isEmpty {
                self.errorMessage = nil
                print("🎙 Recording stopped successfully with text: '\(self.recognizedText)'")
            } else {
                print("🎙 Recording stopped with no recognized text")
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
