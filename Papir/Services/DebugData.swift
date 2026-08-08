//
//  DebugData.swift
//  A shelf and a year of trade, invented, so every screen can be looked at
//  full instead of empty. Statistics in particular is unreadable with three
//  invoices in it: the chart has nothing to draw, the rankings have nothing to
//  rank, and the month picker has one month.
//
//  The whole file sits inside #if DEBUG. That is the point, not a formality:
//  it is not hidden behind a gesture or a tap count, it is not compiled into a
//  Release build at all, so there is no button for a customer to find by
//  accident and no code path for them to reach if they did. Anything added
//  here must stay inside the same fence.
//
//  Text is written in plain English rather than through LKey, because nobody
//  who is not the developer will ever read it, and inventing translations for
//  a debug screen would put fake entries in a table the real screens share.
//  The invented data itself is Ukrainian, since that is what the app is for
//  and English test rows would say nothing about how the real thing wraps.
//
//  Filling twice must not double the shelf: a code already on it is reused
//  rather than added again, because two models with one code is exactly the
//  state the stock screen refuses to let anyone create by hand.
//
//  Shipped invoices are shipped properly: stock is deducted, ShipmentLines are
//  written and a movement is logged, the same three things ShipmentPlanner
//  does. Faking the status alone would produce a store that cannot happen, and
//  a preview of an impossible state is worse than an empty one.
//  Used by: SettingsSheet, in debug builds only.
//

#if DEBUG
import Foundation
import os
import SwiftData

@MainActor
enum DebugData {
    private static let codes = [
        "1987", "2337", "9813", "4402", "6395C", "7710",
        "3128", "5567", "8021", "2244", "6688", "1450"
    ]

    private static let colors = [
        "чорний", "білий", "сірий", "бежевий", "синій",
        "червоний", "зелений", "рожевий", "коричневий", "мокко"
    ]

    private static let firstNames = [
        "Олена", "Ірина", "Наталія", "Оксана", "Марія",
        "Тетяна", "Людмила", "Світлана", "Галина", "Юлія"
    ]

    private static let lastNames = [
        "Шевченко", "Коваленко", "Бондаренко", "Ткаченко", "Мельник",
        "Кравченко", "Олійник", "Поліщук", "Савченко", "Руденко"
    ]

    private static let cities = [
        "Одеса", "Київ", "Львів", "Харків", "Дніпро",
        "Вінниця", "Полтава", "Чернівці", "Ужгород", "Суми"
    ]

