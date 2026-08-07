//
//  InvoiceListTests.swift
//  Regressions the list once shipped for real: duplicating an invoice used to
//  redistribute the colour breakdown into an even spread and drop the link to
//  the customer, so the copy quietly disagreed with its original in the two
//  places statistics reads.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

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
}
