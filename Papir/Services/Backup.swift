//
//  Backup.swift
//  The full-fidelity backup the Excel export is not. The workbook is for
//  reading and hands a person denormalised sheets; this is for disaster, one
//  JSON file that carries everything the store knows, including the links the
//  sheets flatten away: which contact an invoice was addressed to, the exact
//  colour breakdown per row, the shipment record, the movement log.
//  Contacts are referenced by their position in the file rather than by any
//  id, because Contact has no stable identifier of its own and inventing one
//  for the wire keeps the models untouched.
//  Restoring replaces everything. A merge would need rules for every way two
//  stores can disagree and would get them wrong quietly; replace is the one
//  behaviour whose outcome she can predict, and it sits behind a confirmation
//  that says so. The wipe names the rows and lines as well as the four things
//  that own them: cascade would take them anyway, but a store carried over
//  from a build that leaked rows still holds ones no invoice points at, and
//  replace has to mean replace or those survive every restore she ever does. PDF file names are carried over even though the files stay
//  on the old phone: the invoice then honestly reports no PDF and re-generate
//  rebuilds it from the rows.
//  Used by: SettingsSheet, BackupTests.
//

import Foundation
import SwiftData

struct BackupFile: Codable {
    struct ContactRecord: Codable {
        var firstName: String
        var lastName: String
        var phone: String
        var city: String
        var shipmentAddress: String?
        var branchOne: String?
        var branchTwo: String?
    }

    struct StockLineRecord: Codable {
        var color: String
        var packs: Int
    }

    struct StockModelRecord: Codable {
        var code: String
        var pricePerPiece: Double
        var lines: [StockLineRecord]
    }

    struct ItemRecord: Codable {
        var name: String
        var unitCount: Int
        var itemsPerUnit: Int
        var price: Double
        var colors: [String]
        var colorPacks: [Int]
        var sortIndex: Int
    }

    struct ShipmentRecord: Codable {
        var modelCode: String
        var color: String
        var packs: Int
    }

    struct InvoiceRecord: Codable {
        var id: UUID
        var number: Int?
        var date: Date
        var sender: String
        var receiver: String
        var statusRaw: String?
        var shippedAt: Date?
        var pdfFileName: String?
        var contactIndex: Int?
        var items: [ItemRecord]
        var shipment: [ShipmentRecord]
    }

    struct MovementRecord: Codable {
        var date: Date
        var modelCode: String
        var color: String
        var packs: Int
        var kindRaw: String?
        var context: String?
    }

    var version: Int
    var exportedAt: Date
    var contacts: [ContactRecord]
    var models: [StockModelRecord]
    var invoices: [InvoiceRecord]
    var movements: [MovementRecord]
}

