import SwiftUI
import Speech
import Translation
import AVFoundation

struct ChineseFrenchTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Chinese recording state
    @State private var isRecordingFR = false // French recording state
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Translation sessions for Chinese <-> French
    @State private var translationSessionZHtoFR: Translation.TranslationSession?
    @State private var translationSessionFRtoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToFr // Default mode

    // Updated enum cases for Chinese/French
    enum TranslationMode {
        case zhToFr
        case frToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToFr ? "Tap & Hold 中文 button..." : "Tap & Hold Français button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingFR {
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
                                if !isRecordingZH && !isRecordingFR {
                                    isRecordingZH = true
                                    currentMode = .zhToFr // Set mode
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
                    Text("中文 -> Français") // Update label
                        .font(.caption)
                }

                // French Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingFR ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for French, e.g., pink
                            .foregroundStyle(isRecordingFR ? .red : .pink)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingFR && !isRecordingZH {
                                    isRecordingFR = true
                                    currentMode = .frToZh // Set mode
                                    resetState()
                                    // Use French language code for speech
                                    vm.startRecording(sourceLanguage: "fr-FR")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingFR {
                                    isRecordingFR = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("Français -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToFr ? "中文 -> Français" : "Français -> 中文")
        // Use .translationTask for ZH -> FR
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "fr")      // French target
        ) { session in
            if translationSessionZHtoFR == nil {
                print("🔑 TranslationSession (ZH->FR) obtained.")
                translationSessionZHtoFR = session
            }
        }
        // Use .translationTask for FR -> ZH
        .translationTask(
            source: Locale.Language(identifier: "fr"),      // French source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionFRtoZH == nil {
                print("🔑 TranslationSession (FR->ZH) obtained.")
                translationSessionFRtoZH = session
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
                print("📝 Final recognition result (\(currentMode == .zhToFr ? "ZH" : "FR")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToFr ? translationSessionZHtoFR : translationSessionFRtoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToFr ? "ZH->FR" : "FR->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToFr ? "ZH->FR" : "FR->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToFr ? "ZH" : "FR")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToFr ? "FR" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToFr ? "fr-FR" : "zh-Hans" // Use appropriate speech codes
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
    ChineseFrenchTranslatorView()
        .environmentObject(SpeechTranslationViewModel()) // Add for preview
}