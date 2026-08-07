//
//  AppSettings.swift
//  The few preferences that outlive a launch, kept in UserDefaults because
//  they are choices rather than data: the app's language, the currency every
//  amount is written in, and the two numbers a fresh invoice row starts with.
//  A pack is nearly always six, so typing that once here beats retyping it on
//  every row, and a stored zero means the field starts empty instead.
//  Reads are plain statics so any layer can ask; writes go through @AppStorage
//  in the settings sheet, which is what makes a change land immediately.
//  iCloud sync is stored here too, alongside a flag the app writes when a
//  CloudKit container fails to open, so the settings screen can report that
//  rather than leaving the toggle looking switched on and doing nothing.
//  Used by: PapirApp, SettingsSheet, Localization, InvoiceRowDraft, every money
//  label.
//

import Foundation

enum AppSettings {
    static let unitsKey = "defaultUnitCount"
    static let itemsPerUnitKey = "defaultItemsPerUnit"
    static let languageKey = "appLanguage"
    static let currencyKey = "appCurrency"
    static let lowStockKey = "lowStockThreshold"
    static let cloudSyncKey = "iCloudSyncEnabled"
    static let cloudFailureKey = "iCloudSyncUnavailable"
    static let cloudContainerID = "iCloud.com.kaissenberg.Papir"

    static let fallbackUnits = 1
    static let fallbackItemsPerUnit = 6
    static let fallbackLowStock = 2

    static var defaultUnits: Int {
        UserDefaults.standard.object(forKey: unitsKey) as? Int ?? fallbackUnits
    }

    static var defaultItemsPerUnit: Int {
        UserDefaults.standard.object(forKey: itemsPerUnitKey) as? Int ?? fallbackItemsPerUnit
    }

    static var defaultUnitsText: String {
        fieldText(defaultUnits)
    }

    static var defaultItemsPerUnitText: String {
        fieldText(defaultItemsPerUnit)
    }

    static var lowStockThreshold: Int {
        UserDefaults.standard.object(forKey: lowStockKey) as? Int ?? fallbackLowStock
    }

    static var cloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: cloudSyncKey)
    }

    static var cloudSyncUnavailable: Bool {
        UserDefaults.standard.bool(forKey: cloudFailureKey)
    }

    static func recordCloudSyncFailure(_ failed: Bool) {
        UserDefaults.standard.set(failed, forKey: cloudFailureKey)
    }

    static var language: AppLanguage {
        guard let raw = UserDefaults.standard.string(forKey: languageKey),
              let language = AppLanguage(rawValue: raw) else {
            return .english
        }
        return language
    }

    static var currency: AppCurrency {
        guard let raw = UserDefaults.standard.string(forKey: currencyKey),
              let currency = AppCurrency(rawValue: raw) else {
            return .hryvnia
        }
        return currency
    }

    static var currencySymbol: String {
        currency.symbol
    }

    private static func fieldText(_ value: Int) -> String {
        value > 0 ? "\(value)" : ""
    }
}
