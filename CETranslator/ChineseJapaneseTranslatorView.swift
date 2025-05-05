import SwiftUI
import Speech
import Translation // Keep this import
import AVFoundation

struct ChineseJapaneseTranslatorView: View {
    // Use the same ViewModel, assuming it's generic enough
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingZH = false // Renamed for clarity
    @State private var isRecordingJA = false // Renamed for clarity
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    // Update session variable names and types
    @State private var translationSessionZHtoJA: Translation.TranslationSession?
    @State private var translationSessionJAtoZH: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .zhToJa // Default mode

    // Update enum cases
    enum TranslationMode {
        case zhToJa
        case jaToZh
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .zhToJa ? "Tap & Hold 中文 button..." : "Tap & Hold 日本語 button...") : // Updated placeholders
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    // Update recording state check
                    if isRecordingZH || isRecordingJA {
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
                            // Keep orange for Chinese? Or choose another color
                            .foregroundStyle(isRecordingZH ? .red : .orange)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Update recording state check
                                if !isRecordingZH && !isRecordingJA {
                                    isRecordingZH = true
                                    currentMode = .zhToJa // Set mode
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
                    Text("中文 -> 日本語") // Update label
                        .font(.caption)
                }

                // Japanese Recording Button
                VStack {
                    Button(action: {}) {
                        Image(systemName: isRecordingJA ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            // Choose a color for Japanese, e.g., purple
                            .foregroundStyle(isRecordingJA ? .red : .purple)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isRecordingJA && !isRecordingZH {
                                    isRecordingJA = true
                                    currentMode = .jaToZh // Set mode
                                    resetState()
                                    // Use Japanese language code for speech
                                    vm.startRecording(sourceLanguage: "ja-JP") // Correct locale used here
                                }
                            }
                            .onEnded { _ in
                                if isRecordingJA {
                                    isRecordingJA = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("日本語 -> 中文") // Update label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .zhToJa ? "中文 -> 日本語" : "日本語 -> 中文")
        // Use .translationTask for ZH -> JA
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"), // Chinese source
            target: Locale.Language(identifier: "ja")      // Japanese target
        ) { session in
            if translationSessionZHtoJA == nil {
                print("🔑 TranslationSession (ZH->JA) obtained.")
                translationSessionZHtoJA = session
            }
        }
        // Use .translationTask for JA -> ZH
        .translationTask(
            source: Locale.Language(identifier: "ja"),      // Japanese source
            target: Locale.Language(identifier: "zh-Hans") // Chinese target
        ) { session in
            if translationSessionJAtoZH == nil {
                print("🔑 TranslationSession (JA->ZH) obtained.")
                translationSessionJAtoZH = session
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
                // Update logging if desired
                print("📝 Final recognition result (\(currentMode == .zhToJa ? "ZH" : "JA")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Update session logic
        let sessionToUse = currentMode == .zhToJa ? translationSessionZHtoJA : translationSessionJAtoZH

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty {
                 // Don't log
            } else if sessionToUse == nil {
                // Update logging
                print("⏸️ Translation skipped: Session for \(currentMode == .zhToJa ? "ZH->JA" : "JA->ZH") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return
        }

        // Update logging
        print("🚀 Translation task triggered for (\(currentMode == .zhToJa ? "ZH->JA" : "JA->ZH")): '\(textToTranslate)'")

        do {
            isTranslating = true
            // Update logging
            print("📥 Input (\(currentMode == .zhToJa ? "ZH" : "JA")): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            // Update logging
            print("📤 Output (\(currentMode == .zhToJa ? "JA" : "ZH")): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text - Update language codes
            speakText(
                outputText,
                language: currentMode == .zhToJa ? "ja-JP" : "zh-Hans" // Use appropriate speech codes
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
        ChineseJapaneseTranslatorView()
    }
}