    @discardableResult
    static func populate(context: ModelContext) throws -> String {
        var rng = Seeded(seed: 20260807)
        let calendar = Calendar.current

        var contacts: [Contact] = []
        for index in 0..<10 {
            let contact = Contact(
                firstName: firstNames[index],
                lastName: lastNames[index],
                phone: "0\(Int.random(in: 50...99, using: &rng))\(Int.random(in: 1000000...9999999, using: &rng))",
                city: cities[index],
                shipmentAddress: "Відділення №\(Int.random(in: 1...48, using: &rng))"
            )
            context.insert(contact)
            contacts.append(contact)
        }

        let existing = (try? context.fetch(FetchDescriptor<StockModel>())) ?? []
        var models: [StockModel] = []
        for code in codes {
            let palette = colors.shuffled(using: &rng).prefix(Int.random(in: 2...5, using: &rng))

            if let already = existing.first(where: { $0.code.caseInsensitiveCompare(code) == .orderedSame }) {
                models.append(already)
                continue
            }

            let model = StockModel(
                code: code,
                pricePerPiece: Double(Int.random(in: 8...45, using: &rng)) * 10,
                lines: palette.map { StockLine(color: $0, packs: Int.random(in: 0...40, using: &rng)) }
            )
            context.insert(model)
            models.append(model)

            for line in model.allLines where line.packs > 0 {
                context.insert(
                    StockMovement(
                        date: calendar.date(byAdding: .day, value: -Int.random(in: 200...300, using: &rng), to: .now) ?? .now,
                        modelCode: model.code,
                        color: line.color,
                        packs: line.packs,
                        kind: .received
                    )
                )
            }
        }

        var invoiceCount = 0
        var nextNumber = InvoiceNumbering.next(in: context)
        for daysAgo in stride(from: 250, through: 0, by: -1) {
            guard Int.random(in: 0...3, using: &rng) == 0 else { continue }
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }

            let contact = contacts.randomElement(using: &rng)
            let rows = (0..<Int.random(in: 1...5, using: &rng)).map { _ -> ItemRow in
                let model = models.randomElement(using: &rng) ?? models[0]
                let palette = model.orderedLines.map(\.color)
                let chosen = Array(palette.shuffled(using: &rng).prefix(Int.random(in: 1...max(1, palette.count))))
                let packs = chosen.map { _ in Int.random(in: 1...6, using: &rng) }

                let row = ItemRow(
                    name: model.code,
                    unitCount: UInt16(packs.reduce(0, +)),
                    itemsPerUnit: 6,
                    price: model.pricePerPiece,
                    colors: chosen
                )
                row.colorPacks = packs
                return row
            }

            let invoice = Invoice(
                items: rows,
                date: date,
                sender: AppSettings.defaultSender.isEmpty ? "Papir" : AppSettings.defaultSender,
                receiver: contact?.displayName ?? "Готівка"
            )
            invoice.receiverContact = contact
            invoiceCount += 1
            invoice.currencyCode = AppSettings.currency.rawValue
            invoice.number = nextNumber
            nextNumber += 1
            context.insert(invoice)

            if daysAgo > 7 || Bool.random(using: &rng) {
                ship(invoice, models: models, date: date, context: context)
            }
        }

        try context.save()
        AppLog.data.debug("Debug data populated: \(invoiceCount) invoices")
        return "\(invoiceCount) invoices · \(models.count) models · \(contacts.count) contacts"
    }

    private static func ship(_ invoice: Invoice, models: [StockModel], date: Date, context: ModelContext) {
        for item in invoice.orderedItems {
            guard let model = models.first(where: { $0.code.caseInsensitiveCompare(item.name) == .orderedSame }) else { continue }

            for allocation in item.colorBreakdown where allocation.packs > 0 {
                let line: StockLine
                if let existing = model.line(for: allocation.color) {
                    line = existing
                } else {
                    let created = StockLine(color: allocation.color, packs: 0)
                    model.addLine(created)
                    line = created
                }

                line.withdraw(allocation.packs)
                context.insert(
                    StockMovement(
                        date: date,
                        modelCode: model.code,
                        color: line.color,
                        packs: -allocation.packs,
                        kind: .shipped,
                        context: invoice.receiver
                    )
                )
                invoice.recordShipment(
                    ShipmentLine(modelCode: model.code, color: line.color, packs: allocation.packs)
                )
            }
        }

        invoice.status = .shipped
        invoice.shippedAt = date
    }

    @discardableResult
    static func wipe(context: ModelContext) throws -> String {
        let invoices = try context.fetch(FetchDescriptor<Invoice>())
        for invoice in invoices {
            if let fileName = invoice.pdfFileName {
                PDFStorage.deletePDF(fileName: fileName)
            }
            context.delete(invoice)
        }
        for model in try context.fetch(FetchDescriptor<StockModel>()) {
            context.delete(model)
        }
        for contact in try context.fetch(FetchDescriptor<Contact>()) {
            context.delete(contact)
        }
        for movement in try context.fetch(FetchDescriptor<StockMovement>()) {
            context.delete(movement)
        }
        for row in try context.fetch(FetchDescriptor<ItemRow>()) {
            context.delete(row)
        }
        for line in try context.fetch(FetchDescriptor<ShipmentLine>()) {
            context.delete(line)
        }
        for line in try context.fetch(FetchDescriptor<StockLine>()) {
            context.delete(line)
        }

        try context.save()
        AppLog.data.debug("Debug wipe removed everything")
        return "Removed \(invoices.count) invoices and everything else"
    }
}

private struct Seeded: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
#endif
