//
//  ShipmentPlanner.swift
//  Turns an invoice into the list of packs that should leave the shelf, and
//  puts them back if the invoice is pulled out of shipped again. An invoice
//  row names a model and carries her own per-color pack counts, which is what
//  gets deducted; a row saved before those counts existed falls back to an even
//  spread of its unit count. Nothing downstream may alter the plan: the sheet
//  that shows it is read-only, because the invoice is the document the customer
//  receives and the shelf has to agree with it.
//  Matching a row to a model tries the row name as a code first, then looks
//  for a four-digit code inside it, which is what makes a row typed as
//  "Cotton Tee 2337" still find model 2337. A row that matches nothing is
//  carried through as unmatched rather than dropped, so the sheet can say so
//  instead of quietly shipping nothing.
//  Applying is deliberate about order: stock is moved and the exact packs are
//  written onto the invoice in the same pass, so reverting later replays that
//  record rather than recomputing a plan that the rows may no longer produce.
//  Used by: ShipmentSheet, InvoiceDetailView.
//

import Foundation
import SwiftData

struct ShipmentDraft: Identifiable {
    let id = UUID()
    let itemName: String
    let modelCode: String?
    let availableColors: [String]
    var color: String
    var packs: Int

    var isMatched: Bool { modelCode != nil }
    var needsColor: Bool { isMatched && color.isEmpty }
    var isActionable: Bool { isMatched && !color.isEmpty && packs > 0 }
}

@MainActor
enum ShipmentPlanner {

    static func plan(for invoice: Invoice, stock: [StockModel]) -> [ShipmentDraft] {
        invoice.orderedItems.flatMap { item -> [ShipmentDraft] in
            let requested = Int(item.unitCount)
            guard let model = match(name: item.name, in: stock) else {
                return [
                    ShipmentDraft(
                        itemName: item.name,
                        modelCode: nil,
                        availableColors: [],
                        color: "",
                        packs: requested
                    )
                ]
            }

            let known = model.orderedLines.map(\.color)
            let colors = item.colors.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            guard !colors.isEmpty else {
                return [
                    ShipmentDraft(
                        itemName: item.name,
                        modelCode: model.code,
                        availableColors: known,
                        color: "",
                        packs: requested
                    )
                ]
            }

            return ItemRow.breakdown(colors: colors, packs: item.colorPacks, total: requested).map { allocation in
                ShipmentDraft(
                    itemName: item.name,
                    modelCode: model.code,
                    availableColors: known,
                    color: allocation.color,
                    packs: allocation.packs
                )
            }
        }
    }

    static func available(_ draft: ShipmentDraft, in stock: [StockModel]) -> Int? {
        guard let code = draft.modelCode, !draft.color.isEmpty else { return nil }
        guard let model = stock.first(where: { $0.code == code }) else { return nil }
        return model.line(for: draft.color)?.packs ?? 0
    }

    @discardableResult
    static func apply(_ drafts: [ShipmentDraft], to invoice: Invoice, stock: [StockModel], context: ModelContext) throws -> Int {
        var shortfall = 0

        for draft in drafts where draft.isActionable {
            guard let code = draft.modelCode,
                  let model = stock.first(where: { $0.code == code }) else { continue }

            let line: StockLine
            if let existing = model.line(for: draft.color) {
                line = existing
            } else {
                let created = StockLine(color: draft.color, packs: 0)
                model.addLine(created)
                line = created
            }

            shortfall += line.withdraw(draft.packs)
            context.insert(
                StockMovement(
                    modelCode: code,
                    color: line.color,
                    packs: -draft.packs,
                    kind: .shipped,
                    context: invoice.receiver.isEmpty ? nil : invoice.receiver
                )
            )
            invoice.recordShipment(
                ShipmentLine(modelCode: code, color: line.color, packs: draft.packs)
            )
        }

        invoice.status = .shipped
        invoice.shippedAt = .now
        try context.save()

        return shortfall
    }

    static func revert(_ invoice: Invoice, stock: [StockModel], context: ModelContext) throws {
        for line in invoice.shipment {
            guard let model = stock.first(where: { $0.code == line.modelCode }) else { continue }
            if let stockLine = model.line(for: line.color) {
                stockLine.receive(line.packs)
            } else {
                model.addLine(StockLine(color: line.color, packs: line.packs))
            }
            context.insert(
                StockMovement(
                    modelCode: line.modelCode,
                    color: line.color,
                    packs: line.packs,
                    kind: .returned,
                    context: invoice.receiver.isEmpty ? nil : invoice.receiver
                )
            )
        }

        for line in invoice.shipment {
            context.delete(line)
        }
        invoice.clearShipment()
        invoice.status = .draft
        invoice.shippedAt = nil
        try context.save()
    }

    private static func match(name: String, in stock: [StockModel]) -> StockModel? {
        if let code = StockModel.normalizedCode(name),
           let model = stock.first(where: { $0.code == code }) {
            return model
        }

        for token in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
            if let code = StockModel.normalizedCode(String(token)),
               let model = stock.first(where: { $0.code == code }) {
                return model
            }
        }

        return nil
    }

}
