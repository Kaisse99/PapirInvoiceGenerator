//
//  AppCurrency.swift
//  The currency every amount in the app and on the PDF is written in. Chosen
//  in settings rather than taken from the phone's region, because the person
//  invoicing and the person being invoiced are often in different countries
//  and only one of those matters. The symbol is all that is stored; there is
//  no conversion anywhere, an invoice is written in one currency and stays in
//  it.
//  Used by: SettingsSheet, the invoice screens, PDFGenerator.
//

import Foundation

enum AppCurrency: String, CaseIterable, Identifiable {
    case hryvnia
    case zloty
    case rouble
    case dollar

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .hryvnia: return "₴"
        case .zloty:   return "zł"
        case .rouble:  return "₽"
        case .dollar:  return "$"
        }
    }

    var code: String {
        switch self {
        case .hryvnia: return "UAH"
        case .zloty:   return "PLN"
        case .rouble:  return "RUB"
        case .dollar:  return "USD"
        }
    }
}
