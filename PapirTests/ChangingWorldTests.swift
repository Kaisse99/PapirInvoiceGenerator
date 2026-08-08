//
//  ChangingWorldTests.swift
//  What happens to a saved invoice when the world around it moves: prices are
//  raised, a model is deleted, the currency is switched, a row is typed with
//  the model code buried in a sentence. Each of these was asked as a question
//  about statistics, and two of them turned out to be answers nobody would
//  have liked.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
struct ChangingWorldTests {
    private func shippedInvoice(
        code: String = "1987",
        rowName: String? = nil,
        price: Double = 100,
        packs: UInt16 = 2,
        in context: ModelContext
    ) -> Invoice {
        let row = ItemRow(name: rowName ?? code, unitCount: packs, itemsPerUnit: 6, price: price, colors: [])
        let invoice = Invoice(items: [row], date: .now, sender: "Me", receiver: "Olena")
        invoice.status = .shipped
        invoice.currencyCode = AppCurrency.hryvnia.rawValue
        context.insert(invoice)
        return invoice
    }

    @Test func repricingAModelLeavesOldRevenueWhereItWas() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let model = StockModel(code: "1987", pricePerPiece: 100)
        context.insert(model)
        let invoice = shippedInvoice(in: context)
        try context.save()

        let viewModel = StatisticsViewModel()
        viewModel.period = .everything
        let before = viewModel.revenue(viewModel.shipped([invoice]))

        model.pricePerPiece = 500
        try context.save()

        #expect(viewModel.revenue(viewModel.shipped([invoice])) == before)
        #expect(before == 1200)
    }

    @Test func revertRefusesRatherThanLosingThePacks() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let model = StockModel(code: "1987", pricePerPiece: 100, lines: [StockLine(color: "Black", packs: 10)])
        context.insert(model)

        let row = ItemRow(name: "1987", unitCount: 3, itemsPerUnit: 6, price: 100, colors: ["Black"])
        row.colorPacks = [3]
        let invoice = Invoice(items: [row], date: .now, sender: "Me", receiver: "Olena")
        context.insert(invoice)
        try context.save()

        try ShipmentPlanner.apply(
            ShipmentPlanner.plan(for: invoice, stock: [model]),
            to: invoice, stock: [model], context: context
        )
        #expect(invoice.shipment.count == 1)

        context.delete(model)
        try context.save()

        #expect(throws: ShipmentRevertBlocked.self) {
            try ShipmentPlanner.revert(invoice, stock: [], context: context)
        }

        #expect(invoice.status == .shipped, "the invoice stays shipped")
        #expect(invoice.shipment.count == 1, "the record of what left the shelf survives")
    }

    @Test func anInvoiceRemembersTheCurrencyItWasWrittenIn() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let invoice = shippedInvoice(in: context)
        try context.save()

        #expect(invoice.currency == .hryvnia)
        #expect(invoice.snapshot.currencySymbol == AppCurrency.hryvnia.symbol)

        let defaults = UserDefaults.standard
        let previous = defaults.string(forKey: AppSettings.currencyKey)
        defer { defaults.set(previous, forKey: AppSettings.currencyKey) }
        defaults.set(AppCurrency.dollar.rawValue, forKey: AppSettings.currencyKey)

        #expect(invoice.currency == .hryvnia, "switching the setting does not relabel history")
        #expect(invoice.snapshot.currencySymbol == AppCurrency.hryvnia.symbol)

        let viewModel = StatisticsViewModel()
        viewModel.period = .everything
        #expect(viewModel.shipped([invoice]).isEmpty, "not summed into a total of another currency")
        #expect(viewModel.inAnotherCurrency([invoice]) == 1, "and counted rather than dropped")
    }

    @Test func aRowNamingAModelInASentenceRanksUnderThatModel() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let model = StockModel(code: "2337", pricePerPiece: 100)
        context.insert(model)

        let plain = shippedInvoice(code: "2337", price: 100, packs: 1, in: context)
        let wordy = shippedInvoice(code: "2337", rowName: "Cotton Tee 2337", price: 100, packs: 1, in: context)
        try context.save()

        let viewModel = StatisticsViewModel()
        viewModel.period = .everything
        let shipped = viewModel.shipped([plain, wordy])

        let grouped = viewModel.byProfit(shipped, stock: [model])
        #expect(grouped.count == 1, "one model, one rank")
        #expect(grouped.first?.name == "2337")
        #expect(grouped.first?.packs == 2)

        let ungrouped = viewModel.byProfit(shipped, stock: [])
        #expect(ungrouped.count == 2, "with no shelf to match against they stay separate")
    }
}
