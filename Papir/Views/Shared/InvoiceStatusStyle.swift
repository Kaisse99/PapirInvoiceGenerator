//
//  InvoiceStatusStyle.swift
//  How an invoice's status looks and reads, in one place so the toolbar icon,
//  the explanation alert, and the list card cannot describe the same invoice
//  differently. Draft is blue because it is a normal working state rather than
//  a warning; shipped is a deep green rather than the system's bright one, so
//  it reads as settled instead of shouting.
//  Used by: InvoiceDetailView, InvoiceRowItem.
//

import SwiftUI

extension InvoiceStatus {
    var tint: Color {
        switch self {
        case .draft:   return Color(red: 0.20, green: 0.48, blue: 0.90)
        case .shipped: return Color(red: 0.13, green: 0.50, blue: 0.29)
        }
    }

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
