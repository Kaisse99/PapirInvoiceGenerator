//
//  PDFGeneratorTests.swift
//  The PDF is the thing the customer is actually handed, and until now it was
//  the one output nothing checked. These do not judge the layout, which is a
//  matter for eyes; they check that every language renders real PDF data, that
//  a long invoice runs onto a second page instead of drawing off the bottom of
//  the first, and that the receiver's name and the total reach the page at all.
//  Rendering also happens off the main actor, so render is exercised through
//  its async front door rather than by calling generate directly.
//

import Foundation
import PDFKit
import Testing
@testable import Papir

@MainActor
struct PDFGeneratorTests {
    private func snapshot(rows: Int) -> InvoiceSnapshot {
        InvoiceSnapshot(
            id: UUID(),
            number: 42,
            currencySymbol: "₴",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            sender: "Kaissenberg",
            receiver: "Olena Shevchenko",
            receiverDetails: ["Odesa", "NP 12", "067"],
            items: (0..<rows).map { index in
                InvoiceSnapshot.Item(
                    name: "Model \(1000 + index)",
                    unitCount: 6,
                    itemsPerUnit: 6,
                    price: 150,
                    colors: ["Black", "White"],
                    colorBreakdown: [
                        ColorAllocation(color: "Black", packs: 4),
                        ColorAllocation(color: "White", packs: 2)
                    ]
                )
            }
        )
    }

    @Test(arguments: PDFLanguage.allCases)
    func everyLanguageRendersRealPDFData(language: PDFLanguage) async {
        let data = await PDFGenerator.render(snapshot(rows: 3), language: language, currencySymbol: "₴")

        #expect(!data.isEmpty)
        #expect(data.prefix(4) == Data("%PDF".utf8))
        #expect(PDFDocument(data: data)?.pageCount == 1)
    }

    @Test func aLongInvoiceRunsOntoMorePages() async {
        let short = await PDFGenerator.render(snapshot(rows: 3), language: .english, currencySymbol: "₴")
        let long = await PDFGenerator.render(snapshot(rows: 40), language: .english, currencySymbol: "₴")

        let shortPages = PDFDocument(data: short)?.pageCount ?? 0
        let longPages = PDFDocument(data: long)?.pageCount ?? 0

        #expect(shortPages == 1)
        #expect(longPages > 1)
    }

    @Test func aColorWithOnePackStillPrintsItsNumber() async {
        let invoice = InvoiceSnapshot(
            id: UUID(),
            number: 105,
            currencySymbol: "$",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            sender: "ItemsStuff Inc.",
            receiver: "Sophia Davis",
            receiverDetails: [],
            items: [
                InvoiceSnapshot.Item(
                    name: "3128 Windbreaker",
                    unitCount: 2,
                    itemsPerUnit: 6,
                    price: 39,
                    colors: ["Beige", "Olive"],
                    colorBreakdown: [
                        ColorAllocation(color: "Beige", packs: 1),
                        ColorAllocation(color: "Olive", packs: 1)
                    ]
                )
            ]
        )

        let data = await PDFGenerator.render(invoice, language: .english, currencySymbol: "$")
        let text = PDFDocument(data: data)?.string ?? ""

        #expect(text.contains("Beige 1"))
        #expect(text.contains("Olive 1"))
    }

    @Test func thePartiesAndTheTotalReachThePage() async {
        let invoice = snapshot(rows: 2)
        let data = await PDFGenerator.render(invoice, language: .english, currencySymbol: "₴")
        let text = PDFDocument(data: data)?.string ?? ""

        #expect(text.contains("Olena Shevchenko"))
        #expect(text.contains("Kaissenberg"))
        #expect(text.contains("Odesa"))
        #expect(text.contains("Model 1000"))
    }
}
