import SwiftUI
import Speech
import Translation
import AVFoundation

struct TranslatorView: View {
    // Parameters for the selected languages
    let sourceLanguage: SupportedLanguage
    let targetLanguage: SupportedLanguage

    // State objects and variables
    @StateObject private var vm = SpeechTranslationViewModel()
    @State private var isRecordingSource = false // Recording state for source language
    @State private var isRecordingTarget = false // Recording state for target language
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var textToTranslate = ""
    @State private var translationSessionSourceToTarget: Translation.TranslationSession?
    @State private var translationSessionTargetToSource: Translation.TranslationSession?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var currentMode: TranslationDirection = .sourceToTarget // Default direction

    // Enum to manage translation direction
    enum TranslationDirection {
        case sourceToTarget
        case targetToSource
    }

    // Computed properties for dynamic labels and codes
    private var sourceName: String { sourceLanguage.rawValue }
    private var targetName: String { targetLanguage.rawValue }
    private var sourceCode: String { sourceLanguage.languageCode }
    private var targetCode: String { targetLanguage.languageCode }
    private var sourceLocaleId: String { sourceLanguage.translationLocaleIdentifier }
    private var targetLocaleId: String { targetLanguage.translationLocaleIdentifier }

    // Computed property for the dynamic translation placeholder text
    private var dynamicTranslationPlaceholder: String {
        let localizedText = sourceLanguage.translationPlaceholderText // Text in sourceLanguage

        if sourceLanguage == .english {
            return localizedText // Already English
        } else {
            // Add English fallback, dynamically fetched
            let englishFallbackText = SupportedLanguage.english.translationPlaceholderText
            return "\(localizedText) (\(englishFallbackText))"
        }
    }

    // Computed property for the dynamic recognition placeholder text
    private var dynamicRecognitionPlaceholder: String {
        let activeLanguage = (currentMode == .sourceToTarget) ? sourceLanguage : targetLanguage
        let activeLanguageName = (currentMode == .sourceToTarget) ? sourceName : targetName

        // Get the localized format string from the active language
        let localizedFormat = activeLanguage.tapAndHoldButtonPlaceholderFormat
        // Create the localized placeholder by inserting the language name
        let localizedPlaceholder = String(format: localizedFormat, activeLanguageName)

        if activeLanguage == .english {
            return localizedPlaceholder
        } else {
            // For the English fallback, get the English format string
            let englishFormat = SupportedLanguage.english.tapAndHoldButtonPlaceholderFormat
            // Create the English version of the placeholder by inserting the *active* language name
            let englishFallbackText = String(format: englishFormat, activeLanguageName)
            return "\(localizedPlaceholder) (\(englishFallbackText))"
        }
    }

    // Computed property for the left microphone button label
    private var leftMicrophoneButtonLabel: String {
        let localizedLabel = sourceLanguage.tapAndHoldToSpeakLabelFormat // Directly use the string

        if sourceLanguage == .english {
            return localizedLabel
        } else {
            let englishFallbackText = SupportedLanguage.english.tapAndHoldToSpeakLabelFormat // Directly use the English string
            return "\(localizedLabel) (\(englishFallbackText))"
        }
    }

    // Computed property for the right microphone button label
    private var rightMicrophoneButtonLabel: String {
        let localizedLabel = targetLanguage.tapAndHoldToSpeakLabelFormat // Directly use the string

        if targetLanguage == .english {
            return localizedLabel
        } else {
            let englishFallbackText = SupportedLanguage.english.tapAndHoldToSpeakLabelFormat // Directly use the English string
            return "\(localizedLabel) (\(englishFallbackText))"
        }
    }

