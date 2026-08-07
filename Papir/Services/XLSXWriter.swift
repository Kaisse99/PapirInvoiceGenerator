//
//  XLSXWriter.swift
//  Writes a real Excel workbook, one sheet per table, with the parts an xlsx
//  is made of: a content type map, two relationship files, a workbook, a style
//  sheet, and a worksheet each. No library, because a dependency for four
//  tables of text would be a heavier thing to carry than the format itself.
//  Strings go inline rather than through a shared string table. A shared table
//  is how Excel saves its own files, since it pays off across thousands of
//  repeated cells, and it costs a second pass and an index here for nothing.
//  Styling is the point of using xlsx rather than csv, so the sheets arrive
//  looking like something rather than raw: a dark header row that stays put
//  while you scroll, filter arrows on it, columns wide enough for what they
//  hold, money to two decimals with thousands separated, and dates in the one
//  format that cannot be misread.
//  Dates are stored the way the format wants them, as days since the last day
//  of 1899, which is the same off-by-one Lotus shipped in 1983 and Excel has
//  been bug-compatible with ever since.
//  Used by: DataExport.
//

import Foundation

enum XLSXCell {
    case text(String)
    case number(Double)
    case money(Double)
    case whole(Int)
    case date(Date)
    case blank
}

struct XLSXColumn {
    let title: String
    let width: Double
}

struct XLSXSheet {
    let name: String
    let columns: [XLSXColumn]
    let rows: [[XLSXCell]]
}

enum XLSXWriter {
    private enum Style: Int {
        case plain = 0
        case header = 1
        case money = 2
        case date = 3
        case whole = 4
    }

    static func workbook(_ sheets: [XLSXSheet]) -> Data {
        var zip = ZipWriter()

        zip.add(contentTypes(count: sheets.count), named: "[Content_Types].xml")
        zip.add(rootRelationships(), named: "_rels/.rels")
        zip.add(workbookXML(sheets), named: "xl/workbook.xml")
        zip.add(workbookRelationships(count: sheets.count), named: "xl/_rels/workbook.xml.rels")
        zip.add(styles(), named: "xl/styles.xml")

        for (index, sheet) in sheets.enumerated() {
            zip.add(sheetXML(sheet), named: "xl/worksheets/sheet\(index + 1).xml")
        }

        return zip.finish()
    }

    private static func contentTypes(count: Int) -> String {
        var parts = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        """
        for index in 1...count {
            parts += """
            <Override PartName="/xl/worksheets/sheet\(index).xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
            """
        }
        return parts + "</Types>"
    }

    private static func rootRelationships() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private static func workbookXML(_ sheets: [XLSXSheet]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" \
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>
        """
        for (index, sheet) in sheets.enumerated() {
            xml += "<sheet name=\"\(escaped(sheet.name))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }
        return xml + "</sheets></workbook>"
    }

    private static func workbookRelationships(count: Int) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        """
        for index in 1...count {
            xml += """
            <Relationship Id="rId\(index)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet\(index).xml"/>
            """
        }
        return xml + "</Relationships>"
    }

    private static func styles() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <numFmts count="2">
        <numFmt numFmtId="164" formatCode="#,##0.00"/>
        <numFmt numFmtId="165" formatCode="yyyy\\-mm\\-dd"/>
        </numFmts>
        <fonts count="2">
        <font><sz val="11"/><name val="Calibri"/></font>
        <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
        </fonts>
        <fills count="3">
        <fill><patternFill patternType="none"/></fill>
        <fill><patternFill patternType="gray125"/></fill>
        <fill><patternFill patternType="solid"><fgColor rgb="FF1F2430"/><bgColor indexed="64"/></patternFill></fill>
        </fills>
        <borders count="2">
        <border><left/><right/><top/><bottom/><diagonal/></border>
        <border><left/><right/><top/><bottom style="thin"><color rgb="FF9099A8"/></bottom><diagonal/></border>
        </borders>
        <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
        <cellXfs count="5">
        <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
        <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center"/></xf>
        <xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
        <xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
        <xf numFmtId="3" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
        </cellXfs>
        <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
        """
    }

    private static func sheetXML(_ sheet: XLSXSheet) -> String {
        let lastColumn = columnName(sheet.columns.count)
        let lastRow = sheet.rows.count + 1

        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetViews><sheetView workbookViewId="0" showGridLines="0">
        <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>
        </sheetView></sheetViews>
        <sheetFormatPr defaultRowHeight="15"/><cols>
        """

        for (index, column) in sheet.columns.enumerated() {
            let position = index + 1
            xml += "<col min=\"\(position)\" max=\"\(position)\" width=\"\(column.width)\" customWidth=\"1\"/>"
        }

        xml += "</cols><sheetData><row r=\"1\" ht=\"22\" customHeight=\"1\">"
        for (index, column) in sheet.columns.enumerated() {
            xml += cellXML(.text(column.title), reference: "\(columnName(index + 1))1", style: .header)
        }
        xml += "</row>"

        for (rowIndex, row) in sheet.rows.enumerated() {
            let number = rowIndex + 2
            xml += "<row r=\"\(number)\">"
            for (cellIndex, cell) in row.enumerated() {
                xml += cellXML(cell, reference: "\(columnName(cellIndex + 1))\(number)", style: style(for: cell))
            }
            xml += "</row>"
        }

        xml += "</sheetData>"
        if !sheet.rows.isEmpty {
            xml += "<autoFilter ref=\"A1:\(lastColumn)\(lastRow)\"/>"
        }
        return xml + "</worksheet>"
    }

    private static func style(for cell: XLSXCell) -> Style {
        switch cell {
        case .money: return .money
        case .date:  return .date
        case .whole: return .whole
        default:     return .plain
        }
    }

    private static func cellXML(_ cell: XLSXCell, reference: String, style: Style) -> String {
        let styleAttribute = style == .plain ? "" : " s=\"\(style.rawValue)\""

        switch cell {
        case .blank:
            return "<c r=\"\(reference)\"\(styleAttribute)/>"
        case .text(let value):
            guard !value.isEmpty else { return "<c r=\"\(reference)\"\(styleAttribute)/>" }
            return "<c r=\"\(reference)\"\(styleAttribute) t=\"inlineStr\"><is><t xml:space=\"preserve\">\(escaped(value))</t></is></c>"
        case .number(let value), .money(let value):
            return "<c r=\"\(reference)\"\(styleAttribute)><v>\(trimmed(value))</v></c>"
        case .whole(let value):
            return "<c r=\"\(reference)\"\(styleAttribute)><v>\(value)</v></c>"
        case .date(let value):
            return "<c r=\"\(reference)\"\(styleAttribute)><v>\(trimmed(serial(value)))</v></c>"
        }
    }

    private static func serial(_ date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let epoch = calendar.date(from: DateComponents(year: 1899, month: 12, day: 30)) ?? date
        let days = calendar.dateComponents([.day], from: epoch, to: date).day ?? 0
        return Double(days)
    }

    private static func trimmed(_ value: Double) -> String {
        String(format: "%.4f", value)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
    }

    private static func columnName(_ index: Int) -> String {
        var remaining = index
        var name = ""
        while remaining > 0 {
            let position = (remaining - 1) % 26
            name = String(UnicodeScalar(65 + position)!) + name
            remaining = (remaining - 1) / 26
        }
        return name
    }

    private static func escaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
