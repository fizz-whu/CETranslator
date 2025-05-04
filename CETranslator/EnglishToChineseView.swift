import SwiftUI
import Speech
import Translation
import AVFoundation // Add this import

// Rename the struct
struct EnglishToChineseView: View {
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecording = false
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    @State private var translationSession: TranslationSession? // Store the session
    @State private var synthesizer = AVSpeechSynthesizer() // Add synthesizer state

    var body: some View {
        VStack(spacing: 20) {
            // Recognition result box
            Text(vm.recognizedText.isEmpty ? "Waiting for speech..." : vm.recognizedText)
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
                            vm.recognizedText = ""
                            translatedText = ""
                            vm.startRecording(sourceLanguage: "English")
                        }
                    }
                    .onEnded { _ in
                        isRecording = false
                        vm.stopRecording()
                        print("🎙 Recording stopped with text: \(vm.recognizedText)")
                        
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            await MainActor.run {
                                print("📝 Final recognition result: \(vm.recognizedText)")
                                textToTranslate = vm.recognizedText
                                print("🔄 Triggering translation for: '\(textToTranslate)'")
                            }
                        }
                    }
            )
        }
        // Update the navigation title
        .navigationTitle("EN -> 中文")
        // Remove the previous .onChange modifier as .task(id:) handles reactivity
        .translationTask( // Use this ONLY to get the session
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "zh-Hans")
        ) { session in
            // Store the session when the view appears
            if translationSession == nil { // Store only once
                 print("🔑 TranslationSession obtained and stored.")
                 translationSession = session
            }
        }
        .task(id: textToTranslate) { // Use .task(id:) to react to changes
            // Guard against empty text, missing session, or already translating
            guard !textToTranslate.isEmpty, let session = translationSession, !isTranslating else {
                if textToTranslate.isEmpty {
                    // Don't log anything if it's just the initial empty state or cleanup
                } else if translationSession == nil {
                    print("⏸️ Translation task skipped: translationSession not yet available.")
                } else if isTranslating {
                     print("⏸️ Translation task skipped: Already translating.")
                }
                return
            }

            print("🚀 Translation task triggered for: '\(textToTranslate)'")

            do {
                isTranslating = true // Set translating flag
                print("📥 English input: \"\(textToTranslate)\"")

                // Use the stored session
                let result = try await session.translate(textToTranslate)
                let chineseText = result.targetText // Store translated text
                print("📤 Chinese output: \"\(chineseText)\"")

                await MainActor.run {
                    translatedText = chineseText // Update UI first
                    isTranslating = false // Clear translating flag
                    print("💫 UI Updated with translation")
                }

                // Speak the translated text after UI update
                speakText(chineseText, language: "zh-Hans")

                // Clean up after delay
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    // Check if textToTranslate hasn't changed again during the delay
                    if !textToTranslate.isEmpty {
                        print("🧹 Cleanup running...")
                        vm.recognizedText = ""
                        translatedText = ""
                        textToTranslate = "" // This will re-trigger the task, but the guard will catch it
                        print("🧹 Cleanup complete.")
                    } else {
                         print("🧹 Cleanup skipped: textToTranslate already cleared.")
                    }
                }
            } catch {
                print("🔴 Translation error: \(error.localizedDescription)")
                await MainActor.run {
                    translatedText = "Translation error: \(error.localizedDescription)"
                    isTranslating = false // Clear translating flag on error
                }
            }
        }
    }

    // Add a helper function to handle speech synthesis
    private func speakText(_ text: String, language: String) {
         guard !text.isEmpty else { return }
         do {
             // Configure audio session for playback
             try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
             try AVAudioSession.sharedInstance().setActive(true)

             let utterance = AVSpeechUtterance(string: text)
             utterance.voice = AVSpeechSynthesisVoice(language: language)
             utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Adjust rate if needed
             utterance.pitchMultiplier = 1.0 // Adjust pitch if needed

             print("🗣️ Speaking: \"\(text)\" in language \(language)")
             synthesizer.speak(utterance)
         } catch {
             print("🔴 Audio Session Configuration Error: \(error.localizedDescription)")
         }
     }
} // End of EnglishToChineseView struct

// Remove these definitions (should already be removed from previous steps)
// struct BounceButtonStyle: ButtonStyle { ... }
// extension ButtonStyle where Self == BounceButtonStyle { ... }

#Preview {
    NavigationView {
        // Update the preview to use the new struct name
        EnglishToChineseView()
    }
}
