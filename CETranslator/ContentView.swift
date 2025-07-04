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
    case arabic = "العربية"
    case german = "Deutsch"
    case hindi = "हिन्दी"
    case russian = "Русский"
    case thai = "ไทย"
    case vietnamese = "Tiếng Việt"

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
        case .arabic: return "🇸🇦"
        case .german: return "🇩🇪"
        case .hindi: return "🇮🇳"
        case .russian: return "🇷🇺"
        case .thai: return "🇹🇭"
        case .vietnamese: return "🇻🇳"
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
        case .arabic: return "ar-SA"
        case .german: return "de-DE"
        case .hindi: return "hi-IN"
        case .russian: return "ru-RU"
        case .thai: return "th-TH"
        case .vietnamese: return "vi-VN"
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
        case .arabic: return "ar"
        case .german: return "de"
        case .hindi: return "hi"
        case .russian: return "ru"
        case .thai: return "th"
        case .vietnamese: return "vi"
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
        case .arabic: return "بدء الترجمة"
        case .german: return "Übersetzung starten"
        case .hindi: return "अनुवाद शुरू करें"
        case .russian: return "Начать перевод"
        case .thai: return "เริ่มแปล"
        case .vietnamese: return "Bắt đầu dịch"
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
        case .arabic: return "اختر اللغة"
        case .german: return "Sprache auswählen"
        case .hindi: return "भाषा चुनें"
        case .russian: return "Выбрать язык"
        case .thai: return "เลือกภาษา"
        case .vietnamese: return "Chọn ngôn ngữ"
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
        case .arabic: return "ستظهر الترجمة هنا"
        case .german: return "Die Übersetzung wird hier angezeigt"
        case .hindi: return "अनुवाद यहाँ दिखेगा"
        case .russian: return "Перевод появится здесь"
        case .thai: return "การแปลจะปรากฏที่นี่"
        case .vietnamese: return "Bản dịch sẽ xuất hiện ở đây"
        }
    }

    // Text format for "Tap & Hold {LanguageName} button..." placeholder
    // The "%@" will be replaced by the actual language name (e.g., "中文", "English")
    var tapAndHoldButtonPlaceholderFormat: String { // This will now be the general instruction
        switch self {
        case .chinese: return "长按麦克风说话 🎤"
        case .english: return "Press & Hold microphone to speak 🎤"
        case .japanese: return "マイクを長押しして話す 🎤"
        case .spanish: return "Mantén presionado el micrófono para hablar 🎤"
        case .italian: return "Tieni premuto il microfono per parlare 🎤"
        case .korean: return "마이크를 길게 눌러 말하세요 🎤"
        case .french: return "Maintenez le micro pour parler 🎤"
        case .portuguese: return "Pressione e segure o microfone para falar 🎤"
        case .arabic: return "اضغط مع الاستمرار على الميكروفون للتحدث 🎤"
        case .german: return "Mikrofon gedrückt halten zum Sprechen 🎤"
        case .hindi: return "बोलने के लिए माइक्रोफ़ोन दबाए रखें 🎤"
        case .russian: return "Удерживайте микрофон для речи 🎤"
        case .thai: return "กดค้างไมโครโฟนเพื่อพูด 🎤"
        case .vietnamese: return "Nhấn giữ micrô để nói 🎤"
        }
    }

    // Text format for "Tap and hold to speak {LanguageName}" label
    // The "%@" will be replaced by the actual language name
    var tapAndHoldToSpeakLabelFormat: String { // Note: This property might be better named e.g., tapAndHoldInstructionText now
        switch self {
        case .chinese: return "长按说话"
        case .english: return "Press & Hold to speak"
        case .japanese: return "長押しして話す"
        case .spanish: return "Mantén presionado para hablar"
        case .italian: return "Tieni premuto per parlare"
        case .korean: return "길게 눌러 말하기"
        case .french: return "Maintenez pour parler"
        case .portuguese: return "Pressione e segure para falar"
        case .arabic: return "اضغط مع الاستمرار للتحدث"
        case .german: return "Gedrückt halten zum Sprechen"
        case .hindi: return "बोलने के लिए दबाए रखें"
        case .russian: return "Удерживайте для речи"
        case .thai: return "กดค้างเพื่อพูด"
        case .vietnamese: return "Nhấn giữ để nói"
        }
    }

    // Add this new property:
    var localizedTranslateWord: String {
        switch self {
        case .english:
            return "Go" // Short version for English
        case .chinese:
            return "译" // Short version for Chinese
        case .spanish:
            return "Ir" // Short version for Spanish
        case .japanese:
            return "訳" // Short version for Japanese
        case .italian:
            return "Vai" // Short version for Italian
        case .korean:
            return "역" // Short version for Korean
        case .french:
            return "Go" // Short version for French
        case .portuguese:
            return "Ir" // Short version for Portuguese
        case .arabic:
            return "ترجم" // Keep as is (already short)
        case .german:
            return "Los" // Short version for German
        case .hindi:
            return "चलो" // Short version for Hindi
        case .russian:
            return "Иди" // Short version for Russian
        case .thai:
            return "แปล" // Keep as is (already short)
        case .vietnamese:
            return "Đi" // Short version for Vietnamese
        // Add cases for all your supported languages
        }
    }
    
    // Text for "Typing option is available as well" placeholder
    var speakOrTypeHerePlaceholder: String {
        switch self {
        case .chinese:
            return "也可以打字输入"
        case .english:
            return "Typing option is available as well"
        case .japanese:
            return "タイピングオプションもあります"
        case .spanish:
            return "La opción de escribir también está disponible"
        case .italian:
            return "È disponibile anche l'opzione di digitazione"
        case .korean:
            return "타이핑 옵션도 사용 가능합니다"
        case .french:
            return "L'option de frappe est également disponible"
        case .portuguese:
            return "A opção de digitação também está disponível"
        case .arabic:
            return "خيار الكتابة متاح أيضاً"
        case .german:
            return "Die Tippoption ist ebenfalls verfügbar"
        case .hindi:
            return "टाइपिंग विकल्प भी उपलब्ध है"
        case .russian:
            return "Опция набора текста также доступна"
        case .thai:
            return "ตัวเลือกการพิมพ์ก็มีให้ใช้งานด้วย"
        case .vietnamese:
            return "Tùy chọn gõ phím cũng có sẵn"
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
            return "\(localizedText) | \(englishText)"
        }
    }

    // Computed property for the navigation bar title
    private var navigationBarTitleText: String {
        if sourceLanguage == .english {
            return sourceLanguage.selectLanguageTitleText
        } else {
            return "\(sourceLanguage.selectLanguageTitleText) | Select Language"
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

