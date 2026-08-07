//
//  StatisticsViewModel.swift
//  Reads the invoices back rather than keeping running totals: nothing is
//  written down as it happens, so a number here can never drift from the
//  documents it claims to describe, and a corrected invoice corrects the
//  figures the moment it is saved. At the size this business works at, a
//  handful of hundreds of invoices, counting them all on every redraw costs
//  less than keeping a second set of books honest.
//  Money counts every invoice, draft or shipped, because a draft is a sale she
//  has already agreed to; the split is reported so she can see how much of the
//  total has not left the shelf yet. Anything about packs moving counts only
//  shipped invoices, since a draft has taken nothing.
//  Customers are grouped by the contact an invoice was addressed to when there
//  is one and by the typed name when there is not, which is what makes older
//  invoices written before the address book still count towards somebody.
//  Holds no models of its own, the view owns the @Query and hands them in.
//  Used by: StatisticsView.
//

import SwiftUI
import SwiftData
import Combine

enum StatsPeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case thisYear
    case everything

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thisMonth:  return L.t(.thisMonth)
        case .lastMonth:  return L.t(.lastMonth)
        case .thisYear:   return L.t(.thisYear)
        case .everything: return L.t(.everything)
        }
    }

    func contains(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .everything:
            return true
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .lastMonth:
            guard let previous = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: previous, toGranularity: .month)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

struct StatsEntry: Identifiable {
    let id: String
    let name: String
    let detail: String?
    let amount: Double
    let count: Int
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var period: StatsPeriod = .thisMonth

    func invoices(_ all: [Invoice]) -> [Invoice] {
        all.filter { period.contains($0.date) }
    }

    func revenue(_ invoices: [Invoice]) -> Double {
        invoices.reduce(0) { $0 + $1.totalInvoicePrice }
    }

    func revenue(_ invoices: [Invoice], status: InvoiceStatus) -> Double {
        invoices.filter { $0.status == status }.reduce(0) { $0 + $1.totalInvoicePrice }
    }

    func averageInvoice(_ invoices: [Invoice]) -> Double {
        guard !invoices.isEmpty else { return 0 }
        return revenue(invoices) / Double(invoices.count)
    }

    func packsShipped(_ invoices: [Invoice]) -> Int {
        invoices
            .filter { $0.status == .shipped }
            .flatMap(\.shipment)
            .reduce(0) { $0 + $1.packs }
    }

    func topCustomers(_ invoices: [Invoice], limit: Int = 5) -> [StatsEntry] {
        var totals: [String: (name: String, detail: String?, amount: Double, count: Int)] = [:]

        for invoice in invoices {
            let key: String
            let name: String
            let detail: String?

            if let contact = invoice.receiverContact {
                key = "contact:\(contact.persistentModelID)"
                name = contact.displayName
                detail = contact.whereTo.isEmpty ? nil : contact.whereTo
            } else {
                let typed = invoice.receiver.trimmingCharacters(in: .whitespaces)
                guard !typed.isEmpty else { continue }
                key = typed.lowercased()
                name = typed
                detail = nil
            }

            let existing = totals[key]
            totals[key] = (
                name: name,
                detail: detail ?? existing?.detail,
                amount: (existing?.amount ?? 0) + invoice.totalInvoicePrice,
                count: (existing?.count ?? 0) + 1
            )
        }

        return rank(totals, limit: limit)
    }

    func topModels(_ invoices: [Invoice], limit: Int = 5) -> [StatsEntry] {
        var totals: [String: (name: String, detail: String?, amount: Double, count: Int)] = [:]

        for item in invoices.flatMap(\.orderedItems) {
            let name = item.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            let key = name.lowercased()
            let existing = totals[key]
            totals[key] = (
                name: existing?.name ?? name,
                detail: nil,
                amount: (existing?.amount ?? 0) + item.totalForItem,
                count: (existing?.count ?? 0) + Int(item.unitCount)
            )
        }

        return rank(totals, limit: limit)
    }

    func stockValue(_ models: [StockModel]) -> (value: Double, priced: Int, unpriced: Int) {
        let piecesPerPack = max(1, AppSettings.defaultItemsPerUnit)
        var value: Double = 0
        var priced = 0
        var unpriced = 0

        for model in models {
            guard model.hasPrice else {
                if model.totalPacks > 0 { unpriced += 1 }
                continue
            }
            priced += 1
            value += Double(model.totalPacks) * Double(piecesPerPack) * model.pricePerPiece
        }

        return (value, priced, unpriced)
    }

    private func rank(
        _ totals: [String: (name: String, detail: String?, amount: Double, count: Int)],
        limit: Int
    ) -> [StatsEntry] {
        var entries: [StatsEntry] = []
        entries.reserveCapacity(totals.count)

        for (key, value) in totals {
            entries.append(
                StatsEntry(
                    id: key,
                    name: value.name,
                    detail: value.detail,
                    amount: value.amount,
                    count: value.count
                )
            )
        }

        entries.sort { lhs, rhs in
            if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
            return lhs.name < rhs.name
        }

        return Array(entries.prefix(limit))
    }
}