    var body: some View {
        ZStack { // Added ZStack for background color
            facebookBackgroundGray.edgesIgnoringSafeArea(.all) // Facebook-style background

            VStack(spacing: 20) {
                // Recognition result box - Dynamic placeholder
                Text(vm.recognizedText.isEmpty ?
                     dynamicRecognitionPlaceholder : // Use the new computed property here
                     vm.recognizedText)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .foregroundColor(vm.recognizedText.isEmpty ? .secondary : .primary) // Add this line
                    .padding()
                    .background(facebookCardBackground)
                    .cornerRadius(10)
                    .overlay {
                        if isRecordingSource || isRecordingTarget {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(facebookBlue, lineWidth: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                // Translation result box
                Text(translatedText.isEmpty ? dynamicTranslationPlaceholder : translatedText)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .foregroundColor(translatedText.isEmpty ? .secondary : .primary) // Add this line
                    .padding()
                    .background(facebookCardBackground)
                    .cornerRadius(10)
                    .overlay {
                        if isTranslating {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: facebookBlue)) // Style progress view
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)


                Spacer()

                HStack(spacing: 40) {
                    // Source Language Recording Button
                    VStack {
                        Button(action: {}) {
                            Image(systemName: isRecordingSource ? "waveform.circle.fill" : "mic.circle.fill") // Filled icon for source
                                .font(.system(size: 70)) // Slightly larger icon
                                .foregroundStyle(isRecordingSource ? Color.red : facebookBlue) // Facebook blue for default
                        }
                        .buttonStyle(.bouncy)
                        .accessibilityLabel(leftMicrophoneButtonLabel) // Added for accessibility
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isRecordingSource && !isRecordingTarget {
                                        isRecordingSource = true
                                        currentMode = .sourceToTarget
                                        resetState()
                                        vm.startRecording(sourceLanguage: sourceCode) // Use dynamic code
                                    }
                                }
                                .onEnded { _ in
                                    if isRecordingSource {
                                        isRecordingSource = false
                                        vm.stopRecording()
                                        handleRecordingEnd()
                                    }
                                }
                        )
                        Text("\(sourceName) → \(targetName)") // Dynamic label, using arrow
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel)) // Softer text color
                    }

                    // Target Language Recording Button
                    VStack {
                        Button(action: {}) {
                            Image(systemName: isRecordingTarget ? "waveform.circle.fill" : "mic.circle") // Outlined icon for target
                                .font(.system(size: 70)) // Slightly larger icon
                                .foregroundStyle(isRecordingTarget ? Color.red : facebookBlue) // Facebook blue for default
                        }
                        .buttonStyle(.bouncy)
                        .accessibilityLabel(rightMicrophoneButtonLabel) // Added for accessibility
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isRecordingTarget && !isRecordingSource {
                                        isRecordingTarget = true
                                        currentMode = .targetToSource
                                        resetState()
                                        vm.startRecording(sourceLanguage: targetCode) // Use dynamic code
                                    }
                                }
                                .onEnded { _ in
                                    if isRecordingTarget {
                                        isRecordingTarget = false
                                        vm.stopRecording()
                                        handleRecordingEnd()
                                    }
                                }
                        )
                        Text("\(targetName) → \(sourceName)") // Dynamic label, using arrow
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel)) // Softer text color
                    }
                }
                .padding(.bottom, 30) // Adjusted padding
            }
        }
        .navigationTitle(currentMode == .sourceToTarget ? "\(sourceName) → \(targetName)" : "\(targetName) → \(sourceName)")
        .navigationBarTitleDisplayMode(.inline) // Consistent with ContentView
        .toolbarBackground(facebookCardBackground, for: .navigationBar) // Facebook-style nav bar
        .toolbarBackground(.visible, for: .navigationBar) // Ensure nav bar background is visible
        // Translation Task for Source -> Target
        .translationTask(
            source: Locale.Language(identifier: sourceLocaleId), // Dynamic locale ID
            target: Locale.Language(identifier: targetLocaleId)  // Dynamic locale ID
        ) { session in
            if translationSessionSourceToTarget == nil {
                print("🔑 TranslationSession (\(sourceLocaleId)->\(targetLocaleId)) obtained.")
                translationSessionSourceToTarget = session
            }
        }
        // Translation Task for Target -> Source
        .translationTask(
            source: Locale.Language(identifier: targetLocaleId), // Dynamic locale ID
            target: Locale.Language(identifier: sourceLocaleId)  // Dynamic locale ID
        ) { session in
            if translationSessionTargetToSource == nil {
                print("🔑 TranslationSession (\(targetLocaleId)->\(sourceLocaleId)) obtained.")
                translationSessionTargetToSource = session
            }
        }
        .task(id: textToTranslate) {
            await handleTranslation()
        }
        // Request permissions on appear
        .task {
             _ = await vm.checkAndRequestPermission()
         }
         // Display error messages
         .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
             Button("OK") { vm.errorMessage = nil }
         }, message: {
             Text(vm.errorMessage ?? "An unknown error occurred.")
         })
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
                let recordingLang = currentMode == .sourceToTarget ? sourceName : targetName
                print("📝 Final recognition result (\(recordingLang)): \(vm.recognizedText)")
                textToTranslate = vm.recognizedText
                print("🔄 Triggering translation for: '\(textToTranslate)'")
            }
        }
    }

    private func handleTranslation() async {
        let sessionToUse = currentMode == .sourceToTarget ? translationSessionSourceToTarget : translationSessionTargetToSource
        let inputLang = currentMode == .sourceToTarget ? sourceName : targetName
        let outputLang = currentMode == .sourceToTarget ? targetName : sourceName
        let outputCode = currentMode == .sourceToTarget ? targetCode : sourceCode
        let sessionDesc = currentMode == .sourceToTarget ? "\(sourceLocaleId)->\(targetLocaleId)" : "\(targetLocaleId)->\(sourceLocaleId)"

        guard !textToTranslate.isEmpty, let session = sessionToUse, !isTranslating else {
            if textToTranslate.isEmpty { /* Don't log */ }
            else if sessionToUse == nil { print("⏸️ Translation skipped: Session for \(sessionDesc) not ready.") }
            else if isTranslating { print("⏸️ Translation skipped: Already translating.") }
            return
        }

        print("🚀 Translation task triggered for (\(sessionDesc)): '\(textToTranslate)'")

        do {
            isTranslating = true
            print("📥 Input (\(inputLang)): \"\(textToTranslate)\"")

            let result = try await session.translate(textToTranslate)
            let outputText = result.targetText
            print("📤 Output (\(outputLang)): \"\(outputText)\"")

            await MainActor.run {
                translatedText = outputText
                isTranslating = false
                print("💫 UI Updated with translation")
            }

            // Speak the translated text using the dynamic output code
            speakText(outputText, language: outputCode)
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
             utterance.voice = AVSpeechSynthesisVoice(language: language) // Use dynamic code
             utterance.rate = AVSpeechUtteranceDefaultSpeechRate
             utterance.pitchMultiplier = 1.0

             print("🗣️ Speaking: \"\(text)\" in language \(language)")
             synthesizer.speak(utterance)
         } catch {
             print("🔴 Audio Session Configuration Error: \(error.localizedDescription)")
         }
     }
}

// Add a preview provider for the generic view
#Preview {
    // Provide example languages for the preview
    TranslatorView(sourceLanguage: .chinese, targetLanguage: .english)
}