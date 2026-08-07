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
//  moneyRounded pins a price to two decimal places at the moments one enters
//  the store. Money stays Double rather than Decimal on purpose: retyping a
//  stored column is exactly the silent-null migration hazard the schema plan
//  exists to prevent, and CloudKit mirroring has no native Decimal. At
//  hryvnia sizes with two-decimal prices and integer quantities the float
//  error sits under a millionth of a kopiyka; rounding at the boundaries
//  keeps it from ever accumulating into a displayed figure.
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

extension Double {
    var moneyRounded: Double {
        (self * 100).rounded() / 100
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
