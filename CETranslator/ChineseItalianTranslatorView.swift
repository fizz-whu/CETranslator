import SwiftUI
import Speech
import Translation
import AVFoundation

struct ChineseItalianTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Chinese recording state
    @State private var isRecordingIT = false // Italian recording state
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Translation sessions for Chinese <-> Italian
    @State private var translationSessionZHtoIT: Translation.TranslationSession?
    @State private var translationSessionITtoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToIt // Default mode

    // Updated enum cases for Chinese/Italian
    enum TranslationMode {
        case zhToIt
        case itToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToIt ? "Tap & Hold 中文 button..." : "Tap & Hold Italiano button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingIT {
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
                                if !isRecordingZH && !isRecordingIT {
                                    isRecordingZH = true
                                    currentMode = .zhToIt // Set mode
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
                    Text("中文 -> Italiano") // Update label
                        .font(.caption)
                }

                // Italian Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingIT ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for Italian, e.g., teal
                            .foregroundStyle(isRecordingIT ? .red : .teal)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingIT && !isRecordingZH {
                                    isRecordingIT = true
                                    currentMode = .itToZh // Set mode
                                    resetState()
                                    // Use Italian language code for speech
                                    vm.startRecording(sourceLanguage: "it-IT")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingIT {
                                    isRecordingIT = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("Italiano -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToIt ? "中文 -> Italiano" : "Italiano -> 中文")
        // Use .translationTask for ZH -> IT
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "it")      // Italian target
        ) { session in
            if translationSessionZHtoIT == nil {
                print("🔑 TranslationSession (ZH->IT) obtained.")
                translationSessionZHtoIT = session
            }
        }
        // Use .translationTask for IT -> ZH
        .translationTask(
            source: Locale.Language(identifier: "it"),      // Italian source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionITtoZH == nil {
                print("🔑 TranslationSession (IT->ZH) obtained.")
                translationSessionITtoZH = session
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
                print("📝 Final recognition result (\(currentMode == .zhToIt ? "ZH" : "IT")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToIt ? translationSessionZHtoIT : translationSessionITtoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToIt ? "ZH->IT" : "IT->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToIt ? "ZH->IT" : "IT->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToIt ? "ZH" : "IT")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToIt ? "IT" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToIt ? "it-IT" : "zh-Hans" // Use appropriate speech codes
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
        ChineseItalianTranslatorView()
    }
}