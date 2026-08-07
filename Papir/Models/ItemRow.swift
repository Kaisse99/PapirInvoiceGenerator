//
//  ItemRow.swift
//  One line of an invoice: a name, how many units of how many pieces each, the
//  price per piece, and the colors that line comes in with how many packs go to
//  each. unitCount is the source of truth for the total; colorPacks is her
//  breakdown of it, and the two are allowed to disagree because a breakdown
//  that does not add up is a mistake worth showing her rather than one the app
//  should quietly paper over. Rows written before colorPacks existed fall back
//  to an even spread so old invoices still read sensibly. sortIndex holds
//  the position the user typed the row at, because a SwiftData to-many
//  relationship is an unordered set and would otherwise hand the rows back in
//  an arbitrary order on every fetch. Invoice owns the numbering, so nothing
//  else should set sortIndex by hand.
//  invoice is the back link to the invoice this row belongs to. Nothing reads
//  it: it exists because CloudKit mirroring refuses to open a store holding a
//  relationship with no inverse, and a row is worth nothing without the
//  document it is a line of anyway. Invoice owns both ends.
//  Used by: Invoice, NewInvoiceViewModel, MyInvoicesViewModel, PDFGenerator,
//  InvoiceRowCard, InvoiceDetailView.
//

import Foundation
import SwiftData

@Model
final class ItemRow {
    var name: String = ""
    var unitCount: UInt16 = 0
    var itemsPerUnit: UInt16 = 0
    var price: Double = 0
    var colors: [String] = []
    var colorPacks: [Int] = []
    var sortIndex: Int = 0
    var invoice: Invoice? = nil

    init(name: String, unitCount: UInt16, itemsPerUnit: UInt16, price: Double, colors: [String]) {
        self.name = name
        self.unitCount = unitCount
        self.itemsPerUnit = itemsPerUnit
        self.price = price
        self.colors = colors
    }

    var totalForItem: Double {
        Double(unitCount) * Double(itemsPerUnit) * price
    }

    var colorBreakdown: [ColorAllocation] {
        ItemRow.breakdown(colors: colors, packs: colorPacks, total: Int(unitCount))
    }

    static func breakdown(colors: [String], packs: [Int], total: Int) -> [ColorAllocation] {
        guard !colors.isEmpty else { return [] }
        guard packs.count == colors.count else {
            return evenSpread(total, across: colors)
        }
        return zip(colors, packs).map { ColorAllocation(color: $0, packs: $1) }
    }

    static func evenSpread(_ total: Int, across colors: [String]) -> [ColorAllocation] {
        guard !colors.isEmpty else { return [] }
        guard total > 0 else { return colors.map { ColorAllocation(color: $0, packs: 0) } }
        let base = total / colors.count
        let remainder = total % colors.count
        return colors.enumerated().map { index, color in
            ColorAllocation(color: color, packs: base + (index < remainder ? 1 : 0))
        }
    }
}

struct ColorAllocation: Hashable, Sendable {
    let color: String
    let packs: Int
}
