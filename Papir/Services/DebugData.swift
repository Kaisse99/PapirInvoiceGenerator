//
//  DebugData.swift
//  A shelf and most of a year of trade, invented, so every screen can be
//  looked at full instead of empty and so the App Store screenshots show an
//  app that has clearly been used.
//
//  The whole file sits inside #if DEBUG. That is the point, not a formality:
//  it is not hidden behind a gesture or a tap count, it is not compiled into a
//  Release build at all, so there is no button for a customer to find by
//  accident and no code path for them to reach if they did. Anything added
//  here must stay inside the same fence.
//
//  The data is deliberately presentable rather than merely plausible. Three
//  rules come from that, and each of them is a constraint the old seeder broke:
//
//  Nothing goes negative. Stock is tracked as it is spent, and a row can never
//  ask for more packs than the shelf still holds, so shipping deducts without
//  ever pushing a colour under zero. A screenshot full of red minus signs
//  advertises a shop that has lost count of itself.
//
//  The shelf shows its whole range. Most colours end healthy, a few are walked
//  down to under five so the low state appears, and a couple are taken to
//  exactly zero so the out state does too. Those last moves are recorded as
//  recounts, which is a thing that really happens, rather than written straight
//  into the count behind the log's back.
//
//  Most of it has shipped. Statistics counts shipped invoices only, so a book
//  of drafts leaves every chart empty; five in six are marked shipped, spread
//  across ten months so the month picker, the chart and the rankings all have
//  something to say.
//
//  Filling twice must not double the shelf: a code already on it is reused
//  rather than added again, because two models with one code is exactly the
//  state the stock screen refuses to let anyone create by hand.
//
//  Text is written in plain English rather than through LKey, because nobody
//  who is not the developer will ever read it.
//  Used by: SettingsSheet, in debug builds only.
//

#if DEBUG
import Foundation
import os
import SwiftData

@MainActor
enum DebugData {
    private static let models: [(code: String, price: Int)] = [
        ("1987 Hoodie", 34), ("2337 T-Shirt", 12), ("9813 Cap", 9),
        ("4402 Denim Jacket", 48), ("6395 Sweatpants", 26), ("7710 Polo", 18),
        ("3128 Windbreaker", 39), ("5567 Crewneck", 29), ("8021 Beanie", 8),
        ("2244 Chinos", 31), ("6688 Overshirt", 42), ("1450 Long Sleeve", 16),
        ("7104 Zip Hoodie", 44), ("3390 Shorts", 21)
    ]

    private static let colors = [
        "Black", "White", "Grey", "Navy", "Beige",
        "Olive", "Cream", "Rust", "Charcoal", "Sand"
    ]

    private static let firstNames = [
        "Emma", "Olivia", "Ava", "Sophia", "Isabella",
        "Mia", "Charlotte", "Amelia", "Harper", "Evelyn"
    ]

    private static let lastNames = [
        "Johnson", "Smith", "Brown", "Davis", "Miller",
        "Wilson", "Moore", "Taylor", "Anderson", "Thomas"
    ]

    private static let cities = [
        "Austin", "Denver", "Portland", "Nashville", "Boise",
        "Raleigh", "Tucson", "Omaha", "Boulder", "Savannah"
    ]

    private static let streets = [
        "Oak St", "Maple Ave", "Cedar Rd", "Pine St", "Birch Ln",
        "Elm St", "Walnut Ave", "Aspen Way", "Chestnut St", "Willow Rd"
    ]

