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

struct ContentView: View {
    @State private var sourceLanguage: SupportedLanguage = .chinese
    @State private var targetLanguage: SupportedLanguage = .english
    @State private var navigateToTranslator = false

    var body: some View {
        NavigationStack {
            ZStack {
                facebookBackgroundGray.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Language Selection Section
                    VStack(spacing: 0) {
                        LanguagePickerRow(
                            label: "Translate From",
                            selectedLanguage: $sourceLanguage,
                            allLanguages: SupportedLanguage.allCases
                        )
                        
                        Divider()
                            .background(facebookSeparatorGray)
                            .padding(.leading, 16)

                        LanguagePickerRow(
                            label: "Translate To",
                            selectedLanguage: $targetLanguage,
                            allLanguages: SupportedLanguage.allCases
                        )
                    }
                    .background(facebookCardBackground)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Swap Button
                    Button {
                        withAnimation {
                            let temp = sourceLanguage
                            sourceLanguage = targetLanguage
                            targetLanguage = temp
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(facebookBlue)
                            .padding()
                            .background(facebookCardBackground)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.vertical, 20)


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

struct LanguagePickerRow: View {
    var label: String
    @Binding var selectedLanguage: SupportedLanguage
    var allLanguages: [SupportedLanguage]

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(Color(.label))
            Spacer()
            Picker(label, selection: $selectedLanguage) {
                ForEach(allLanguages) { language in
                    HStack {
                        Text(language.flagEmoji)
                        Text(language.rawValue)
                    }.tag(language)
                }
            }
            .pickerStyle(.menu)
            .accentColor(facebookBlue) // Styles the picker's chevron
        }
        .padding(.horizontal)
        .frame(height: 50)
    }
}

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

