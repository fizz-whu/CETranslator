import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack { // Or NavigationView
            VStack(spacing: 30) {
                // Update the destination for the first link
                NavigationLink {
                    EnglishToChineseView() // Use the new view name
                } label: {
                    Label("EN -> 中文", systemImage: "arrow.right.circle")
                }

                // Update the destination for the second link
                NavigationLink {
                    ChineseToEnglishView() // Use the new view name
                } label: {
                    Label("中文 -> EN", systemImage: "arrow.left.arrow.right.circle") // Label for the link
                }

                Spacer() // Optional: Pushes links to the top
            }
            .padding()
            .navigationTitle("Translators") // Set a title for the main view
        }
    }
} // End of ContentView struct

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