    @discardableResult
    static func populate(context: ModelContext) throws -> String {
        var rng = Seeded(seed: 20260808)
        let calendar = Calendar.current

        // ---- customers ----
        var contacts: [Contact] = []
        for index in 0..<10 {
            let contact = Contact(
                firstName: firstNames[index],
                lastName: lastNames[index],
                phone: "(\(Int.random(in: 201...989))) \(Int.random(in: 200...999))-\(String(format: "%04d", Int.random(in: 0...9999, using: &rng)))",
                city: cities[index],
                shipmentAddress: "\(Int.random(in: 100...4800, using: &rng)) \(streets[index])"
            )
            context.insert(contact)
            contacts.append(contact)
        }

        // ---- the shelf, stocked generously so shipping never bites through ----
        let existing = (try? context.fetch(FetchDescriptor<StockModel>())) ?? []
        var shelf: [StockModel] = []
        var onHand: [String: Int] = [:]          // "code|colour" -> packs left
        let received = calendar.date(byAdding: .day, value: -320, to: .now) ?? .now

        for entry in models {
            if let already = existing.first(where: { $0.code.caseInsensitiveCompare(entry.code) == .orderedSame }) {
                shelf.append(already)
                for line in already.allLines { onHand["\(already.code)|\(line.color)"] = max(0, line.packs) }
                continue
            }

            let palette = Array(colors.shuffled(using: &rng).prefix(Int.random(in: 3...5, using: &rng)))
            let lines = palette.map { StockLine(color: $0, packs: Int.random(in: 90...240, using: &rng)) }
            let model = StockModel(
                code: entry.code,
                pricePerPiece: Double(entry.price),
                piecesPerPack: max(1, AppSettings.defaultItemsPerUnit),
                lines: lines
            )
            context.insert(model)
            shelf.append(model)

            for line in lines {
                onHand["\(entry.code)|\(line.color)"] = line.packs
                context.insert(
                    StockMovement(
                        date: received,
                        modelCode: entry.code,
                        color: line.color,
                        packs: line.packs,
                        kind: .received
                    )
                )
            }
        }

        // ---- ten months of trade ----
        var invoiceCount = 0, shippedCount = 0
        var nextNumber = InvoiceNumbering.next(in: context)
        let currency = AppSettings.currency.rawValue
        let sender = AppSettings.defaultSender.isEmpty ? "Papir" : AppSettings.defaultSender

        for daysAgo in stride(from: 300, through: 0, by: -1) {
            guard Int.random(in: 0...2, using: &rng) == 0 else { continue }
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }

            // nine in ten ship, so statistics has something to count. It lands
            // nearer eighty-five once the few that lose every row to an empty
            // colour drop out, which only ever removes a shipped one.
            let ships = Int.random(in: 0...9, using: &rng) > 0
            let contact = contacts.randomElement(using: &rng)

            var rows: [ItemRow] = []
            for _ in 0..<Int.random(in: 1...4, using: &rng) {
                guard let model = shelf.randomElement(using: &rng) else { continue }
                let palette = model.orderedLines.map(\.color).shuffled(using: &rng)
                var chosen: [String] = []
                var packs: [Int] = []

                for colour in palette.prefix(Int.random(in: 1...3, using: &rng)) {
                    let key = "\(model.code)|\(colour)"
                    let available = ships ? (onHand[key] ?? 0) : Int.max
                    guard available > 0 else { continue }
                    let take = min(Int.random(in: 1...7, using: &rng), available)
                    chosen.append(colour)
                    packs.append(take)
                    if ships { onHand[key] = available - take }
                }

                guard !chosen.isEmpty else { continue }
                let row = ItemRow(
                    name: model.code,
                    unitCount: UInt16(packs.reduce(0, +)),
                    itemsPerUnit: UInt16(max(1, AppSettings.defaultItemsPerUnit)),
                    price: model.pricePerPiece,
                    colors: chosen
                )
                row.colorPacks = packs
                rows.append(row)
            }

            guard !rows.isEmpty else { continue }

            let invoice = Invoice(
                items: rows,
                date: date,
                sender: sender,
                receiver: contact?.displayName ?? "Walk-in"
            )
            invoice.receiverContact = contact
            invoice.receiverContactID = contact?.identifier
            invoice.currencyCode = currency
            invoice.number = nextNumber
            nextNumber += 1
            context.insert(invoice)
            invoiceCount += 1

            if ships {
                ship(invoice, shelf: shelf, date: date, context: context)
                shippedCount += 1
            }
        }

        // ---- leave the shelf showing every state it can be in ----
        showEveryStockState(shelf, context: context, rng: &rng)

        try context.save()
        AppLog.data.debug("Debug data populated: \(invoiceCount) invoices, \(shippedCount) shipped")
        return "\(invoiceCount) invoices · \(shippedCount) shipped · \(shelf.count) models · \(contacts.count) contacts"
    }

    /// Walks a handful of colours down to under five and a couple to zero, so
    /// the low and out states appear on screen. Recorded as recounts, because
    /// that is the operation a person would actually perform.
    private static func showEveryStockState(_ shelf: [StockModel], context: ModelContext, rng: inout Seeded) {
        let lines = shelf.flatMap { model in model.allLines.map { (model, $0) } }
            .filter { $0.1.packs > 6 }
            .shuffled(using: &rng)

        for (index, pair) in lines.prefix(7).enumerated() {
            let (model, line) = pair
            let target = index < 2 ? 0 : Int.random(in: 1...4, using: &rng)
            let delta = target - line.packs
            line.recount(to: target)
            context.insert(
                StockMovement(
                    date: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...20, using: &rng), to: .now) ?? .now,
                    modelCode: model.code,
                    color: line.color,
                    packs: delta,
                    kind: .recounted
                )
            )
        }
    }

    private static func ship(_ invoice: Invoice, shelf: [StockModel], date: Date, context: ModelContext) {
        for item in invoice.orderedItems {
            guard let model = shelf.first(where: { $0.code.caseInsensitiveCompare(item.name) == .orderedSame }) else { continue }

            for allocation in item.colorBreakdown where allocation.packs > 0 {
                guard let line = model.line(for: allocation.color) else { continue }
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
