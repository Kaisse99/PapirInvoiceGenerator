//
//  AppCurrency.swift
//  The currency every amount in the app and on the PDF is written in. Chosen
//  in settings rather than taken from the phone's region, because the person
//  invoicing and the person being invoiced are often in different countries
//  and only one of those matters. The symbol is all that is stored; there is
//  no conversion anywhere, an invoice is written in one currency and stays in
//  it.
//  PriceText sits here because a price is written two ways and both belong
//  next to the currency: display for reading, which groups thousands and drops
//  trailing zeros, and editable for putting back into a text field, which must
//  stay something Double(_:) can parse and so never carries separators.
//  Used by: SettingsSheet, the invoice screens, the stock screens, PDFGenerator.
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

enum PriceText {
    private static let displayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    static func display(_ value: Double) -> String {
        displayFormatter.string(from: NSNumber(value: value)) ?? editable(value)
    }

    static func editable(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return "\(value)"
    }
}
