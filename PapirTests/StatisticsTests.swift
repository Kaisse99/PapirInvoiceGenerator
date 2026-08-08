//
//  StatisticsTests.swift
//  The statistics screen promises that every figure on it counts shipped
//  invoices only, that the chart never skips an empty day, and that a model's
//  colours sum across every row that named it. These tests hold it to that,
//  because a statistics screen that flatters is worse than none.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

@MainActor
struct StatisticsTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    @Test func revenueCountsShippedOnly() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = StatisticsViewModel()
        viewModel.period = .month(StatsPeriod.startOfMonth(date(2026, 3, 10)))

        let shipped = Invoice(
            items: [ItemRow(name: "1987", unitCount: 2, itemsPerUnit: 6, price: 100, colors: [])],
            date: date(2026, 3, 10),
            sender: "",
            receiver: ""
        )
        shipped.status = .shipped

        let draft = Invoice(
            items: [ItemRow(name: "1987", unitCount: 9, itemsPerUnit: 6, price: 100, colors: [])],
            date: date(2026, 3, 12),
            sender: "",
            receiver: ""
        )

        context.insert(shipped)
        context.insert(draft)

        let visible = viewModel.shipped([shipped, draft])
        #expect(visible.count == 1)
        #expect(viewModel.revenue(visible) == 1200)
        #expect(viewModel.packsSold(visible) == 2)
    }

    @Test func seriesZeroFillsEveryDayOfAPastMonth() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = StatisticsViewModel()
        viewModel.period = .month(StatsPeriod.startOfMonth(date(2026, 3, 1)))

        let invoice = Invoice(
            items: [ItemRow(name: "1987", unitCount: 1, itemsPerUnit: 6, price: 100, colors: [])],
            date: date(2026, 3, 10),
            sender: "",
            receiver: ""
        )
        invoice.status = .shipped
        context.insert(invoice)

        let points = viewModel.series([invoice])
        #expect(points.count == 31)
        #expect(points.filter { $0.amount > 0 }.count == 1)
        #expect(points.reduce(0) { $0 + $1.amount } == 600)
    }

    @Test func modelColorsSumAcrossRows() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = StatisticsViewModel()
        viewModel.period = .everything

        let first = ItemRow(name: "1987", unitCount: 3, itemsPerUnit: 6, price: 100, colors: ["Black", "White"])
        first.colorPacks = [2, 1]
        let second = ItemRow(name: "1987 ", unitCount: 2, itemsPerUnit: 6, price: 100, colors: ["Black"])
        second.colorPacks = [2]

        let invoice = Invoice(items: [first, second], date: date(2026, 3, 10), sender: "", receiver: "")
        invoice.status = .shipped
        context.insert(invoice)

        let stats = viewModel.modelStats([invoice])
        #expect(stats.count == 1)
        #expect(stats.first?.packs == 5)
        #expect(stats.first?.colors.first?.color == "Black")
        #expect(stats.first?.colors.first?.packs == 4)
    }

    @Test func buyersFallBackFromContactToTypedNameToNone() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = StatisticsViewModel()
        viewModel.period = .everything

        let contact = Contact(firstName: "Olena", lastName: "Shevchenko")
        context.insert(contact)

        let linked = Invoice(
            items: [ItemRow(name: "A", unitCount: 1, itemsPerUnit: 1, price: 300, colors: [])],
            date: date(2026, 3, 1),
            sender: "",
            receiver: contact.displayName
        )
        linked.status = .shipped
        linked.receiverContact = contact

        let typed = Invoice(
            items: [ItemRow(name: "A", unitCount: 1, itemsPerUnit: 1, price: 200, colors: [])],
            date: date(2026, 3, 2),
            sender: "",
            receiver: "Someone"
        )
        typed.status = .shipped

        let nameless = Invoice(
            items: [ItemRow(name: "A", unitCount: 1, itemsPerUnit: 1, price: 100, colors: [])],
            date: date(2026, 3, 3),
            sender: "",
            receiver: ""
        )
        nameless.status = .shipped

        context.insert(linked)
        context.insert(typed)
        context.insert(nameless)

        let buyers = viewModel.topBuyers([linked, typed, nameless])
        #expect(buyers.count == 3)
        #expect(buyers[0].name == "Olena Shevchenko")
        #expect(buyers[1].name == "Someone")
        #expect(buyers[2].name == L.t(.noReceiver))
    }
}
