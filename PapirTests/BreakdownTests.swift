//
//  BreakdownTests.swift
//  The colour breakdown is the arithmetic the whole shipping pipeline stands
//  on: what she typed per colour when the counts are hers, an even spread when
//  an old row predates per-colour counts, and a deliberate refusal to invent
//  numbers when the two disagree in length. Every case here is a behaviour the
//  invoice card or the shipment sheet shows to a user.
//

import Testing
@testable import Papir

struct BreakdownTests {
    @Test func explicitPacksAreKeptAsTyped() {
        let result = ItemRow.breakdown(colors: ["Black", "White"], packs: [5, 1], total: 6)
        #expect(result.map(\.packs) == [5, 1])
        #expect(result.map(\.color) == ["Black", "White"])
    }

    @Test func mismatchedPackCountFallsBackToEvenSpread() {
        let result = ItemRow.breakdown(colors: ["Black", "White"], packs: [5], total: 6)
        #expect(result.map(\.packs) == [3, 3])
    }

    @Test func evenSpreadHandsRemainderToTheFirstColors() {
        let result = ItemRow.evenSpread(7, across: ["A", "B", "C"])
        #expect(result.map(\.packs) == [3, 2, 2])
    }

    @Test func evenSpreadOfZeroLeavesEveryColorAtZero() {
        let result = ItemRow.evenSpread(0, across: ["A", "B"])
        #expect(result.map(\.packs) == [0, 0])
    }

    @Test func noColorsMeansNoBreakdown() {
        #expect(ItemRow.breakdown(colors: [], packs: [], total: 6).isEmpty)
    }

    @Test func rowTotalMultipliesAllThreeNumbers() {
        let row = ItemRow(name: "1987", unitCount: 3, itemsPerUnit: 6, price: 150, colors: [])
        #expect(row.totalForItem == 2700)
    }
}
