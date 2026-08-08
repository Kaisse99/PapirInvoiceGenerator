//
//  StatisticsViewModel.swift
//  Reads the invoices back rather than keeping running totals: nothing is
//  written down as it happens, so a number here can never drift from the
//  documents it claims to describe, and a corrected invoice corrects the
//  figures the moment it is saved. At the size this business works at, a
//  handful of hundreds of invoices, counting them all on every redraw costs
//  less than keeping a second set of books honest.
//  Everything here counts shipped invoices only. A draft is an intention, not
//  money, and putting the two in one figure taught the screen to flatter; the
//  drafts are simply absent rather than shown and subtracted.
//  Only invoices written in the currency now selected are counted, because an
//  invoice carries the currency it was written in and summing two of them
//  produces a number that is true in neither. Any that are left out are
//  counted and said out loud under the total rather than quietly dropped.
//  The period is a concrete month picked from the months that actually hold
//  invoices, or the year, or everything. The chart series is zero-filled
//  across its whole span, day by day inside a month and month by month above
//  that, because a line that skips empty days lies about the pace.
//  Models are grouped through the same matcher that decides what a row takes
//  off the shelf, so a row typed "Cotton Tee 2337" counts under 2337 rather
//  than forming a rank of its own. Grouping on the raw name meant shipping and
//  statistics disagreed about what a row was, and a model's takings could sit
//  split across two entries while stock deducted them from one. A row matching
//  no model still groups under its own trimmed name. They carry their colour
//  breakdown summed across rows, so one card can say both what a model earned
//  and which colours of it actually went.
//  Buyers are grouped by the contact an invoice was addressed to when there is
//  one, then by the id copied onto the invoice when that contact has since
//  been deleted, and only then by the typed name. Falling straight to the name
//  merged two different customers who happened to share one the moment either
//  was deleted; the copied id keeps them apart for good. Invoices written
//  before the address book existed still count towards somebody by name.
//  Holds no models of its own, the view owns the @Query and hands them in.
//  Used by: StatisticsView.
//

import SwiftUI
import SwiftData
import Combine

enum StatsPeriod: Hashable {
    case month(Date)
    case thisYear
    case everything

    var title: String {
        switch self {
        case .month(let anchor): return Self.monthTitle(anchor)
        case .thisYear:          return L.t(.thisYear)
        case .everything:        return L.t(.everything)
        }
    }

    var bucketsByMonth: Bool {
        if case .month = self { return false }
        return true
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .everything:
            return true
        case .thisYear:
            return calendar.isDate(date, equalTo: .now, toGranularity: .year)
        case .month(let anchor):
            return calendar.isDate(date, equalTo: anchor, toGranularity: .month)
        }
    }

    static func currentMonth(calendar: Calendar = .current) -> StatsPeriod {
        .month(startOfMonth(.now, calendar: calendar))
    }

    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func monthTitle(_ anchor: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppSettings.language.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: anchor).capitalized
    }
}

struct StatsPoint: Identifiable {
    let date: Date
    let amount: Double

    var id: Date { date }
}

struct ModelStat: Identifiable {
    let id: String
    let name: String
    let money: Double
    let packs: Int
    let colors: [ColorAllocation]
}

struct BuyerStat: Identifiable {
    let id: String
    let name: String
    let detail: String?
    let money: Double
    let invoices: Int
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var period: StatsPeriod = .currentMonth()

    func availableMonths(_ all: [Invoice], calendar: Calendar = .current, limit: Int = 12) -> [Date] {
        var months = Set(all.map { StatsPeriod.startOfMonth($0.date, calendar: calendar) })
        months.insert(StatsPeriod.startOfMonth(.now, calendar: calendar))
        return Array(months.sorted(by: >).prefix(limit))
    }

    func shipped(_ all: [Invoice]) -> [Invoice] {
        all.filter { $0.status == .shipped && period.contains($0.date) && $0.currency == AppSettings.currency }
    }

