//
//  StockTests.swift
//  What a count means and how it moves: withdrawals that report their
//  shortfall instead of refusing, totals that ignore negative colours rather
//  than letting a miscount understate the shelf, model names that collapse
//  their whitespace, and the state ladders both screens colour by. The low
//  threshold comes from UserDefaults, so the tests that depend on it pin it
//  and put the old value back.
//  StockFilterTests covers the list's own menu: which models each filter
//  keeps, that a negative colour is caught alongside a flat zero, and that
//  every order breaks its ties on the code so an even shelf holds still.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
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

@MainActor
struct StockFilterTests {
    private func withLowStockThreshold(_ value: Int, _ body: () -> Void) {
        let oldValue = UserDefaults.standard.object(forKey: AppSettings.lowStockKey)
        UserDefaults.standard.set(value, forKey: AppSettings.lowStockKey)
        defer {
            if let oldValue {
                UserDefaults.standard.set(oldValue, forKey: AppSettings.lowStockKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppSettings.lowStockKey)
            }
        }
        body()
    }

    @Test func aColorAtZeroCatchesNegativeColorsToo() {
        let full = StockModel(code: "1111", lines: [StockLine(color: "Black", packs: 9)])
        let zeroed = StockModel(code: "2222", lines: [
            StockLine(color: "Black", packs: 9),
            StockLine(color: "White", packs: 0)
        ])
        let miscounted = StockModel(code: "3333", lines: [StockLine(color: "Black", packs: -2)])

        let viewModel = StockViewModel()
        viewModel.stockFilter = .colorAtZero

        #expect(viewModel.filteredAndSorted([full, zeroed, miscounted]).map(\.code) == ["2222", "3333"])
    }

    @Test func understockedAsksTheModelTotalNotItsColors() {
        withLowStockThreshold(3) {
            let healthy = StockModel(code: "1111", lines: [StockLine(color: "Black", packs: 9)])
            let low = StockModel(code: "2222", lines: [StockLine(color: "Black", packs: 3)])
            let empty = StockModel(code: "3333", lines: [StockLine(color: "Black", packs: 0)])
            let healthyWithAGap = StockModel(code: "4444", lines: [
                StockLine(color: "Black", packs: 20),
                StockLine(color: "White", packs: 0)
            ])

            let viewModel = StockViewModel()
            viewModel.stockFilter = .understocked

            let kept = viewModel.filteredAndSorted([healthy, low, empty, healthyWithAGap])
            #expect(kept.map(\.code) == ["2222", "3333"])
        }
    }

    @Test func allModelsHidesNothing() {
        let models = [
            StockModel(code: "2222", lines: [StockLine(color: "Black", packs: 0)]),
            StockModel(code: "1111", lines: [StockLine(color: "Black", packs: 9)])
        ]
        let viewModel = StockViewModel()
        #expect(viewModel.filteredAndSorted(models).count == 2)
    }

    @Test func packOrdersRunBothWaysAndBreakTiesOnTheCode() {
        let big = StockModel(code: "9999", lines: [StockLine(color: "Black", packs: 40)])
        let tiedB = StockModel(code: "2222", lines: [StockLine(color: "Black", packs: 5)])
        let tiedA = StockModel(code: "1111", lines: [StockLine(color: "Black", packs: 5)])

        let viewModel = StockViewModel()

        viewModel.sortOption = .mostPacks
        #expect(viewModel.filteredAndSorted([tiedB, big, tiedA]).map(\.code) == ["9999", "1111", "2222"])

        viewModel.sortOption = .fewestPacks
        #expect(viewModel.filteredAndSorted([tiedB, big, tiedA]).map(\.code) == ["1111", "2222", "9999"])
    }

    @Test func creationOrdersRunBothWays() {
        let older = StockModel(code: "1111")
        older.createdAt = Date(timeIntervalSince1970: 1_000)
        let newer = StockModel(code: "2222")
        newer.createdAt = Date(timeIntervalSince1970: 9_000)

        let viewModel = StockViewModel()

        viewModel.sortOption = .newest
        #expect(viewModel.filteredAndSorted([older, newer]).map(\.code) == ["2222", "1111"])

        viewModel.sortOption = .oldest
        #expect(viewModel.filteredAndSorted([older, newer]).map(\.code) == ["1111", "2222"])
    }

    @Test func searchStillNarrowsWhatTheFilterKept() {
        let zeroedBlack = StockModel(code: "1111", lines: [StockLine(color: "Black", packs: 0)])
        let zeroedWhite = StockModel(code: "2222", lines: [StockLine(color: "White", packs: 0)])

        let viewModel = StockViewModel()
        viewModel.stockFilter = .colorAtZero
        viewModel.searchText = "white"

        #expect(viewModel.filteredAndSorted([zeroedBlack, zeroedWhite]).map(\.code) == ["2222"])
    }
}

@MainActor
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
