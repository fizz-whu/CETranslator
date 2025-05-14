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

// Facebook-inspired colors
let facebookBlue = Color(red: 23/255, green: 120/255, blue: 242/255) // #1778F2
let facebookBackgroundGray = Color(UIColor.systemGroupedBackground)
let facebookCardBackground = Color(UIColor.secondarySystemGroupedBackground)
let facebookSeparatorGray = Color(UIColor.systemGray4)

// New View for the Menu Label
struct LanguageMenuLabelView: View {
    let language: SupportedLanguage

    var body: some View {
        HStack {
            Text(language.flagEmoji)
            Text(language.rawValue)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary) // Changed from Color(.systemGray2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(facebookCardBackground)
        .cornerRadius(10)
        .foregroundColor(.primary) // Changed from Color(.label)
    }
}

// New View for the entire Language Selection Menu
struct LanguageSelectionMenu: View {
    @Binding var selectedLanguage: SupportedLanguage
    let allLanguages: [SupportedLanguage]

    var body: some View {
        Menu {
            ForEach(allLanguages) { language in
                Button {
                    selectedLanguage = language
                } label: {
                    HStack {
                        Text(language.flagEmoji)
                        Text(language.rawValue)
                            .foregroundColor(.primary) // Changed from Color(.primary)
                            .padding(.leading, 2)
                    }
                }
            }
        } label: {
            LanguageMenuLabelView(language: selectedLanguage)
        }
        // .accentColor(facebookBlue) // accentColor on Menu might not style the label as expected
    }
}

struct ContentView: View {
    @State private var sourceLanguage: SupportedLanguage = .chinese
    @State private var targetLanguage: SupportedLanguage = .english
    @State private var navigateToTranslator = false

    var body: some View {
        NavigationStack {
            ZStack {
                facebookBackgroundGray.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) { // Adjusted spacing
                    // Language Selection Section
                    HStack(spacing: 10) { // Use HStack for side-by-side pickers
                        LanguageSelectionMenu(selectedLanguage: $sourceLanguage, allLanguages: SupportedLanguage.allCases)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary) // Changed from Color(.systemGray2)

                        LanguageSelectionMenu(selectedLanguage: $targetLanguage, allLanguages: SupportedLanguage.allCases)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Removed Swap Button

                    Spacer()

                    // Start Translation Button
                    Button {
                        if sourceLanguage != targetLanguage {
                            navigateToTranslator = true
                        }
                    } label: {
                        Text("Start Translation")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(sourceLanguage == targetLanguage ? Color.gray : facebookBlue)
                            .cornerRadius(10)
                    }
                    .disabled(sourceLanguage == targetLanguage)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Translator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(facebookCardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToTranslator) {
                TranslatorView(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
            }
        }
    }
}

// Removed LanguagePickerRow as it's no longer used in this layout

// Keep the BounceButtonStyle if used elsewhere
// The BounceButtonStyle is not typically Facebook-like,
// but I'll keep it here if you use it elsewhere.
// If not, you can remove it.
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

