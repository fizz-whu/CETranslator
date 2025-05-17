import SwiftUI

// Define the SupportedLanguage enum here
enum SupportedLanguage: String, CaseIterable, Identifiable, Hashable {
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

    // Text for the "Start Translation" button in this language
    var startTranslationButtonText: String {
        switch self {
        case .chinese: return "开始翻译"
        case .english: return "Start Translation"
        case .japanese: return "翻訳を開始"
        case .spanish: return "Iniciar Traducción"
        case .italian: return "Inizia Traduzione"
        case .korean: return "번역 시작"
        case .french: return "Commencer la Traduction"
        case .portuguese: return "Iniciar Tradução"
        }
    }

    // Text for the "Select Language" navigation title in this language
    var selectLanguageTitleText: String {
        switch self {
        case .chinese: return "选择语言"
        case .english: return "Select Language"
        case .japanese: return "言語を選択"
        case .spanish: return "Seleccionar Idioma"
        case .italian: return "Seleziona Lingua"
        case .korean: return "언어 선택"
        case .french: return "Sélectionner la Langue"
        case .portuguese: return "Selecionar Idioma"
        }
    }

    // Text for the "Translation will appear here" placeholder
    var translationPlaceholderText: String {
        switch self {
        case .chinese: return "翻译将显示在此处"
        case .english: return "Translation will appear here"
        case .japanese: return "翻訳はここに表示されます"
        case .spanish: return "La traducción aparecerá aquí"
        case .italian: return "La traduzione apparirà qui"
        case .korean: return "번역이 여기에 표시됩니다"
        case .french: return "La traduction apparaîtra ici"
        case .portuguese: return "A tradução aparecerá aqui"
        }
    }

    // Text format for "Tap & Hold {LanguageName} button..." placeholder
    // The "%@" will be replaced by the actual language name (e.g., "中文", "English")
    var tapAndHoldButtonPlaceholderFormat: String { // This will now be the general instruction
        switch self {
        case .chinese: return "点击并按住下方的麦克风按钮讲话，松开以翻译"
        case .english: return "Tap and hold a microphone button below to speak, then release to translate."
        case .japanese: return "下のマイクボタンを長押しして話し、離して翻訳します"
        case .spanish: return "Mantén presionado un botón de micrófono abajo para hablar, luego suelta para traducir."
        case .italian: return "Tocca e tieni premuto un pulsante del microfono in basso per parlare, quindi rilascia per tradurre."
        case .korean: return "아래 마이크 버튼을 길게 눌러 말하고 손을 떼면 번역됩니다."
        case .french: return "Appuyez et maintenez un bouton de microphone ci-dessous pour parler, puis relâchez pour traduire."
        case .portuguese: return "Toque e segure um botão de microfone abaixo para falar e solte para traduzir."
        }
    }

    // Text format for "Tap and hold to speak {LanguageName}" label
    // The "%@" will be replaced by the actual language name
    var tapAndHoldToSpeakLabelFormat: String { // Note: This property might be better named e.g., tapAndHoldInstructionText now
        switch self {
        case .chinese: return "点击并按住下方的麦克风按钮讲话，松开以翻译"
        case .english: return "Tap and hold a microphone button below to speak, then release to translate."
        case .japanese: return "下のマイクボタンを長押しして話し、離して翻訳します"
        case .spanish: return "Mantén presionado un botón de micrófono abajo para hablar, luego suelta para traducir."
        case .italian: return "Tocca e tieni premuto un pulsante del microfono in basso per parlare, quindi rilascia per tradurre."
        case .korean: return "아래 마이크 버튼을 길게 눌러 말하고 손을 떼면 번역됩니다."
        case .french: return "Appuyez et maintenez un bouton de microphone ci-dessous pour parler, puis relâchez pour traduire."
        case .portuguese: return "Toque e segure um botão de microfone abaixo para falar e solte para traduzir."
        }
    }

    // Add this new property:
    var localizedTranslateWord: String {
        switch self {
        case .english:
            return "Translate" // For English, it's just "Translate"
        case .chinese:
            return "翻译" // Example for Chinese
        case .spanish:
            return "Traducir" // Example for Spanish
        case .japanese:
            return "翻訳" // Example for Japanese
        case .italian:
            return "Traduci" // Example for Italian
        case .korean:
            return "번역" // Example for Korean
        case .french:
            return "Traduire" // Example for French
        case .portuguese:
            return "Traduzir" // Example for Portuguese
        // Add cases for all your supported languages
        }
    }
}

// Facebook-inspired colors
let facebookBlue = Color(red: 23/255, green: 120/255, blue: 242/255) // #1778F2
let facebookBackgroundGray = Color(UIColor.systemGroupedBackground)
let facebookCardBackground = Color(UIColor.secondarySystemGroupedBackground)
let facebookSeparatorGray = Color(UIColor.systemGray4)

// New View for the Menu Label (displays the selected language)
struct LanguageMenuLabelView: View {
    let language: SupportedLanguage

    var body: some View {
        HStack {
            Text(language.rawValue)
            Text(language.flagEmoji) 
                .padding(.leading, 4) 
            Spacer()
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(facebookCardBackground)
        .cornerRadius(10)
        .foregroundColor(.primary)
    }
}

// New dedicated View for each item in the dropdown menu
struct LanguageMenuItemRow: View {
    let language: SupportedLanguage

    var body: some View {
        HStack {
            Text("\(language.flagEmoji) \(language.rawValue)") // Concatenate flag and name in one Text view
            // Spacer() // Keep Spacer commented out or remove if not needed for alignment
        }
        // .contentShape(Rectangle()) // Keep commented out or remove
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
                    LanguageMenuItemRow(language: language) // Use the new dedicated view
                }
            }
        } label: {
            LanguageMenuLabelView(language: selectedLanguage)
        }
        // .accentColor(facebookBlue)
    }
}

struct ContentView: View {
    @State private var sourceLanguage: SupportedLanguage = .chinese
    @State private var targetLanguage: SupportedLanguage = .english
    @State private var navigateToTranslator = false

    // Computed property for the button's display text
    private var startTranslationButtonDisplayText: String {
        let localizedText = sourceLanguage.startTranslationButtonText
        if sourceLanguage == .english {
            return localizedText
        } else {
            // Add English fallback, dynamically fetched
            let englishText = SupportedLanguage.english.startTranslationButtonText
            return "\(localizedText) (\(englishText))"
        }
    }

    // Computed property for the navigation bar title
    private var navigationBarTitleText: String {
        if sourceLanguage == .english {
            return sourceLanguage.selectLanguageTitleText
        } else {
            return "\(sourceLanguage.selectLanguageTitleText) (Select Language)"
        }
    }

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
                        Text(startTranslationButtonDisplayText) // Use the updated computed property here
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
            .navigationTitle(navigationBarTitleText) // Use the new computed property for the title
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

