import SwiftUI

// Define the SupportedLanguage enum here
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case chinese = "中文"
    case english = "English"
    case japanese = "日本語"
    case spanish = "Español"
    case italian = "Italiano"
    case korean = "한국어"
    case french = "Français"
    case portuguese = "Português"

    var id: String { self.rawValue }

    // Add flag emoji property
    var flagEmoji: String {
        switch self {
        case .chinese: return "🇨🇳"
        case .english: return "🇺🇸" // Or 🇬🇧 for UK English
        case .japanese: return "🇯🇵"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .korean: return "🇰🇷"
        case .french: return "🇫🇷"
        case .portuguese: return "🇵🇹" // Or 🇧🇷 for Brazilian Portuguese
        }
    }

    // Language code for Speech Recognition (SFSpeechRecognizer)
    var languageCode: String {
        switch self {
        case .chinese: return "zh-Hans" // Use zh-Hans for Simplified Chinese
        case .english: return "en-US"
        case .japanese: return "ja-JP"
        case .spanish: return "es-ES"
        case .italian: return "it-IT"
        case .korean: return "ko-KR"
        case .french: return "fr-FR"
        case .portuguese: return "pt-PT"
        }
    }

    // Locale identifier for Translation framework (Locale.Language)
    var translationLocaleIdentifier: String {
        switch self {
        case .chinese: return "zh-Hans" // Use zh-Hans for Translation
        case .english: return "en"
        case .japanese: return "ja"
        case .spanish: return "es"
        case .italian: return "it"
        case .korean: return "ko"
        case .french: return "fr"
        case .portuguese: return "pt"
        }
    }
}


struct ContentView: View {
    // State variables to hold the selected languages
    @State private var sourceLanguage: SupportedLanguage = .chinese
    @State private var targetLanguage: SupportedLanguage = .english
    @State private var navigateToTranslator = false // State to trigger navigation

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Select Languages")
                    .font(.title2)
                    .padding(.top)

                // Picker for Source Language
                Picker("From:", selection: $sourceLanguage) {
                    ForEach(SupportedLanguage.allCases) { language in
                        // Display flag and name
                        Text(language.flagEmoji + " " + language.rawValue).tag(language)
                    }
                }
                .pickerStyle(.menu) // Or .wheel, .segmented
                .padding(.horizontal)

                // Swap Button (Optional but helpful)
                Button {
                    let temp = sourceLanguage
                    sourceLanguage = targetLanguage
                    targetLanguage = temp
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title)
                }

                // Picker for Target Language
                Picker("To:", selection: $targetLanguage) {
                    ForEach(SupportedLanguage.allCases) { language in
                        // Display flag and name
                        Text(language.flagEmoji + " " + language.rawValue).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                Spacer() // Pushes the button to the bottom

                // Navigation Button - use a symbol instead of text
                Button {
                    // Trigger navigation if languages are different
                    if sourceLanguage != targetLanguage {
                        navigateToTranslator = true
                    } else {
                        // Optionally show an alert if languages are the same
                        print("Cannot translate: Source and target languages are the same.")
                    }
                } label: {
                    // Use a play symbol
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle) // Make the symbol larger
                        .foregroundStyle(.white) // Ensure visibility on prominent button
                }
                .buttonStyle(.borderedProminent)
                .disabled(sourceLanguage == targetLanguage) // Disable if same language
                .padding()

            }
            .navigationTitle("Translator Setup")
            // Use the new generic TranslatorView
            .navigationDestination(isPresented: $navigateToTranslator) {
                TranslatorView(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            }
        }
    }

    // No longer need isPairSupported or translatorViewFor functions
}

// Keep the BounceButtonStyle if used elsewhere
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BounceButtonStyle {
    static var bouncy: Self { .init() }
}


#Preview {
    ContentView()
}

