import SwiftUI
import Speech
import Translation // Keep this import
import AVFoundation

struct ChineseEnglishTranslatorView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingEN = false
    @State private var isRecordingZH = false
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    @State private var translationSessionENtoZH: Translation.TranslationSession?
    @State private var translationSessionZHtoEN: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationMode = .enToZh

    enum TranslationMode {
        case enToZh
        case zhToEn
    }

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box - Updated placeholder text
            Text(vm.recognizedText.isEmpty ?
                 (currentMode == .enToZh ? "Tap & Hold EN button..." : "Tap & Hold 中文 button...") : // More specific placeholder
                 vm.recognizedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    if isRecordingEN || isRecordingZH {
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
                // English Recording Button
                VStack { // Wrap button and text
                    Button(action: {}) {
                        Image(systemName: isRecordingEN ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(isRecordingEN ? .red : .blue)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isRecordingEN && !isRecordingZH {
                                    isRecordingEN = true
                                    currentMode = .enToZh // Set mode here
                                    resetState()
                                    vm.startRecording(sourceLanguage: "en-US")
                                }
                            }
                            .onEnded { _ in
                                if isRecordingEN {
                                    isRecordingEN = false
                                    vm.stopRecording()
                                    handleRecordingEnd()
                                }
                            }
                    )
                    Text("EN -> 中文") // Add label
                        .font(.caption)
                }

                // Chinese Recording Button
                VStack { // Wrap button and text
                    Button(action: {}) {
                        Image(systemName: isRecordingZH ? "waveform" : "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(isRecordingZH ? .red : .orange)
                    }
                    .buttonStyle(.bouncy)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isRecordingZH && !isRecordingEN {
                                    isRecordingZH = true
                                    currentMode = .zhToEn // Set mode here
                                    resetState()
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
                    Text("中文 -> EN") // Add label
                        .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
        // Update navigation title dynamically
        .navigationTitle(currentMode == .enToZh ? "EN -> 中文" : "中文 -> EN")
        // Remove the previous .task that tried to initialize sessions
        // .task { ... } // REMOVE THIS

        // Use .translationTask to get the EN -> ZH session
        .translationTask(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "zh-Hans")
        ) { session in // 'session' is valid *here*
            if translationSessionENtoZH == nil {
                print("🔑 TranslationSession (EN->ZH) obtained.")
                translationSessionENtoZH = session // Assign to state variable
            }
        }
        // Use another .translationTask to get the ZH -> EN session
        .translationTask(
            source: Locale.Language(identifier: "zh-Hans"),
            target: Locale.Language(identifier: "en")
        ) { session in // 'session' is valid *here*
            if translationSessionZHtoEN == nil {
                print("🔑 TranslationSession (ZH->EN) obtained.")
                translationSessionZHtoEN = session // Assign to state variable
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
            // Add a small delay to ensure recognition is finalized
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                print("📝 Final recognition result (\(currentMode == .enToZh ? "EN" : "ZH")): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText // Set the text to be translated
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        // Determine which session to use based on the current mode
        let sessionToUse = currentMode == .enToZh ? translationSessionENtoZH : translationSessionZHtoEN

        // Guard against empty text, missing session, or already translating
        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            // Check the reason for guard failure
            if textToTranslate.isEmpty {
                 // Don't log if empty, it's expected after reset or initial state
            } else if sessionToUse == nil { // Check the original session variable
                print("⏸️ Translation skipped: Session for \(currentMode == .enToZh ? "EN->ZH" : "ZH->EN") not ready.")
            } else if isTranslating {
                print("⏸️ Translation skipped: Already translating.")
            }
            return // Exit if guard fails
        }

        // --- The rest of the function remains the same ---
        // 'session' is now guaranteed to be non-nil here

        print("🚀 Translation task triggered for (\(currentMode == .enToZh ? "EN->ZH" : "ZH->EN")): '\(textToTranslate)'")

        do {
            isTranslating = true
            print("📥 Input (\(currentMode == .enToZh ? "EN" : "ZH")): \"\(textToTranslate)\"")

            // Perform translation using the obtained session
            let result = try await session.translate(textToTranslate) // Use the 'session' from the guard
            let outputText = result.targetText
            print("📤 Output (\(currentMode == .enToZh ? "ZH" : "EN")): \"\(outputText)\"")


            await MainActor.run {
                translatedText = outputText // Update UI
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text
            speakText(
                outputText,
                language: currentMode == .enToZh ? "zh-Hans" : "en-US"
            )
        } catch {
            print("🔴 Translation error: \(error.localizedDescription)")
            await MainActor.run {
                translatedText = "Translation error: \(error.localizedDescription)"
                isTranslating = false // Clear flag on error
            }
        }
    }

    private func speakText(_ text: String, language: String) {
         guard !text.isEmpty else { return }
         do {
             try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
             try AVAudioSession.sharedInstance().setActive(true)

             let utterance = AVSpeechUtterance(string: text)
             utterance.voice = AVSpeechSynthesisVoice(language: language)
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
        ChineseEnglishTranslatorView()
    }
}