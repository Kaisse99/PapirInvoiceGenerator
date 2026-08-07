//
//  BackupTests.swift
//  A backup that cannot be restored is a report, so the round trip is the
//  test: build a store with everything in it, write the file, restore it into
//  an empty store, and check that what came back is what went in, down to the
//  colour breakdown, the shipment record, the contact link and the shipped
//  status, which are exactly the things the Excel export flattens away.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

struct BackupTests {
    @Test func roundTripKeepsEverythingTheSheetsFlatten() throws {
        let source = try makeContainer()
        let sourceContext = source.mainContext

        let contact = Contact(firstName: "Olena", lastName: "Shevchenko", phone: "067", city: "Odesa", branchOne: "NP 12")
        sourceContext.insert(contact)

        let model = StockModel(code: "1987", pricePerPiece: 150, lines: [
            StockLine(color: "Black", packs: 5),
            StockLine(color: "Yellow", packs: -2)
        ])
        sourceContext.insert(model)

        let row = ItemRow(name: "1987", unitCount: 6, itemsPerUnit: 6, price: 150, colors: ["Black", "White"])
        row.colorPacks = [5, 1]

        let invoice = Invoice(items: [row], date: .now, sender: "Me", receiver: contact.displayName)
        invoice.receiverContact = contact
        invoice.status = .shipped
        invoice.shippedAt = .now
        invoice.recordShipment(ShipmentLine(modelCode: "1987", color: "Black", packs: 5))
        sourceContext.insert(invoice)

        sourceContext.insert(StockMovement(modelCode: "1987", color: "Black", packs: -5, kind: .shipped, context: "Olena"))
        try sourceContext.save()

        let file = try Backup.snapshot(context: sourceContext)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(file)

        let target = try makeContainer()
        let targetContext = target.mainContext
        let counts = try Backup.restore(data, context: targetContext)

        #expect(counts.invoices == 1)
        #expect(counts.models == 1)
        #expect(counts.contacts == 1)

        let restored = try #require(try targetContext.fetch(FetchDescriptor<Invoice>()).first)
        #expect(restored.id == invoice.id)
        #expect(restored.status == .shipped)
        #expect(restored.orderedItems.first?.colorPacks == [5, 1])
        #expect(restored.shipment.first?.packs == 5)
        #expect(restored.receiverContact?.firstName == "Olena")

        let restoredModel = try #require(try targetContext.fetch(FetchDescriptor<StockModel>()).first)
        #expect(restoredModel.pricePerPiece == 150)
        #expect(restoredModel.line(for: "yellow")?.packs == -2)

        let movements = try targetContext.fetch(FetchDescriptor<StockMovement>())
        #expect(movements.count == 1)
        #expect(movements.first?.kind == .shipped)
    }

    @Test func restoreReplacesRatherThanMerges() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(StockModel(code: "OLD"))
        context.insert(Contact(firstName: "Old"))
        try context.save()

        let empty = BackupFile(
            version: 1,
            exportedAt: .now,
            contacts: [],
            models: [BackupFile.StockModelRecord(code: "NEW", pricePerPiece: 0, lines: [])],
            invoices: [],
            movements: []
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(empty)
        _ = try Backup.restore(data, context: context)

        let models = try context.fetch(FetchDescriptor<StockModel>())
        #expect(models.map(\.code) == ["NEW"])
        #expect(try context.fetch(FetchDescriptor<Contact>()).isEmpty)
    }

    @Test func restoreClearsRowsNoInvoiceOwns() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(ItemRow(name: "orphan", unitCount: 1, itemsPerUnit: 6, price: 10, colors: []))
        context.insert(ShipmentLine(modelCode: "orphan", color: "Black", packs: 1))
        context.insert(StockLine(color: "Black", packs: 1))
        try context.save()

        let empty = BackupFile(
            version: 1,
            exportedAt: .now,
            contacts: [],
            models: [],
            invoices: [],
            movements: []
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        _ = try Backup.restore(try encoder.encode(empty), context: context)

        #expect(try context.fetch(FetchDescriptor<ItemRow>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ShipmentLine>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<StockLine>()).isEmpty)
    }
}
