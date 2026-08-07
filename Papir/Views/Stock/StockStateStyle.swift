//
//  StockStateStyle.swift
//  How a StockState looks, in one place so the list card and the detail screen
//  cannot say different things about the same number. In stock reads as the
//  normal ink of the app, out of stock reads orange because it is a thing to
//  act on rather than an error, and a negative count reads red because it can
//  only mean the record and the shelf have come apart. Orange rather than
//  yellow so it still carries against a white background and keeps enough
//  contrast for anyone reading it in daylight.
//  The pack total is coloured on its own scale: red only when the shelf is
//  actually empty, since red on a healthy total is the kind of alarm that
//  stops being read, and the warning amber once the total is down to the
//  number set in settings.
//  Used by: StockModelCard, StockModelDetailView.
//

import SwiftUI

extension StockState {
    var tint: Color {
        switch self {
        case .stocked:  return .primary
        case .low:      return Color(red: 0.90, green: 0.62, blue: 0.15)
        case .out:      return .orange
        case .negative: return .red
        }
    }

    var accent: Color {
        switch self {
        case .stocked:  return .primary.opacity(0.35)
        case .low:      return Color(red: 0.90, green: 0.62, blue: 0.15)
        case .out:      return .orange
        case .negative: return .red
        }
    }

    var label: String {
        switch self {
        case .stocked:  return L.t(.inStock)
        case .low:      return L.t(.lowStock)
        case .out:      return L.t(.outOfStock)
        case .negative: return L.t(.recount)
        }
    }

    var isFlagged: Bool {
        self != .stocked
    }
}

extension PackTotalState {
    var tint: Color {
        switch self {
        case .healthy: return .primary
        case .low:     return Color(red: 0.90, green: 0.62, blue: 0.15)
        case .empty:   return .red
        }
    }
}
