//
//  ShipmentPlannerTests.swift
//  The join between an invoice and the shelf, tested end to end in memory:
//  planning finds the model even when the row spells its code in another case
//  or buries it in a longer name, applying deducts per colour and writes down
//  exactly what left, and reverting replays that record instead of guessing.
//  The case-insensitive match is a regression test; shipping once deducted
//  nothing for a row typed in the wrong case while the editor said in stock.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
struct ShipmentPlannerTests {
    @Test func planMatchesModelCodeIgnoringCase() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let model = StockModel(code: "Abc Hat", lines: [StockLine(color: "Black", packs: 5)])
        context.insert(model)

        let invoice = Invoice(
            items: [ItemRow(name: "abc hat", unitCount: 2, itemsPerUnit: 6, price: 100, colors: ["Black"])],
            sender: "",
            receiver: ""
        )
        invoice.allItems.first?.colorPacks = [2]
        context.insert(invoice)

        let drafts = ShipmentPlanner.plan(for: invoice, stock: [model])
        #expect(drafts.count == 1)
        #expect(drafts.first?.modelCode == "Abc Hat")
        #expect(drafts.first?.packs == 2)
    }

    @Test func planFindsTheCodeInsideALongerName() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let model = StockModel(code: "2337", lines: [StockLine(color: "Black", packs: 5)])
        context.insert(model)

        let invoice = Invoice(
            items: [ItemRow(name: "Cotton Tee 2337", unitCount: 1, itemsPerUnit: 6, price: 100, colors: ["Black"])],
            sender: "",
            receiver: ""
        )
        invoice.allItems.first?.colorPacks = [1]
        context.insert(invoice)

        let drafts = ShipmentPlanner.plan(for: invoice, stock: [model])
        #expect(drafts.first?.modelCode == "2337")
    }

    @Test func applyDeductsRecordsAndRevertRestores() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let model = StockModel(code: "1987", lines: [StockLine(color: "Black", packs: 5)])
        context.insert(model)

        let invoice = Invoice(
            items: [ItemRow(name: "1987", unitCount: 2, itemsPerUnit: 6, price: 150, colors: ["Black"])],
            sender: "",
            receiver: "Olena"
        )
        invoice.allItems.first?.colorPacks = [2]
        context.insert(invoice)

        let drafts = ShipmentPlanner.plan(for: invoice, stock: [model])
        let shortfall = try ShipmentPlanner.apply(drafts, to: invoice, stock: [model], context: context)

        #expect(shortfall == 0)
        #expect(model.line(for: "Black")?.packs == 3)
        #expect(invoice.status == .shipped)
        #expect(invoice.shipment.count == 1)
        #expect(invoice.shipment.first?.packs == 2)

        let movements = try context.fetch(FetchDescriptor<StockMovement>())
        #expect(movements.contains { $0.kind == .shipped && $0.packs == -2 })

        try ShipmentPlanner.revert(invoice, stock: [model], context: context)

        #expect(model.line(for: "Black")?.packs == 5)
        #expect(invoice.status == .draft)
        #expect(invoice.shipment.isEmpty)
    }

    @Test func overshippingReportsTheShortfallAndStillHappens() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let model = StockModel(code: "1987", lines: [StockLine(color: "Black", packs: 1)])
        context.insert(model)

        let invoice = Invoice(
            items: [ItemRow(name: "1987", unitCount: 4, itemsPerUnit: 6, price: 150, colors: ["Black"])],
            sender: "",
            receiver: ""
        )
        invoice.allItems.first?.colorPacks = [4]
        context.insert(invoice)

        let drafts = ShipmentPlanner.plan(for: invoice, stock: [model])
        let shortfall = try ShipmentPlanner.apply(drafts, to: invoice, stock: [model], context: context)

        #expect(shortfall == 3)
        #expect(model.line(for: "Black")?.packs == -3)
    }

    @Test func unmatchedRowsAreCarriedThroughNotDropped() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let invoice = Invoice(
            items: [ItemRow(name: "Nowhere", unitCount: 2, itemsPerUnit: 6, price: 100, colors: [])],
            sender: "",
            receiver: ""
        )
        context.insert(invoice)

        let drafts = ShipmentPlanner.plan(for: invoice, stock: [])
        #expect(drafts.count == 1)
        #expect(drafts.first?.isMatched == false)
        #expect(drafts.first?.isActionable == false)
    }
}
