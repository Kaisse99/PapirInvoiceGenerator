//
//  StockStateStyle.swift
//  How a StockState looks, in one place so the list card and the detail screen
//  cannot say different things about the same number. Everything short of
//  stocked is red now, at three strengths of the one hue: soft for a colour
//  running low, mid at zero, and a plain full red once the count has gone
//  negative and the record and the shelf have come apart. One hue rather than
//  amber then red, because every one of these is the same sentence, there is
//  not enough of this, and only the degree changes. The ramp runs by how much
//  colour is in it rather than by how dark it is, since a deep blood red at
//  the bottom read as alarming out of all proportion to a miscount.
//  The pack total is coloured on the same ramp but from the total alone, so a
//  full shelf with one colour at zero is not painted as a problem.
//  Used by: StockModelCard, StockModelDetailView.
//

import SwiftUI

enum StockRed {
    static let soft = Color(red: 0.90, green: 0.62, blue: 0.58)
    static let mid = Color(red: 0.86, green: 0.47, blue: 0.44)
    static let full = Color(red: 0.79, green: 0.30, blue: 0.29)
}

extension StockState {
    var tint: Color {
        switch self {
        case .stocked:  return .primary
        case .low:      return StockRed.soft
        case .out:      return StockRed.mid
        case .negative: return StockRed.full
        }
    }

    var accent: Color {
        switch self {
        case .stocked:  return .primary.opacity(0.35)
        case .low:      return StockRed.soft
        case .out:      return StockRed.mid
        case .negative: return StockRed.full
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
        case .low:     return StockRed.soft
        case .empty:   return StockRed.full
        }
    }
}