    /// Shipped invoices in the period written in some other currency. Adding
    /// them to the total would be adding hryvnia to dollars, so they are left
    /// out and counted here instead, because silently dropping money is the
    /// one thing worse than not showing it.
    func inAnotherCurrency(_ all: [Invoice]) -> Int {
        all.filter { $0.status == .shipped && period.contains($0.date) && $0.currency != AppSettings.currency }.count
    }

    func revenue(_ shipped: [Invoice]) -> Double {
        shipped.reduce(0) { $0 + $1.totalInvoicePrice }
    }

    func averageInvoice(_ shipped: [Invoice]) -> Double {
        guard !shipped.isEmpty else { return 0 }
        return revenue(shipped) / Double(shipped.count)
    }

    func packsSold(_ shipped: [Invoice]) -> Int {
        shipped.flatMap(\.orderedItems).reduce(0) { $0 + Int($1.unitCount) }
    }

    func series(_ shipped: [Invoice], calendar: Calendar = .current) -> [StatsPoint] {
        let byMonth = period.bucketsByMonth
        var totals: [Date: Double] = [:]
        for invoice in shipped {
            let key = byMonth
                ? StatsPeriod.startOfMonth(invoice.date, calendar: calendar)
                : calendar.startOfDay(for: invoice.date)
            totals[key, default: 0] += invoice.totalInvoicePrice
        }

        guard let domain = bucketDomain(shipped, calendar: calendar) else { return [] }
        let step: Calendar.Component = byMonth ? .month : .day

        var points: [StatsPoint] = []
        var cursor = domain.lowerBound
        while cursor <= domain.upperBound {
            points.append(StatsPoint(date: cursor, amount: totals[cursor] ?? 0))
            guard let next = calendar.date(byAdding: step, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    func modelStats(_ shipped: [Invoice], stock: [StockModel] = []) -> [ModelStat] {
        var order: [String] = []
        var names: [String: String] = [:]
        var money: [String: Double] = [:]
        var packs: [String: Int] = [:]
        var colorPacks: [String: [String: Int]] = [:]
        var colorNames: [String: [String: String]] = [:]

        for item in shipped.flatMap(\.orderedItems) {
            let trimmed = ShipmentPlanner.canonicalName(for: item.name, in: stock)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()

            if names[key] == nil {
                order.append(key)
                names[key] = trimmed
            }
            money[key, default: 0] += item.totalForItem
            packs[key, default: 0] += Int(item.unitCount)

            for allocation in item.colorBreakdown where allocation.packs > 0 {
                let colorKey = allocation.color.lowercased()
                colorPacks[key, default: [:]][colorKey, default: 0] += allocation.packs
                if colorNames[key]?[colorKey] == nil {
                    colorNames[key, default: [:]][colorKey] = allocation.color
                }
            }
        }

        var stats: [ModelStat] = []
        stats.reserveCapacity(order.count)

        for key in order {
            let packsByColor: [String: Int] = colorPacks[key] ?? [:]
            let casing: [String: String] = colorNames[key] ?? [:]

            var colors: [ColorAllocation] = []
            colors.reserveCapacity(packsByColor.count)
            for (colorKey, count) in packsByColor {
                colors.append(ColorAllocation(color: casing[colorKey] ?? colorKey, packs: count))
            }
            colors.sort { lhs, rhs in
                if lhs.packs != rhs.packs { return lhs.packs > rhs.packs }
                return lhs.color < rhs.color
            }

            stats.append(
                ModelStat(
                    id: key,
                    name: names[key] ?? key,
                    money: money[key] ?? 0,
                    packs: packs[key] ?? 0,
                    colors: colors
                )
            )
        }

        return stats
    }

    func byProfit(_ shipped: [Invoice], stock: [StockModel] = []) -> [ModelStat] {
        modelStats(shipped, stock: stock)
            .sorted { $0.money == $1.money ? $0.name < $1.name : $0.money > $1.money }
    }

    func mostProfitable(_ shipped: [Invoice], limit: Int = 5) -> [ModelStat] {
        Array(byProfit(shipped).prefix(limit))
    }

    func mostSold(_ shipped: [Invoice], limit: Int = 5) -> [ModelStat] {
        Array(
            modelStats(shipped)
                .sorted { $0.packs == $1.packs ? $0.name < $1.name : $0.packs > $1.packs }
                .prefix(limit)
        )
    }

    func allBuyers(_ shipped: [Invoice]) -> [BuyerStat] {
        topBuyers(shipped, limit: Int.max)
    }

    func topBuyers(_ shipped: [Invoice], limit: Int = 5) -> [BuyerStat] {
        var order: [String] = []
        var names: [String: String] = [:]
        var details: [String: String] = [:]
        var money: [String: Double] = [:]
        var counts: [String: Int] = [:]

        for invoice in shipped {
            let key: String
            let name: String
            let detail: String?

            if let contact = invoice.receiverContact {
                key = "contact:\(contact.identifier.uuidString)"
                name = contact.displayName
                detail = contact.whereTo.isEmpty ? nil : contact.whereTo
            } else if let stored = invoice.receiverContactID {
                key = "contact:\(stored.uuidString)"
                name = invoice.receiver.trimmingCharacters(in: .whitespaces).isEmpty
                    ? L.t(.noReceiver)
                    : invoice.receiver
                detail = nil
            } else {
                let typed = invoice.receiver.trimmingCharacters(in: .whitespaces)
                key = typed.isEmpty ? "none" : typed.lowercased()
                name = typed.isEmpty ? L.t(.noReceiver) : typed
                detail = nil
            }

            if names[key] == nil {
                order.append(key)
                names[key] = name
            }
            if let detail, details[key] == nil {
                details[key] = detail
            }
            money[key, default: 0] += invoice.totalInvoicePrice
            counts[key, default: 0] += 1
        }

        var buyers: [BuyerStat] = []
        buyers.reserveCapacity(order.count)

        for key in order {
            buyers.append(
                BuyerStat(
                    id: key,
                    name: names[key] ?? key,
                    detail: details[key],
                    money: money[key] ?? 0,
                    invoices: counts[key] ?? 0
                )
            )
        }

        buyers.sort { lhs, rhs in
            if lhs.money != rhs.money { return lhs.money > rhs.money }
            return lhs.name < rhs.name
        }

        return Array(buyers.prefix(limit))
    }

    func stockValue(_ models: [StockModel]) -> (value: Double, priced: Int, unpriced: Int) {
        var value: Double = 0
        var priced = 0
        var unpriced = 0

        for model in models {
            guard model.hasPrice else {
                if model.totalPacks > 0 { unpriced += 1 }
                continue
            }
            priced += 1
            value += model.shelfValue
        }

        return (value, priced, unpriced)
    }

    func unitsInStock(_ models: [StockModel]) -> Int {
        models.reduce(0) { $0 + $1.unitsOnShelf }
    }

    private func bucketDomain(_ shipped: [Invoice], calendar: Calendar) -> ClosedRange<Date>? {
        let today = calendar.startOfDay(for: .now)
        let currentMonth = StatsPeriod.startOfMonth(today, calendar: calendar)

        switch period {
        case .month(let anchor):
            if calendar.isDate(anchor, equalTo: today, toGranularity: .month) {
                return anchor <= today ? anchor...today : nil
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: anchor),
                  let last = calendar.date(byAdding: .day, value: -1, to: next),
                  anchor <= last else { return nil }
            return anchor...last

        case .thisYear:
            guard let january = calendar.date(from: calendar.dateComponents([.year], from: today)),
                  january <= currentMonth else { return nil }
            return january...currentMonth

        case .everything:
            let earliest = shipped.map(\.date).min() ?? today
            var first = StatsPeriod.startOfMonth(earliest, calendar: calendar)
            if first >= currentMonth,
               let padded = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
                first = padded
            }
            return first <= currentMonth ? first...currentMonth : nil
        }
    }
}
