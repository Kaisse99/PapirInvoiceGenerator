//
//  InvoiceStatusStyle.swift
//  How an invoice's status looks and reads, in one place so the toolbar icon,
//  the explanation alert, and the list card cannot describe the same invoice
//  differently. A draft is drawn in ink, near black on a light screen and near
//  white on a dark one but never either exactly, because a draft is the
//  ordinary state of an invoice and ordinary is what the rest of the app is
//  written in. Shipped takes the blue, since it is the one thing that has
//  actually happened to the paper and deserves the only colour on the row.
//  The colours are built as dynamic UIColors rather than picked per screen, so
//  a caller cannot forget which appearance it is drawing into.
//  plateTint is the same pair banked down for the strip behind a list row,
//  where a full strength fill glares, and plateText is whatever reads on top
//  of it, which is the inverse of the ink and white on the blue.
//  Used by: InvoiceDetailView, InvoiceRowItem.
//

import SwiftUI

extension InvoiceStatus {
    var tint: Color {
        switch self {
        case .draft:   return Self.ink
        case .shipped: return Self.blue
        }
    }

    var plateTint: Color {
        switch self {
        case .draft:   return Self.plateInk
        case .shipped: return Self.plateBlue
        }
    }

    var plateText: Color {
        switch self {
        case .draft:   return Self.plateInkText
        case .shipped: return .white
        }
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    private static let ink = adaptive(
        light: UIColor(white: 0.14, alpha: 1),
        dark: UIColor(white: 0.88, alpha: 1)
    )

    private static let blue = Color(red: 0.20, green: 0.48, blue: 0.90)

    private static let plateInk = adaptive(
        light: UIColor(white: 0.16, alpha: 1),
        dark: UIColor(white: 0.95, alpha: 1)
    )

    private static let plateInkText = adaptive(
        light: UIColor(white: 0.97, alpha: 1),
        dark: UIColor(white: 0.08, alpha: 1)
    )

    private static let plateBlue = adaptive(
        light: UIColor(red: 0.20, green: 0.48, blue: 0.90, alpha: 1),
        dark: UIColor(red: 0.13, green: 0.30, blue: 0.57, alpha: 1)
    )

    var icon: String {
        switch self {
        case .draft:   return "pencil.circle.fill"
        case .shipped: return "checkmark.seal.fill"
        }
    }

    var actionIcon: String {
        switch self {
        case .draft:   return "shippingbox.fill"
        case .shipped: return "arrow.uturn.backward"
        }
    }

    var label: String {
        L.t(self == .shipped ? .shipped : .draft)
    }

    var actionLabel: String {
        L.t(self == .shipped ? .returnToDraft : .markShipped)
    }

    var explanation: String {
        L.t(self == .shipped ? .shippedExplained : .draftExplained)
    }
}
