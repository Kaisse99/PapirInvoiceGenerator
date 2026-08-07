//
//  StockModel.swift
//  A garment model held in stock, identified by whatever she calls it (1987,
//  6395C, a name), plus one StockLine per color under it. Two codes differing
//  by a letter are separate models, not variants of one, so the code is the
//  whole identity. It used to be held to four digits and an optional letter;
//  that turned out to be her supplier's habit rather than a rule, so the only
//  thing enforced now is that it is not blank and that runs of spaces are
//  collapsed, since "132.   FSD" and "132. FSD" are the same box on the shelf
//  and only one of them can be found by searching.
//  Stock is counted in whole packs and nothing else. Loose pieces left over
//  from a part-pack order are deliberately not tracked: she does not store
//  partials separately, so counting them would be bookkeeping with no shelf
//  behind it. Taking out more packs than are on hand is allowed and drives the
//  count negative, so a miscount never blocks a real order; the caller is
//  handed the shortfall to warn with.
//  StockState is the one place that decides what a color's count means, so the
//  list card and the detail screen cannot drift apart on what counts as out.
//  There is no state for the model as a whole: the badge that summarised its
//  colors said in words what the chips beneath it already say in colour, so it
//  is gone and so is the rollup behind it. A screen that needs the idea again
//  should say out loud which colors it means.
//  A negative color counts as nothing towards the pack total rather than
//  eating into it: minus one is a bookkeeping error, not a debt against the
//  boxes actually on the shelf, and subtracting it would understate what she
//  can ship. It still shows red on its own line and still flags the model for
//  a recount. PackTotalState is what the big number is coloured by, and it
//  reads the total alone: empty when the shelf is bare, low against the
//  warning number in settings, and otherwise plain ink. It is deliberately not
//  StockState, because one color sitting at zero says nothing about whether
//  there is anything left to sell.
//  pricePerPiece is what this model sells for per piece, kept on the model
//  rather than on the invoice row so writing an invoice fills the price in
//  instead of asking for it again. Zero means it has never been set, which is
//  also what every model held before the field existed, so nothing needs
//  backfilling; a row only autofills when the price is above zero.
//  StockLine.model is the back link to the model a colour sits under. Nothing
//  reads it: it is there because CloudKit mirroring refuses to open a store
//  holding a relationship with no inverse, and a colour with no model behind
//  it is not a thing on the shelf.
//  Used by: StockViewModel, StockView, StockModelCard, StockModelDetailView,
//  InvoiceRowCard through StockSuggestion.
//

import Foundation
import SwiftData

@Model
final class StockModel {
    var code: String = ""
    var createdAt: Date = Date.now
    var pricePerPiece: Double = 0
    @Relationship(deleteRule: .cascade, inverse: \StockLine.model)
    var lines: [StockLine]? = nil

    init(code: String, pricePerPiece: Double = 0, lines: [StockLine] = []) {
        self.code = code
        self.createdAt = .now
        self.pricePerPiece = pricePerPiece
        self.lines = lines
    }

    var hasPrice: Bool {
        pricePerPiece > 0
    }

    var allLines: [StockLine] {
        lines ?? []
    }

    var orderedLines: [StockLine] {
        allLines.sorted { $0.color.localizedStandardCompare($1.color) == .orderedAscending }
    }

    var totalPacks: Int {
        allLines.reduce(0) { $0 + max(0, $1.packs) }
    }

    var totalState: PackTotalState {
        if totalPacks <= 0 { return .empty }
        if totalPacks <= AppSettings.lowStockThreshold { return .low }
        return .healthy
    }

    func line(for color: String) -> StockLine? {
        allLines.first { $0.color.caseInsensitiveCompare(color) == .orderedSame }
    }

    func addLine(_ line: StockLine) {
        if lines == nil { lines = [] }
        lines?.append(line)
    }

    func removeLine(_ line: StockLine) {
        lines?.removeAll { $0.persistentModelID == line.persistentModelID }
    }

    static func normalizedCode(_ raw: String) -> String? {
        let collapsed = raw
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return collapsed.isEmpty ? nil : collapsed
    }
}

@Model
final class StockLine {
    var color: String = ""
    var packs: Int = 0
    var model: StockModel? = nil

    init(color: String, packs: Int = 0) {
        self.color = color
        self.packs = packs
    }

    func receive(_ count: Int) {
        guard count > 0 else { return }
        packs += count
    }

    @discardableResult
    func withdraw(_ count: Int) -> Int {
        guard count > 0 else { return 0 }
        let shortfall = max(0, count - packs)
        packs -= count
        return shortfall
    }

    func recount(to count: Int) {
        packs = count
    }

    var state: StockState {
        if packs < 0 { return .negative }
        if packs == 0 { return .out }
        if packs <= AppSettings.lowStockThreshold { return .low }
        return .stocked
    }
}

enum StockState {
    case stocked, low, out, negative
}

enum PackTotalState {
    case healthy, low, empty
}
