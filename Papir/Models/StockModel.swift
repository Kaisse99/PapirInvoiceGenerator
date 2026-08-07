//
//  StockModel.swift
//  A garment model held in stock, identified by its code (1987, 6395C), plus
//  one StockLine per color under it. Codes differing only by a letter are
//  separate models, not variants of one, so the code is the whole identity.
//  Stock is counted in whole packs and nothing else. Loose pieces left over
//  from a part-pack order are deliberately not tracked: she does not store
//  partials separately, so counting them would be bookkeeping with no shelf
//  behind it. Taking out more packs than are on hand is allowed and drives the
//  count negative, so a miscount never blocks a real order; the caller is
//  handed the shortfall to warn with.
//  StockState is the one place that decides what a count means, so the list
//  card and the detail screen cannot drift apart on what counts as out.
//  Used by: StockViewModel, StockView, StockModelCard, StockModelDetailView.
//

import Foundation
import SwiftData

@Model
final class StockModel {
    var code: String = ""
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .cascade)
    var lines: [StockLine]? = nil

    init(code: String, lines: [StockLine] = []) {
        self.code = code
        self.createdAt = .now
        self.lines = lines
    }

    var allLines: [StockLine] {
        lines ?? []
    }

    var orderedLines: [StockLine] {
        allLines.sorted { $0.color.localizedStandardCompare($1.color) == .orderedAscending }
    }

    var totalPacks: Int {
        allLines.reduce(0) { $0 + $1.packs }
    }

    var isNegative: Bool {
        allLines.contains { $0.packs < 0 }
    }

    var hasColorOut: Bool {
        allLines.contains { $0.state == .out }
    }

    var state: StockState {
        if isNegative { return .negative }
        if allLines.isEmpty || allLines.allSatisfy({ $0.state == .out }) { return .out }
        if allLines.contains(where: { $0.state == .low || $0.state == .out }) { return .low }
        return .stocked
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
        let trimmed = raw.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count == 4 || trimmed.count == 5 else { return nil }
        guard trimmed.prefix(4).allSatisfy(\.isNumber) else { return nil }
        if trimmed.count == 5, let suffix = trimmed.last, !suffix.isLetter {
            return nil
        }
        return trimmed
    }
}

@Model
final class StockLine {
    var color: String = ""
    var packs: Int = 0

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
