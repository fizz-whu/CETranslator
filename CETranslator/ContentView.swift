import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ChineseEnglishTranslatorView()
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

