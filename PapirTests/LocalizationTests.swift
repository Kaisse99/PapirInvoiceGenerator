//
//  LocalizationTests.swift
//  Every key must exist in every table, because a missing translation falls
//  back to English silently and nobody notices until a Ukrainian user is
//  reading English in the middle of their own language. This is the test that
//  turns that silence into a red build, and it is why the tables are internal
//  rather than private.
//

import Testing
@testable import Papir

struct LocalizationTests {
    @Test func everyKeyIsTranslatedInEveryLanguage() {
        for key in LKey.allCases {
            #expect(L.ukrainian[key] != nil, "ukrainian is missing \(key)")
            #expect(L.russian[key] != nil, "russian is missing \(key)")
            #expect(L.polish[key] != nil, "polish is missing \(key)")
        }
    }

    @Test func englishFallsBackToTheRawValue() {
        #expect(L.t(.invoice, .english) == "Invoice")
    }

    @Test func everyAppLanguageMapsToAPDFLanguage() {
        for language in AppLanguage.allCases {
            _ = language.pdfLanguage
            #expect(!language.displayName.isEmpty)
        }
    }
}
