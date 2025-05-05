import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            // Use a List for standard navigation rows
            List {
                NavigationLink("English <-> Chinese Translator") {
                    ChineseEnglishTranslatorView()
                }
                NavigationLink("Chinese <-> Japanese Translator") {
                    ChineseJapaneseTranslatorView()
                }
                NavigationLink("Chinese <-> Spanish Translator") {
                    ChineseSpanishTranslatorView()
                }
                // Add link for Chinese <-> Italian
                NavigationLink("Chinese <-> Italian Translator") {
                    ChineseItalianTranslatorView()
                }
                // Add link for Chinese <-> Korean
                NavigationLink("Chinese <-> Korean Translator") {
                    ChineseKoreanTranslatorView()
                }
                // Add link for Chinese <-> French
                NavigationLink("Chinese <-> French Translator") {
                    ChineseFrenchTranslatorView()
                }
                // Add link for Chinese <-> Portuguese
                NavigationLink("Chinese <-> Portuguese Translator") {
                    ChinesePortugueseTranslatorView()
                }
            }
            .navigationTitle("Translators") // Add a title to the main page
        }
    }
}

// Add these definitions here (if not already present)
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

