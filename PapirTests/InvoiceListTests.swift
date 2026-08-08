//
//  InvoiceListTests.swift
//  Regressions the list once shipped for real: duplicating an invoice used to
//  redistribute the colour breakdown into an even spread and drop the link to
//  the customer, so the copy quietly disagreed with its original in the two
//  places statistics reads. Editing one used to leave its old rows behind in
//  the store, reachable from nothing and counted by no screen, which is
//  invisible until iCloud starts syncing them.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
struct InvoiceListTests {
    @Test func duplicateKeepsColorPacksAndContact() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let contact = Contact(firstName: "Olena", lastName: "Shevchenko")
        context.insert(contact)

        let row = ItemRow(name: "1987", unitCount: 6, itemsPerUnit: 6, price: 150, colors: ["Black", "White"])
        row.colorPacks = [5, 1]

        let original = Invoice(
            items: [row],
            date: Date(timeIntervalSinceNow: -86400),
            sender: "Me",
            receiver: contact.displayName
        )
        original.receiverContact = contact
        context.insert(original)
        try context.save()

        let viewModel = MyInvoicesViewModel()
        viewModel.duplicate(original, context: context)

        let all = try context.fetch(FetchDescriptor<Invoice>())
        #expect(all.count == 2)

        let copy = try #require(all.first { $0.id != original.id })
        #expect(copy.orderedItems.first?.colorPacks == [5, 1])
        #expect(copy.receiverContact?.persistentModelID == contact.persistentModelID)
        #expect(copy.orderedItems.first?.colorBreakdown.map(\.packs) == [5, 1])
    }

    @Test func editingAnInvoiceLeavesNoOrphanedRows() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let invoice = Invoice(
            items: [
                ItemRow(name: "1987", unitCount: 6, itemsPerUnit: 6, price: 150, colors: []),
                ItemRow(name: "2337", unitCount: 2, itemsPerUnit: 6, price: 90, colors: [])
            ],
            sender: "Me",
            receiver: "Olena"
        )
        context.insert(invoice)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<ItemRow>()).count == 2)

        invoice.replaceItems(with: [
            ItemRow(name: "9813", unitCount: 1, itemsPerUnit: 6, price: 120, colors: [])
        ])
        try context.save()

        #expect(invoice.orderedItems.map(\.name) == ["9813"])
        #expect(try context.fetch(FetchDescriptor<ItemRow>()).count == 1)
    }

    @Test func revertingAShipmentLeavesNoOrphanedLines() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let invoice = Invoice(
            items: [ItemRow(name: "1987", unitCount: 1, itemsPerUnit: 6, price: 150, colors: [])],
            sender: "Me",
            receiver: "Olena"
        )
        invoice.recordShipment(ShipmentLine(modelCode: "1987", color: "Black", packs: 1))
        context.insert(invoice)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<ShipmentLine>()).count == 1)

        invoice.clearShipment()
        try context.save()

        #expect(invoice.shipment.isEmpty)
        #expect(try context.fetch(FetchDescriptor<ShipmentLine>()).isEmpty)
    }
}
