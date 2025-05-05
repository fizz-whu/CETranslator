import SwiftUI
import Speech
import Translation
import AVFoundation

struct ChineseKoreanTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Chinese recording state
    @State private var isRecordingKO = false // Korean recording state
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Translation sessions for Chinese <-> Korean
    @State private var translationSessionZHtoKO: Translation.TranslationSession?
    @State private var translationSessionKOtoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToKo // Default mode

    // Updated enum cases for Chinese/Korean
    enum TranslationMode {
        case zhToKo
        case koToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToKo ? "Tap & Hold 中文 button..." : "Tap & Hold 한국어 button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingKO {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 2)
                    }
                }
                .padding()

            // Translation result box
            Text(translatedText.isEmpty ? "Translation will appear here" : translatedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    if isTranslating {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                .padding()

            Spacer()

            HStack(spacing: 40) {
                // Chinese Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingZH ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(isRecordingZH ? .red : .orange) // Keep orange for Chinese
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingZH && !isRecordingKO {
                                    isRecordingZH = true
                                    currentMode = .zhToKo // Set mode
                                    resetState()
                                    // Use Chinese language code
                                    vm.startRecording(sourceLanguage: "zh-Hans")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingZH {
                                    isRecordingZH = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("中文 -> 한국어") // Update label
                        .font(.caption)
                }

                // Korean Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingKO ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for Korean, e.g., indigo
                            .foregroundStyle(isRecordingKO ? .red : .indigo)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingKO && !isRecordingZH {
                                    isRecordingKO = true
                                    currentMode = .koToZh // Set mode
                                    resetState()
                                    // Use Korean language code for speech
                                    vm.startRecording(sourceLanguage: "ko-KR")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingKO {
                                    isRecordingKO = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("한국어 -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToKo ? "中文 -> 한국어" : "한국어 -> 中文")
        // Use .translationTask for ZH -> KO
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "ko")      // Korean target
        ) { session in
            if translationSessionZHtoKO == nil {
                print("🔑 TranslationSession (ZH->KO) obtained.")
                translationSessionZHtoKO = session
            }
        }
        // Use .translationTask for KO -> ZH
        .translationTask(
            source: Locale.Language(identifier: "ko"),      // Korean source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionKOtoZH == nil {
                print("🔑 TranslationSession (KO->ZH) obtained.")
                translationSessionKOtoZH = session
            }
        }
        // Keep the task that handles the actual translation logic
        .task(id: textToTranslate) {
            await handleTranslation()
        }
    }

    private func resetState() {
        vm.recognizedText = ""
        translatedText = ""
        textToTranslate = ""
    }

    private func handleRecordingEnd() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
            await MainActor.run {
                // Update logging
                print("📝 Final recognition result (\(currentMode == .zhToKo ? "ZH" : "KO")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToKo ? translationSessionZHtoKO : translationSessionKOtoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToKo ? "ZH->KO" : "KO->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToKo ? "ZH->KO" : "KO->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToKo ? "ZH" : "KO")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToKo ? "KO" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToKo ? "ko-KR" : "zh-Hans" // Use appropriate speech codes
            )
        } catch {
            print("🔴 Translation error: \(error.localizedDescription)")
            await MainActor.run {
                translatedText = "Translation error: \(error.localizedDescription)"
                isTranslating = false
            }
        }
    }

    private func speakText(_ text: String, language: String) {
         guard !text.isEmpty else { return }
         do {
             try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
             try AVAudioSession.sharedInstance().setActive(true)

             let utterance = AVSpeechUtterance(string: text)
             utterance.voice = AVSpeechSynthesisVoice(language: language) // Use provided language code
             utterance.rate = AVSpeechUtteranceDefaultSpeechRate
             utterance.pitchMultiplier = 1.0

             print("🗣️ Speaking: \"\(text)\" in language \(language)")
             synthesizer.speak(utterance)
         } catch {
             print("🔴 Audio Session Configuration Error: \(error.localizedDescription)")
         }
     }
}

#Preview {
    ChineseKoreanTranslatorView()
        .environmentObject(SpeechTranslationViewModel()) // Add environment object for preview
}