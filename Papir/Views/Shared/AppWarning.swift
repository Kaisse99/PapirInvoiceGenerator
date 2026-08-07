//
//  AppWarning.swift
//  The fourth thing the app's colours say. Ink is the default voice, blue is
//  shipped, red is a stock count that has gone wrong, and this is amber: look
//  at it, but nothing is broken. A breakdown that does not add up, a price
//  that disagrees with the shelf, an order that oversells, an invoice with no
//  PDF, a model with no price, iCloud that did not come up, a backup that has
//  never been made. All of those mean the same thing to the reader and so they
//  should be one colour.
//  They were seventeen separate calls to Color.orange across seven files
//  before this existed, which is how the palette drifted: system orange is
//  tuned for a red-blue iOS, sits loud against this app's ink, and could be
//  changed in one place and missed in six. Naming it makes it a decision.
//  Amber rather than the system's: pulled down and warmed in light so it does
//  not shout beside ink, lifted in dark so it stays legible on black.
//  fill and border are the same hue at the two opacities every amber plate in
//  the app was already using by hand.
//  Used by: InvoiceRowCard, ShipmentSheet, InvoiceRowItem, MovementLogView,
//  StockEntrySheets, StatisticsView, SettingsSheet.
//

import SwiftUI

enum AppWarning {
    static let tint = Color(
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.98, green: 0.69, blue: 0.28, alpha: 1)
                : UIColor(red: 0.84, green: 0.51, blue: 0.08, alpha: 1)
        }
    )

    static var fill: Color {
        tint.opacity(0.12)
    }

    static var border: Color {
        tint.opacity(0.5)
    }
}
