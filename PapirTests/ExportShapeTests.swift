//
//  ExportShapeTests.swift
//  A spreadsheet whose header row is wider than its data rows does not look
//  broken, it looks wrong: every value after the gap sits under somebody
//  else's heading, and the reader has no way to tell. That is what happened
//  when a contact's two Nova Poshta fields became one address and the column
//  went on being declared, so the invoice count slid under a heading about
//  delivery. Nothing caught it because nothing was counting.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
struct ExportShapeTests {
    private func filledStore() throws -> ModelContainer {
        let container = try makeContainer()
        let context = container.mainContext

        let contact = Contact(firstName: "Olena", lastName: "Shevchenko", phone: "067", city: "Odesa", shipmentAddress: "NP 12")
        context.insert(contact)

        let model = StockModel(code: "1987", pricePerPiece: 150, piecesPerPack: 6, lines: [StockLine(color: "Black", packs: 4)])
        context.insert(model)

        let row = ItemRow(name: "1987", unitCount: 2, itemsPerUnit: 6, price: 150, colors: ["Black"])
        row.colorPacks = [2]
        let invoice = Invoice(items: [row], date: .now, sender: "Me", receiver: contact.displayName)
        invoice.receiverContact = contact
        invoice.status = .shipped
        context.insert(invoice)

        context.insert(StockMovement(modelCode: "1987", color: "Black", packs: -2, kind: .shipped, context: "Olena"))
        try context.save()
        return container
    }

    @Test func everySheetRowIsAsWideAsItsHeader() throws {
        let container = try filledStore()
        let context = container.mainContext

        let invoices = try context.fetch(FetchDescriptor<Invoice>())
        let stock = try context.fetch(FetchDescriptor<StockModel>())
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        let movements = try context.fetch(FetchDescriptor<StockMovement>())

        let sheets = [
            DataExport.invoiceSheet(invoices, currencySymbol: "₴"),
            DataExport.stockSheet(stock),
            DataExport.contactSheet(contacts),
            DataExport.historySheet(movements)
        ]

        for sheet in sheets {
            #expect(!sheet.rows.isEmpty, "\(sheet.name) produced no rows to check")
            for (index, row) in sheet.rows.enumerated() {
                #expect(
                    row.count == sheet.columns.count,
                    "\(sheet.name) row \(index) has \(row.count) cells under \(sheet.columns.count) headings"
                )
            }
        }
    }
}
