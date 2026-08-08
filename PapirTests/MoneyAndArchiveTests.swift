//
//  MoneyAndArchiveTests.swift
//  The two hand-rolled formats and the money formatter. The CRC is checked
//  against the standard vector every implementation on earth agrees on, the
//  zip against its own end-of-directory record and local headers, and the
//  xlsx by reading the raw XML back out of the archive, which works because
//  entries are stored rather than deflated. If any of these drift, Excel
//  opens a broken file on someone else's machine, not here.
//

import Foundation
import Testing
@testable import Papir

@MainActor
struct MoneyAndArchiveTests {
    @Test func priceDisplayGroupsThousands() {
        #expect(PriceText.display(21150) == "21,150")
        #expect(PriceText.display(150.5) == "150.5")
    }

    @Test func priceEditableStaysParseable() {
        #expect(PriceText.editable(150) == "150")
        #expect(PriceText.editable(150.25) == "150.25")
        #expect(Double(PriceText.editable(99.9)) == 99.9)
    }

    @Test func crcMatchesTheStandardVector() {
        let data = Data("123456789".utf8)
        #expect(CRC32.checksum(data) == 0xCBF43926)
    }

    @Test func zipCarriesItsEntriesAndDirectory() {
        var zip = ZipWriter()
        zip.add("hello", named: "a.txt")
        zip.add("world", named: "b/c.txt")
        let data = zip.finish()

        #expect(data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04]))

        let eocd = data.suffix(22)
        #expect(eocd.prefix(4) == Data([0x50, 0x4B, 0x05, 0x06]))

        let entryCount = Int(eocd[eocd.startIndex + 10]) | Int(eocd[eocd.startIndex + 11]) << 8
        #expect(entryCount == 2)

        var directoryOffset = 0
        for i in 0..<4 {
            directoryOffset |= Int(eocd[eocd.startIndex + 16 + i]) << (8 * i)
        }
        #expect(data[directoryOffset..<directoryOffset + 4] == Data([0x50, 0x4B, 0x01, 0x02]))
    }

    @Test func workbookContainsItsPartsAndEscapesText() {
        let sheet = XLSXSheet(
            name: "Sales & Stock",
            columns: [XLSXColumn(title: "Name", width: 20)],
            rows: [[.text("a <& b")], [.money(150.5)], [.whole(7)]]
        )
        let data = XLSXWriter.workbook([sheet])
        let raw = String(decoding: data, as: UTF8.self)

        #expect(raw.contains("[Content_Types].xml"))
        #expect(raw.contains("xl/worksheets/sheet1.xml"))
        #expect(raw.contains("Sales &amp; Stock"))
        #expect(raw.contains("a &lt;&amp; b"))
        #expect(raw.contains("<v>150.5</v>"))
        #expect(raw.contains("<v>7</v>"))
        #expect(raw.contains("autoFilter"))
    }
}
