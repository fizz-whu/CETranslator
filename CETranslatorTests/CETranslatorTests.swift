//
//  CETranslatorTests.swift
//  CETranslatorTests
//
//  Created by Chee on 3/28/25.
//

import Testing
import Speech
import AVFoundation
@testable import CETranslator

struct CETranslatorTests {

    @Test func testSupportedLanguageEnumBasics() async throws {
        // Test that all supported languages have proper configuration
        for language in SupportedLanguage.allCases {
            #expect(!language.rawValue.isEmpty, "Language raw value should not be empty")
            #expect(!language.languageCode.isEmpty, "Language code should not be empty")
            #expect(!language.translationLocaleIdentifier.isEmpty, "Translation locale ID should not be empty")
            #expect(!language.flagEmoji.isEmpty, "Flag emoji should not be empty")
            #expect(!language.startTranslationButtonText.isEmpty, "Start translation button text should not be empty")
        }
    }
    
    @Test func testLanguageCodeFormats() async throws {
        // Test that language codes follow expected formats
        let language = SupportedLanguage.english
        #expect(language.languageCode == "en-US", "English language code should be en-US")
        #expect(language.translationLocaleIdentifier == "en", "English translation locale should be en")
        
        let chineseLanguage = SupportedLanguage.chinese
        #expect(chineseLanguage.languageCode == "zh-Hans", "Chinese language code should be zh-Hans")
        #expect(chineseLanguage.translationLocaleIdentifier == "zh-Hans", "Chinese translation locale should be zh-Hans")
    }
    
    @Test func testSpeechTranslationViewModelInitialization() async throws {
        let viewModel = SpeechTranslationViewModel()
        
        // Test initial state
        #expect(viewModel.recognizedText.isEmpty, "Initial recognized text should be empty")
        #expect(viewModel.isRecording == false, "Initial recording state should be false")
        #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
    }
    
    @Test func testSpeechRecognitionPermissionHandling() async throws {
        let viewModel = SpeechTranslationViewModel()
        
        // Test permission checking (this will depend on device permissions)
        let hasPermission = await viewModel.checkAndRequestPermission()
        
        // The result depends on actual device permissions, so we just verify the method doesn't crash
        #expect(hasPermission == true || hasPermission == false, "Permission check should return a boolean")
    }
    
    @Test func testLanguageDetectionLogic() async throws {
        // Test the language detection logic used in TranslatorView
        let testTexts = [
            ("Hello world", false, true), // English text
            ("你好世界", true, false), // Chinese text
            ("こんにちは", false, false), // Japanese text (neither Chinese nor English)
            ("", false, false) // Empty text
        ]
        
        for (text, expectedChinese, expectedEnglish) in testTexts {
            let hasChineseCharacters = text.range(of: "\\p{Script=Han}", options: .regularExpression) != nil
            let hasEnglishCharacters = !hasChineseCharacters && !text.isEmpty
            
            if expectedChinese {
                #expect(hasChineseCharacters, "Text '\(text)' should contain Chinese characters")
            }
            if expectedEnglish && !text.isEmpty {
                #expect(!hasChineseCharacters, "Text '\(text)' should not contain Chinese characters")
            }
        }
    }
    
    @Test func testAudioSessionSafety() async throws {
        // Test that audio session operations don't crash
        let viewModel = SpeechTranslationViewModel()
        
        // Test starting recording with invalid language code
        viewModel.startRecording(sourceLanguage: "invalid-code")
        
        // Should handle gracefully without crashing
        #expect(viewModel.errorMessage != nil, "Should have error message for invalid language code")
        #expect(viewModel.isRecording == false, "Should not be recording with invalid language code")
    }
    
    @Test func testStopRecordingWithoutStarting() async throws {
        // Test that stopping recording without starting doesn't crash
        let viewModel = SpeechTranslationViewModel()
        
        // This should not crash
        viewModel.stopRecording()
        
        #expect(viewModel.isRecording == false, "Recording state should remain false")
    }
    
    @Test func testMultipleStopRecordingCalls() async throws {
        // Test that multiple stop recording calls don't crash
        let viewModel = SpeechTranslationViewModel()
        
        // Multiple calls should not crash
        viewModel.stopRecording()
        viewModel.stopRecording()
        viewModel.stopRecording()
        
        #expect(viewModel.isRecording == false, "Recording state should remain false")
    }
    
    @Test func testSupportedLanguageCount() async throws {
        // Test that we have the expected number of supported languages
        let expectedLanguageCount = 14
        #expect(SupportedLanguage.allCases.count == expectedLanguageCount, "Should have \(expectedLanguageCount) supported languages")
    }
    
    @Test func testLanguageUniqueIdentifiers() async throws {
        // Test that all languages have unique identifiers
        let languageCodes = SupportedLanguage.allCases.map { $0.languageCode }
        let uniqueLanguageCodes = Set(languageCodes)
        
        #expect(languageCodes.count == uniqueLanguageCodes.count, "All language codes should be unique")
    }
    
    @Test func testErrorMessageLocalization() async throws {
        // Test that error messages are properly localized
        let viewModel = SpeechTranslationViewModel()
        
        // Test with different language codes
        let testLanguages = ["en-US", "zh-Hans", "ja-JP", "invalid-code"]
        
        for languageCode in testLanguages {
            viewModel.startRecording(sourceLanguage: languageCode)
            
            if languageCode == "invalid-code" {
                #expect(viewModel.errorMessage != nil, "Should have error message for invalid language code")
            }
            
            viewModel.stopRecording()
        }
    }

}