@MainActor
enum Backup {
    static func write(context: ModelContext) throws -> URL {
        let file = try snapshot(context: context)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(file)

        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent("PapirBackup", isDirectory: true)
        if fm.fileExists(atPath: folder.path) {
            try fm.removeItem(at: folder)
        }
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let url = folder.appendingPathComponent("Papir-Backup-\(formatter.string(from: .now)).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func snapshot(context: ModelContext) throws -> BackupFile {
        let contacts = try context.fetch(FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)]
        ))
        let models = try context.fetch(FetchDescriptor<StockModel>(sortBy: [SortDescriptor(\.code)]))
        let invoices = try context.fetch(FetchDescriptor<Invoice>(sortBy: [SortDescriptor(\.date)]))
        let movements = try context.fetch(FetchDescriptor<StockMovement>(sortBy: [SortDescriptor(\.date)]))

        var contactIndex: [PersistentIdentifier: Int] = [:]
        for (index, contact) in contacts.enumerated() {
            contactIndex[contact.persistentModelID] = index
        }

        return BackupFile(
            version: 1,
            exportedAt: .now,
            contacts: contacts.map {
                BackupFile.ContactRecord(
                    firstName: $0.firstName,
                    lastName: $0.lastName,
                    phone: $0.phone,
                    city: $0.city,
                    shipmentAddress: $0.shipmentAddress,
                    branchOne: nil,
                    branchTwo: nil
                )
            },
            models: models.map { model in
                BackupFile.StockModelRecord(
                    code: model.code,
                    pricePerPiece: model.pricePerPiece,
                    lines: model.orderedLines.map {
                        BackupFile.StockLineRecord(color: $0.color, packs: $0.packs)
                    }
                )
            },
            invoices: invoices.map { invoice in
                BackupFile.InvoiceRecord(
                    id: invoice.id,
                    number: invoice.number,
                    date: invoice.date,
                    sender: invoice.sender,
                    receiver: invoice.receiver,
                    statusRaw: invoice.statusRaw,
                    shippedAt: invoice.shippedAt,
                    pdfFileName: invoice.pdfFileName,
                    contactIndex: invoice.receiverContact.flatMap { contactIndex[$0.persistentModelID] },
                    items: invoice.orderedItems.map {
                        BackupFile.ItemRecord(
                            name: $0.name,
                            unitCount: Int($0.unitCount),
                            itemsPerUnit: Int($0.itemsPerUnit),
                            price: $0.price,
                            colors: $0.colors,
                            colorPacks: $0.colorPacks,
                            sortIndex: $0.sortIndex
                        )
                    },
                    shipment: invoice.shipment.map {
                        BackupFile.ShipmentRecord(modelCode: $0.modelCode, color: $0.color, packs: $0.packs)
                    }
                )
            },
            movements: movements.map {
                BackupFile.MovementRecord(
                    date: $0.date,
                    modelCode: $0.modelCode,
                    color: $0.color,
                    packs: $0.packs,
                    kindRaw: $0.kindRaw,
                    context: $0.context
                )
            }
        )
    }

    @discardableResult
    static func restore(_ data: Data, context: ModelContext) throws -> (invoices: Int, models: Int, contacts: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(BackupFile.self, from: data)

        try wipe(context: context)

        var contacts: [Contact] = []
        for record in file.contacts {
            let contact = Contact(
                firstName: record.firstName,
                lastName: record.lastName,
                phone: record.phone,
                city: record.city,
                shipmentAddress: record.shipmentAddress
                    ?? [record.branchOne, record.branchTwo]
                        .compactMap { $0 }
                        .first { !$0.isEmpty }
                    ?? ""
            )
            context.insert(contact)
            contacts.append(contact)
        }

        for record in file.models {
            let model = StockModel(
                code: record.code,
                pricePerPiece: record.pricePerPiece,
                lines: record.lines.map { StockLine(color: $0.color, packs: $0.packs) }
            )
            context.insert(model)
        }

        for record in file.invoices {
            let items = record.items
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { item -> ItemRow in
                    let row = ItemRow(
                        name: item.name,
                        unitCount: UInt16(clamping: item.unitCount),
                        itemsPerUnit: UInt16(clamping: item.itemsPerUnit),
                        price: item.price,
                        colors: item.colors
                    )
                    row.colorPacks = item.colorPacks
                    return row
                }

            let invoice = Invoice(
                items: items,
                date: record.date,
                sender: record.sender,
                receiver: record.receiver,
                pdfFileName: record.pdfFileName
            )
            invoice.id = record.id
            invoice.number = record.number ?? 0
            invoice.statusRaw = record.statusRaw
            invoice.shippedAt = record.shippedAt
            if let index = record.contactIndex, contacts.indices.contains(index) {
                invoice.receiverContact = contacts[index]
            }
            for line in record.shipment {
                invoice.recordShipment(
                    ShipmentLine(modelCode: line.modelCode, color: line.color, packs: line.packs)
                )
            }
            context.insert(invoice)
        }

        for record in file.movements {
            context.insert(
                StockMovement(
                    date: record.date,
                    modelCode: record.modelCode,
                    color: record.color,
                    packs: record.packs,
                    kind: StockMovementKind(rawValue: record.kindRaw ?? "") ?? .received,
                    context: record.context
                )
            )
        }

        try context.save()
        return (file.invoices.count, file.models.count, file.contacts.count)
    }

    private static func wipe(context: ModelContext) throws {
        for invoice in try context.fetch(FetchDescriptor<Invoice>()) {
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
    }
}
