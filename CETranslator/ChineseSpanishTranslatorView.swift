import SwiftUI
import Speech
import Translation
import AVFoundation

struct ChineseSpanishTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Chinese recording state
    @State private var isRecordingES = false // Spanish recording state
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Translation sessions for Chinese <-> Spanish
    @State private var translationSessionZHtoES: Translation.TranslationSession?
    @State private var translationSessionEStoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToEs // Default mode

    // Updated enum cases for Chinese/Spanish
    enum TranslationMode {
        case zhToEs
        case esToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToEs ? "Tap & Hold 中文 button..." : "Tap & Hold Español button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingES {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 2)
                    }
                }
                .padding()

            // Translation result box (remains the same)
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
                                if !isRecordingZH && !isRecordingES {
                                    isRecordingZH = true
                                    currentMode = .zhToEs // Set mode
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
                    Text("中文 -> Español") // Update label
                        .font(.caption)
                }

                // Spanish Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingES ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for Spanish, e.g., green
                            .foregroundStyle(isRecordingES ? .red : .green)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingES && !isRecordingZH {
                                    isRecordingES = true
                                    currentMode = .esToZh // Set mode
                                    resetState()
                                    // Use Spanish language code for speech
                                    vm.startRecording(sourceLanguage: "es-ES")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingES {
                                    isRecordingES = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("Español -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToEs ? "中文 -> Español" : "Español -> 中文")
        // Use .translationTask for ZH -> ES
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "es")      // Spanish target
        ) { session in
            if translationSessionZHtoES == nil {
                print("🔑 TranslationSession (ZH->ES) obtained.")
                translationSessionZHtoES = session
            }
        }
        // Use .translationTask for ES -> ZH
        .translationTask(
            source: Locale.Language(identifier: "es"),      // Spanish source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionEStoZH == nil {
                print("🔑 TranslationSession (ES->ZH) obtained.")
                translationSessionEStoZH = session
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
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                // Update logging
                print("📝 Final recognition result (\(currentMode == .zhToEs ? "ZH" : "ES")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToEs ? translationSessionZHtoES : translationSessionEStoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToEs ? "ZH->ES" : "ES->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToEs ? "ZH->ES" : "ES->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToEs ? "ZH" : "ES")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToEs ? "ES" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToEs ? "es-ES" : "zh-Hans" // Use appropriate speech codes
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
    NavigationView {
        // Update preview
        ChineseSpanishTranslatorView()
    }
}