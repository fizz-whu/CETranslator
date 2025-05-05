import SwiftUI
import Speech
import Translation
import AVFoundation

// Rename the struct
struct ChineseToEnglishView: View {
    @StateObject private var vm = SpeechTranslationViewModel() // Re-use the same ViewModel
    @State private var isRecording = false
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = "" // This will hold the recognized Chinese text
    @State private var translationSession: TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box (Shows recognized Chinese)
            Text(vm.recognizedText.isEmpty ? "等待语音输入..." : vm.recognizedText) // Updated placeholder
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay {
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 2)
                    }
                }
                .padding()

            // Translation result box (Shows translated English)
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

            // Recording button
            Button(action: {}) {
                Image(systemName: isRecording ? "waveform" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(isRecording ? .red : .blue)
            }
            .buttonStyle(.bouncy) // Revert back to using the static member
            .padding(.bottom, 40)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRecording {
                            isRecording = true
                            vm.recognizedText = "" // Clear previous text
                            translatedText = ""    // Clear previous translation
                            textToTranslate = ""   // Clear previous text to translate
                            vm.startRecording(sourceLanguage: "zh-Hans")
                        }
                    }
                    .onEnded { _ in
                        isRecording = false
                        vm.stopRecording()
                        print("🎙 Recording stopped with text (Chinese): \(vm.recognizedText)")

                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            await MainActor.run {
                                print("📝 Final recognition result (Chinese): \(vm.recognizedText)")
                                textToTranslate = vm.recognizedText // Set the Chinese text to be translated
                                print("🔄 Triggering translation for: '\(textToTranslate)'")
                            }
                        }
                    }
            )
        }
        // Update the navigation title
        .navigationTitle("中文 -> EN") // Updated title
        .translationTask( // Setup session for Chinese -> English
            source: Locale.Language(identifier: "zh-Hans"), // Source is Chinese
            target: Locale.Language(identifier: "en")      // Target is English
        ) { session in
            if translationSession == nil {
                 print("🔑 TranslationSession (zh->en) obtained and stored.")
                 translationSession = session
            }
        }
        .task(id: textToTranslate) { // Reacts to changes in recognized Chinese text
            guard !textToTranslate.isEmpty, let session = translationSession, !isTranslating else {
                // ... (guard logic remains similar) ...
                return
            }

            print("🚀 Translation task triggered for (Chinese): '\(textToTranslate)'")

            do {
                isTranslating = true
                print("📥 Chinese input: \"\(textToTranslate)\"")

                // Translate Chinese to English
                let result = try await session.translate(textToTranslate)
                let englishText = result.targetText // Store translated English text
                print("📤 English output: \"\(englishText)\"")

                await MainActor.run {
                    translatedText = englishText // Update UI with English text
                    isTranslating = false
                    print("💫 UI Updated with translation")
                }

                // Speak the translated text
                speakText(englishText, language: "en-US") // Changed from chineseText to englishText and language to en-US

                // Remove the cleanup code that was here
                // This will keep the translation visible until next recording
            } catch {
                print("🔴 Translation error: \(error.localizedDescription)")
                await MainActor.run {
                    translatedText = "Translation error: \(error.localizedDescription)"
                    isTranslating = false
                }
            }
        }
    }

    // Helper function to handle speech synthesis (same as before)
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
} // End of ChineseToEnglishView struct

// Remove these definitions (should already be removed from previous steps)
// struct BounceButtonStyle: ButtonStyle { ... }
// extension ButtonStyle where Self == BounceButtonStyle { ... }

#Preview {
    NavigationView {
        // Update the preview to use the new struct name
        ChineseToEnglishView()
    }
}