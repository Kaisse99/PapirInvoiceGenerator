//
//  Invoice.swift
//  One saved invoice: its two parties, its date, its rows, and the name of the
//  PDF rendered from it (nil until one exists). Owns the row numbering: every
//  path that sets items runs through init or replaceItems, which stamp each row
//  with its position, and every path that reads them for display reads
//  orderedItems. Rows saved before sortIndex existed all carry 0 and fall back
//  to a name tiebreak, so they keep one settled order instead of reshuffling.
//  InvoiceSnapshot is the frozen, Sendable copy handed to PDF rendering, which
//  runs off the main thread where touching the model itself would be unsafe.
//  Both replaceItems and clearShipment delete what they drop rather than just
//  unhooking it. A row cut from an edited invoice is reachable from nothing
//  once the array no longer holds it, so leaving it behind would pile up dead
//  rows in the store forever, and with iCloud on it would sync them too.
//  An invoice is a draft until it is marked shipped, and marking it shipped is
//  the only thing that moves stock. What came off the shelf is written down as
//  ShipmentLines on the invoice itself rather than inferred later, because the
//  rows can be edited afterwards and the only honest way to put stock back is
//  to put back exactly what was taken. Status and the shipment lines are both
//  stored optional and read through accessors that supply the default, because
//  SwiftData does not backfill a property's default onto rows that already
//  exist: a non-optional enum would come back null on every older invoice and
//  trap the moment anything read it.
//  receiverContact is who the receiver was picked from in the address book,
//  and is nil whenever the name was simply typed. The sender has no such link
//  on purpose: it is always whoever is holding the phone, prefilled from a
//  name kept in settings, and nothing about the business is worth counting by.
//  The receiver string stays the record of what the document says; the link is
//  there so counting by customer is a relationship rather than a string match,
//  and so the PDF can print the city, branch and phone underneath the name
//  without the invoice storing a second copy of them.
//  Used by: NewInvoiceViewModel, MyInvoicesViewModel, InvoiceDetailViewModel,
//  ShipmentPlanner, PDFGenerator, PDFStorage, MyInvoicesView,
//  InvoiceDetailView, InvoiceRowItem.
//

import Foundation
import SwiftData

@Model
final class Invoice {
    @Relationship(deleteRule: .cascade, inverse: \ItemRow.invoice)
    var items: [ItemRow]? = nil
    var id: UUID = UUID()
    var date: Date = Date.now
    var sender: String = ""
    var receiver: String = ""
    var pdfFileName: String? = nil
    var statusRaw: String? = nil
    var shippedAt: Date? = nil
    @Relationship(deleteRule: .cascade, inverse: \ShipmentLine.invoice)
    var shipmentLines: [ShipmentLine]? = nil
    var receiverContact: Contact? = nil

    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRaw ?? "") ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var shipment: [ShipmentLine] {
        shipmentLines ?? []
    }

    init(items: [ItemRow], date: Date = .now, sender: String, receiver: String, pdfFileName: String? = nil) {
        self.items = Invoice.numbered(items)
        self.date = date
        self.sender = sender
        self.receiver = receiver
        self.pdfFileName = pdfFileName
    }

    var allItems: [ItemRow] {
        items ?? []
    }

    var orderedItems: [ItemRow] {
        allItems.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var totalInvoicePrice: Double {
        allItems.reduce(0) { $0 + $1.totalForItem }
    }

    var snapshot: InvoiceSnapshot {
        InvoiceSnapshot(
            id: id,
            date: date,
            sender: sender,
            receiver: receiver,
            receiverDetails: receiverContact?.documentLines ?? [],
            items: orderedItems.map {
                InvoiceSnapshot.Item(
                    name: $0.name,
                    unitCount: $0.unitCount,
                    itemsPerUnit: $0.itemsPerUnit,
                    price: $0.price,
                    colors: $0.colors,
                    colorBreakdown: $0.colorBreakdown
                )
            }
        )
    }

    func replaceItems(with newItems: [ItemRow]) {
        let kept = Set(newItems.map(\.persistentModelID))
        let discarded = allItems.filter { !kept.contains($0.persistentModelID) }
        items = Invoice.numbered(newItems)
        for row in discarded {
            modelContext?.delete(row)
        }
    }

    func recordShipment(_ line: ShipmentLine) {
        if shipmentLines == nil { shipmentLines = [] }
        shipmentLines?.append(line)
    }

    func clearShipment() {
        let discarded = shipment
        shipmentLines = []
        for line in discarded {
            modelContext?.delete(line)
        }
    }

    private static func numbered(_ items: [ItemRow]) -> [ItemRow] {
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
        return items
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft
    case shipped
}

@Model
final class ShipmentLine {
    var modelCode: String = ""
    var color: String = ""
    var packs: Int = 0
    var invoice: Invoice? = nil

    init(modelCode: String, color: String, packs: Int) {
        self.modelCode = modelCode
        self.color = color
        self.packs = packs
    }
}

nonisolated struct InvoiceSnapshot: Sendable {
    struct Item: Sendable {
        let name: String
        let unitCount: UInt16
        let itemsPerUnit: UInt16
        let price: Double
        let colors: [String]
        let colorBreakdown: [ColorAllocation]

        var totalForItem: Double {
            Double(unitCount) * Double(itemsPerUnit) * price
        }
    }

    let id: UUID
    let date: Date
    let sender: String
    let receiver: String
    let receiverDetails: [String]
    let items: [Item]

    var total: Double {
        items.reduce(0) { $0 + $1.totalForItem }
    }
}
