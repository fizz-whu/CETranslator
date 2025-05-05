import SwiftUI
import Speech
import Translation
import AVFoundation

struct ChinesePortugueseTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Chinese recording state
    @State private var isRecordingPT = false // Portuguese recording state
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Translation sessions for Chinese <-> Portuguese
    @State private var translationSessionZHtoPT: Translation.TranslationSession?
    @State private var translationSessionPTtoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToPt // Default mode

    // Updated enum cases for Chinese/Portuguese
    enum TranslationMode {
        case zhToPt
        case ptToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToPt ? "Tap & Hold 中文 button..." : "Tap & Hold Português button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingPT {
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
                                if !isRecordingZH && !isRecordingPT {
                                    isRecordingZH = true
                                    currentMode = .zhToPt // Set mode
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
                    Text("中文 -> Português") // Update label
                        .font(.caption)
                }

                // Portuguese Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingPT ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for Portuguese, e.g., cyan
                            .foregroundStyle(isRecordingPT ? .red : .cyan)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingPT && !isRecordingZH {
                                    isRecordingPT = true
                                    currentMode = .ptToZh // Set mode
                                    resetState()
                                    // Use Portuguese language code for speech
                                    vm.startRecording(sourceLanguage: "pt-PT")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingPT {
                                    isRecordingPT = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("Português -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToPt ? "中文 -> Português" : "Português -> 中文")
        // Use .translationTask for ZH -> PT
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "pt")      // Portuguese target
        ) { session in
            if translationSessionZHtoPT == nil {
                print("🔑 TranslationSession (ZH->PT) obtained.")
                translationSessionZHtoPT = session
            }
        }
        // Use .translationTask for PT -> ZH
        .translationTask(
            source: Locale.Language(identifier: "pt"),      // Portuguese source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionPTtoZH == nil {
                print("🔑 TranslationSession (PT->ZH) obtained.")
                translationSessionPTtoZH = session
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
                print("📝 Final recognition result (\(currentMode == .zhToPt ? "ZH" : "PT")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToPt ? translationSessionZHtoPT : translationSessionPTtoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToPt ? "ZH->PT" : "PT->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToPt ? "ZH->PT" : "PT->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToPt ? "ZH" : "PT")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToPt ? "PT" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToPt ? "pt-PT" : "zh-Hans" // Use appropriate speech codes
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
    ChinesePortugueseTranslatorView()
        .environmentObject(SpeechTranslationViewModel()) // Add for preview
}