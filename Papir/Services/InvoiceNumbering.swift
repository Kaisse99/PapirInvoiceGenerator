//
//  InvoiceNumbering.swift
//  Hands out the number an invoice is referred to by, once, when it is first
//  saved. One running sequence over the whole store rather than one per year:
//  a year-reset sequence needs a rule for what happens to an invoice dated in
//  December and written in January, and she would rather have a number that is
//  never ambiguous than one that is tidy.
//
//  next is max + 1 rather than count + 1, because deleting an invoice must not
//  hand its number to the next one written. Numbers therefore have gaps, which
//  is correct: a gap says a document was cancelled, and a sequence that closed
//  its gaps would quietly claim it never existed.
//
//  backfill numbers the invoices written before this existed, in date order so
//  the oldest gets one, and runs once. It is guarded by a flag rather than by
//  looking for zeroes, because an invoice restored from an old backup will
//  also carry zero and must not renumber the whole book behind her.
//  Used by: NewInvoiceViewModel, PapirApp, Backup.
//

import Foundation
import os
import SwiftData

@MainActor
enum InvoiceNumbering {
    static let backfilledKey = "invoiceNumbersBackfilled"

    static func next(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<Invoice>(
            sortBy: [SortDescriptor(\.number, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            let highest = try context.fetch(descriptor).first?.number ?? 0
            return max(0, highest) + 1
        } catch {
            AppLog.data.error("Could not read the highest invoice number: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    static func assignIfNeeded(_ invoice: Invoice, in context: ModelContext) {
        guard !invoice.hasNumber else { return }
        invoice.number = next(in: context)
    }

    @discardableResult
    static func backfill(context: ModelContext) -> Int {
        guard !UserDefaults.standard.bool(forKey: backfilledKey) else { return 0 }

        do {
            let invoices = try context.fetch(
                FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.date)])
            )
            var next = invoices.map(\.number).max().map { max(0, $0) + 1 } ?? 1
            var numbered = 0
            for invoice in invoices where !invoice.hasNumber {
                invoice.number = next
                next += 1
                numbered += 1
            }

            if numbered > 0 {
                try context.save()
                AppLog.data.notice("Backfilled \(numbered) invoice numbers")
            }
            UserDefaults.standard.set(true, forKey: backfilledKey)
            return numbered
        } catch {
            AppLog.data.error("Invoice number backfill failed: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }
}
