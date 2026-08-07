//
//  StockTests.swift
//  What a count means and how it moves: withdrawals that report their
//  shortfall instead of refusing, totals that ignore negative colours rather
//  than letting a miscount understate the shelf, model names that collapse
//  their whitespace, and the state ladders both screens colour by. The low
//  threshold comes from UserDefaults, so the tests that depend on it pin it
//  and put the old value back.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

struct StockTests {
    @Test func withdrawReportsShortfallAndGoesNegative() {
        let line = StockLine(color: "Black", packs: 3)
        let shortfall = line.withdraw(5)
        #expect(shortfall == 2)
        #expect(line.packs == -2)
    }

    @Test func withdrawWithinStockHasNoShortfall() {
        let line = StockLine(color: "Black", packs: 5)
        #expect(line.withdraw(3) == 0)
        #expect(line.packs == 2)
    }

    @Test func receiveIgnoresNonPositiveCounts() {
        let line = StockLine(color: "Black", packs: 2)
        line.receive(0)
        line.receive(-4)
        #expect(line.packs == 2)
    }

    @Test func totalPacksCountsNegativeColorsAsNothing() {
        let model = StockModel(code: "1987", lines: [
            StockLine(color: "Black", packs: 5),
            StockLine(color: "Yellow", packs: -12)
        ])
        #expect(model.totalPacks == 5)
    }

    @Test func totalStateReadsTheTotalAlone() {
        let oldValue = UserDefaults.standard.object(forKey: AppSettings.lowStockKey)
        UserDefaults.standard.set(3, forKey: AppSettings.lowStockKey)
        defer {
            if let oldValue {
                UserDefaults.standard.set(oldValue, forKey: AppSettings.lowStockKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppSettings.lowStockKey)
            }
        }

        let healthy = StockModel(code: "A", lines: [StockLine(color: "B", packs: 9)])
        let low = StockModel(code: "B", lines: [StockLine(color: "B", packs: 3)])
        let empty = StockModel(code: "C", lines: [StockLine(color: "B", packs: 0)])

        #expect(healthy.totalState == .healthy)
        #expect(low.totalState == .low)
        #expect(empty.totalState == .empty)
    }

    @Test func normalizedCodeCollapsesRunsOfWhitespace() {
        #expect(StockModel.normalizedCode("132.   FSD.   Hat") == "132. FSD. Hat")
        #expect(StockModel.normalizedCode("  1987  ") == "1987")
        #expect(StockModel.normalizedCode("   ") == nil)
    }

    @Test func lineLookupIgnoresCase() {
        let model = StockModel(code: "1987", lines: [StockLine(color: "Black", packs: 2)])
        #expect(model.line(for: "black")?.packs == 2)
        #expect(model.line(for: "BLACK") != nil)
        #expect(model.line(for: "White") == nil)
    }

    @Test func recountRecordsTheNewFigureOutright() {
        let line = StockLine(color: "Black", packs: -4)
        line.recount(to: 7)
        #expect(line.packs == 7)
    }
}

struct DuplicateModelTests {
    @Test func aCodeAlreadyOnTheShelfCannotBeAddedAgain() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(StockModel(code: "1987"))
        try context.save()

        let viewModel = StockViewModel()
        viewModel.newModelCode = "1987"
        viewModel.addModel(existing: [], context: context)

        #expect(viewModel.addModelError != nil)
        #expect(try context.fetch(FetchDescriptor<StockModel>()).count == 1)
    }

    @Test func caseAndSpacingDoNotSlipADuplicateThrough() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(StockModel(code: "6395C"))
        try context.save()

        let viewModel = StockViewModel()
        viewModel.newModelCode = "  6395c  "
        viewModel.addModel(existing: [], context: context)

        #expect(viewModel.addModelError != nil)
        #expect(try context.fetch(FetchDescriptor<StockModel>()).count == 1)
    }
}
