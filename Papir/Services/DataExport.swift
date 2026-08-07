//
//  DataExport.swift
//  Everything in the app as one Excel workbook, handed to the share sheet. It
//  exists because iCloud is opt-in and unproven, so until it is this is the
//  only way a dropped phone is not a dropped business, and because an
//  accountant asking for the year's sales should not be told to screenshot a
//  list.
//  One workbook, four sheets, because the four things are not the same shape:
//  invoices flattened to a line per item row, stock to a line per colour,
//  contacts, and the movement log. Invoices are deliberately denormalised, the
//  parties and date repeated on every line, because that is the shape a
//  spreadsheet can filter and pivot; a normalised pair of tables would leave
//  her to do the join by hand.
//  Numbers are written as numbers rather than as text, which is the whole
//  reason for xlsx over csv: money adds up in the footer bar, dates sort as
//  dates, and nothing depends on whether the machine reading it expects a
//  comma or a full stop for its decimals.
//  The file lands in a fresh folder under the temporary directory and the
//  previous one is removed each time, so the share sheet always offers today's
//  export and nothing accumulates behind it.
//  Used by: SettingsSheet.
//

import Foundation

@MainActor
enum DataExport {
    private static let folderName = "PapirExport"

    static func write(
        invoices: [Invoice],
        stock: [StockModel],
        contacts: [Contact],
        movements: [StockMovement],
        currencySymbol: String
    ) throws -> URL {
        let workbook = XLSXWriter.workbook([
            invoiceSheet(invoices, currencySymbol: currencySymbol),
            stockSheet(stock),
            contactSheet(contacts),
            historySheet(movements)
        ])

        let folder = try freshFolder()
        let url = folder.appendingPathComponent("Papir-\(day(.now)).xlsx")
        try workbook.write(to: url, options: .atomic)
        return url
    }

    private static func freshFolder() throws -> URL {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)
        if fm.fileExists(atPath: root.path) {
            try fm.removeItem(at: root)
        }
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func invoiceSheet(_ invoices: [Invoice], currencySymbol: String) -> XLSXSheet {
        let columns = [
            XLSXColumn(title: L.t(.date), width: 12),
            XLSXColumn(title: L.t(.draft) + " / " + L.t(.shipped), width: 11),
            XLSXColumn(title: L.t(.sender), width: 18),
            XLSXColumn(title: L.t(.receiver), width: 22),
            XLSXColumn(title: L.t(.city), width: 14),
            XLSXColumn(title: L.t(.novaPoshtaOne), width: 16),
            XLSXColumn(title: L.t(.phone), width: 15),
            XLSXColumn(title: L.t(.name), width: 26),
            XLSXColumn(title: L.t(.units), width: 8),
            XLSXColumn(title: L.t(.perUnit), width: 9),
            XLSXColumn(title: "\(L.t(.price)), \(currencySymbol)", width: 11),
            XLSXColumn(title: "\(L.t(.subtotal)), \(currencySymbol)", width: 13),
            XLSXColumn(title: L.t(.colorsCaps).capitalized, width: 34)
        ]

        var rows: [[XLSXCell]] = []
        for invoice in invoices.sorted(by: { $0.date < $1.date }) {
            let contact = invoice.receiverContact
            for item in invoice.orderedItems {
                rows.append([
                    .date(invoice.date),
                    .text(invoice.status.label),
                    .text(invoice.sender),
                    .text(invoice.receiver),
                    .text(contact?.city ?? ""),
                    .text(contact?.branches.joined(separator: " / ") ?? ""),
                    .text(contact?.phone ?? ""),
                    .text(item.name),
                    .whole(Int(item.unitCount)),
                    .whole(Int(item.itemsPerUnit)),
                    .money(item.price),
                    .money(item.totalForItem),
                    .text(item.colorBreakdown.map { "\($0.color) \($0.packs)" }.joined(separator: " / "))
                ])
            }
        }

        return XLSXSheet(name: L.t(.invoices), columns: columns, rows: rows)
    }

    private static func stockSheet(_ stock: [StockModel]) -> XLSXSheet {
        let columns = [
            XLSXColumn(title: L.t(.modelCode), width: 22),
            XLSXColumn(title: L.t(.color), width: 18),
            XLSXColumn(title: L.t(.packs), width: 9),
            XLSXColumn(title: L.t(.pricePerPiece), width: 15)
        ]

        var rows: [[XLSXCell]] = []
        for model in stock.sorted(by: { $0.code.localizedStandardCompare($1.code) == .orderedAscending }) {
            let price: XLSXCell = model.hasPrice ? .money(model.pricePerPiece) : .blank

            guard !model.orderedLines.isEmpty else {
                rows.append([.text(model.code), .blank, .whole(0), price])
                continue
            }

            for line in model.orderedLines {
                rows.append([.text(model.code), .text(line.color), .whole(line.packs), price])
            }
        }

        return XLSXSheet(name: L.t(.stockTitle), columns: columns, rows: rows)
    }

    private static func contactSheet(_ contacts: [Contact]) -> XLSXSheet {
        let columns = [
            XLSXColumn(title: L.t(.firstName), width: 16),
            XLSXColumn(title: L.t(.lastName), width: 18),
            XLSXColumn(title: L.t(.phone), width: 16),
            XLSXColumn(title: L.t(.city), width: 16),
            XLSXColumn(title: L.t(.novaPoshtaOne), width: 18),
            XLSXColumn(title: L.t(.novaPoshtaTwo), width: 18),
            XLSXColumn(title: L.t(.invoices), width: 10)
        ]

        let rows = contacts
            .sorted { $0.lastName.localizedStandardCompare($1.lastName) == .orderedAscending }
            .map { contact -> [XLSXCell] in
                [
                    .text(contact.firstName),
                    .text(contact.lastName),
                    .text(contact.phone),
                    .text(contact.city),
                    .text(contact.branchOne),
                    .text(contact.branchTwo),
                    .whole(contact.invoiceCount)
                ]
            }

        return XLSXSheet(name: L.t(.addressBook), columns: columns, rows: rows)
    }

    private static func historySheet(_ movements: [StockMovement]) -> XLSXSheet {
        let columns = [
            XLSXColumn(title: L.t(.date), width: 12),
            XLSXColumn(title: L.t(.modelCode), width: 22),
            XLSXColumn(title: L.t(.color), width: 18),
            XLSXColumn(title: L.t(.packs), width: 9),
            XLSXColumn(title: L.t(.history), width: 14),
            XLSXColumn(title: L.t(.receiver), width: 22)
        ]

        let rows = movements
            .sorted { $0.date < $1.date }
            .map { movement -> [XLSXCell] in
                [
                    .date(movement.date),
                    .text(movement.modelCode),
                    .text(movement.color),
                    .whole(movement.packs),
                    .text(movement.kind.label),
                    .text(movement.context ?? "")
                ]
            }

        return XLSXSheet(name: L.t(.history), columns: columns, rows: rows)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func day(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
