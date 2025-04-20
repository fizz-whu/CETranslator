//
//  ContentView.swift
//  CETranslator
//
//  Created by Chee on 3/28/25.
//

import SwiftUI

struct ContentView: View {
    // Access the view model from the environment
    @EnvironmentObject var viewModel: SpeechTranslationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("CETranslator")
                    .font(.largeTitle)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized Text:")
                        .font(.headline)
                    Text(viewModel.recognizedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translated Text:")
                        .font(.headline)
                    Text(viewModel.translatedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.startRecording(sourceLanguage: "English")
                    }) {
                        Label("Record English", systemImage: "mic.fill")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    
                    Button(action: {
                        viewModel.startRecording(sourceLanguage: "Chinese")
                    }) {
                        Label("Record Chinese", systemImage: "mic.fill")
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .navigationTitle("CETranslator")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SpeechTranslationViewModel())
}

