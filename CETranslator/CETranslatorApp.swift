//
//  CETranslatorApp.swift
//  CETranslator
//
//  Created by Chee on 3/28/25.
//

import SwiftUI

@main
struct CETranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SpeechTranslationViewModel())
        }
    }
}

