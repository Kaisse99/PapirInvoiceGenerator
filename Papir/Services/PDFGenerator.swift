//
//  PDFGenerator.swift
//  Renders an Invoice into A4 PDF data (595.2 × 841.8 points at 72 DPI) with
//  UIGraphicsPDFRenderer: header, both parties, the item table, the total, and
//  a footer. Rows are drawn in the invoice's own order and are not a fixed
//  height: both the item name and its color list wrap inside the item column
//  and push the row taller, so each row is measured before it is drawn and a
//  new page starts whenever the next one would not fit. The quantity, price,
//  and line total stay on the row's first line so the columns still read
//  across. A party with no name is left off the page entirely rather than
//  printed as a label over a dash, so an invoice with only a receiver puts that
//  receiver where the sender would have been. Every color on a row prints its
//  pack count, including a one. The count used to be dropped when every color
//  on the row happened to be a single pack, on the reasoning that a one adds
//  nothing, which put two conventions in one document: a row of three and one
//  printed its numbers while the row under it, one and one, printed bare names
//  and left the reader to divide. Input is an InvoiceSnapshot
//  rather than the model, because rendering happens off the main thread.
//  The type is nonisolated for that reason. The project defaults every type to
//  MainActor, which made render's Task.detached a main-actor method being run
//  off the main actor: legal in Swift 5, an error in Swift 6, and a lie about
//  where the work happens either way. Nothing here touches main-actor state,
//  so saying so out loud costs nothing and keeps the detached hop honest.
//  PDFLanguage carries every piece of on-page text, so adding a language means
//  adding a case here and nothing else. It is nonisolated for the same reason
//  the renderer is: it is read while drawing, which happens off the main
//  actor, and a page of static strings never needed the main actor anyway.
//  Used by: NewInvoiceViewModel, InvoiceDetailViewModel; PDFLanguage also by
//  LanguagePickerSheet and PDFStorage.
//

import UIKit
import PDFKit

nonisolated enum PDFLanguage: String, CaseIterable, Identifiable {
    case english
    case ukrainian
    case russian
    case polish

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english:   return "English"
        case .ukrainian: return "Українська"
        case .russian:   return "Русский"
        case .polish:    return "Polski"
        }
    }
    
    var flag: String {
        switch self {
        case .english:   return "🇬🇧"
        case .ukrainian: return "🇺🇦"
        case .russian:   return "🇷🇺"
        case .polish:    return "🇵🇱"
        }
    }
    
    var appLanguage: AppLanguage {
        switch self {
        case .english:   return .english
        case .ukrainian: return .ukrainian
        case .russian:   return .russian
        case .polish:    return .polish
        }
    }

    var title: String { L.t(.pdfTitle, appLanguage) }

    var numberPrefix: String { L.t(.pdfNumber, appLanguage) }

    var fromLabel: String { L.t(.pdfFrom, appLanguage) }

    var toLabel: String { L.t(.pdfTo, appLanguage) }

    var itemHeader: String { L.t(.pdfItem, appLanguage) }

    var qtyHeader: String { L.t(.pdfQty, appLanguage) }

    var priceHeader: String { L.t(.pdfPrice, appLanguage) }

    var totalHeader: String { L.t(.pdfTotal, appLanguage) }

    var totalLabel: String { L.t(.pdfTotal, appLanguage) }

    var footerText: String { L.t(.pdfFooter, appLanguage) }
    
    var dateLocale: Locale {
        switch self {
        case .english:   return Locale(identifier: "en_US")
        case .ukrainian: return Locale(identifier: "uk_UA")
        case .russian:   return Locale(identifier: "ru_RU")
        case .polish:    return Locale(identifier: "pl_PL")
        }
    }
}

nonisolated struct PDFGenerator {

    static let a4Size = CGSize(width: 595.2, height: 841.8)
    static let margin: CGFloat = 40
    static let fontScale: CGFloat = 1.05
    static let footerReserve: CGFloat = 20
    static let totalBlockHeight: CGFloat = 50

    static func render(_ invoice: InvoiceSnapshot, language: PDFLanguage, currencySymbol: String) async -> Data {
        await Task.detached(priority: .userInitiated) {
            generate(for: invoice, language: language, currencySymbol: currencySymbol)
        }.value
    }

    static func generate(for invoice: InvoiceSnapshot, language: PDFLanguage = .english, currencySymbol: String = "") -> Data {
        let pageRect = CGRect(origin: .zero, size: a4Size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let contentWidth = pageRect.width - margin * 2
        let contentBottom = pageRect.height - margin - footerReserve

        return renderer.pdfData { context in
            var cursorY: CGFloat = margin
            context.beginPage()

            cursorY = drawHeader(invoice: invoice, language: language, startY: cursorY, pageWidth: pageRect.width)
            cursorY += 20

            cursorY = drawParties(invoice: invoice, language: language, startY: cursorY, pageWidth: pageRect.width)
            cursorY += 24

            cursorY = drawTableHeader(language: language, startY: cursorY, pageWidth: pageRect.width)

            for (index, item) in invoice.items.enumerated() {
                if cursorY + rowHeight(for: item, contentWidth: contentWidth) > contentBottom {
                    context.beginPage()
                    cursorY = margin
                    cursorY = drawTableHeader(language: language, startY: cursorY, pageWidth: pageRect.width)
                }

                cursorY = drawTableRow(
                    index: index + 1,
                    item: item,
                    startY: cursorY,
                    pageWidth: pageRect.width
                )
            }

            cursorY += 16

            if cursorY + totalBlockHeight > contentBottom {
                context.beginPage()
                cursorY = margin
            }
            cursorY = drawTotal(total: invoice.total, language: language, currencySymbol: currencySymbol, startY: cursorY, pageWidth: pageRect.width)

            drawFooter(invoice: invoice, language: language, pageRect: pageRect)
        }
    }
    
    private static func drawHeader(invoice: InvoiceSnapshot, language: PDFLanguage, startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 26 * fontScale, weight: .black),
            .foregroundColor: UIColor.black,
            .kern: 6
        ]
        
        language.title.draw(at: CGPoint(x: margin, y: startY), withAttributes: titleAttrs)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = language.dateLocale
        dateFormatter.dateStyle = .long
        let dateText = dateFormatter.string(from: invoice.date)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11 * fontScale, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        let dateSize = (dateText as NSString).size(withAttributes: dateAttrs)
        dateText.draw(
            at: CGPoint(x: pageWidth - margin - dateSize.width, y: startY + 10),
            withAttributes: dateAttrs
        )
        
        let titleHeight: CGFloat = 36
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: startY + titleHeight + 8))
        line.addLine(to: CGPoint(x: pageWidth - margin, y: startY + titleHeight + 8))
        UIColor.black.setStroke()
        line.lineWidth = 1
        line.stroke()
        
        return startY + titleHeight + 12
    }
    
    private static func drawParties(invoice: InvoiceSnapshot, language: PDFLanguage, startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 8 * fontScale, weight: .regular),
            .foregroundColor: UIColor.gray,
            .kern: 2
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 12 * fontScale, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9.5 * fontScale, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let columnWidth = (pageWidth - margin * 2 - 20) / 2

        var parties: [(label: String, name: String, details: [String])] = []
        if !invoice.sender.isEmpty {
            parties.append((language.fromLabel, invoice.sender, []))
        }
        if !invoice.receiver.isEmpty {
            parties.append((language.toLabel, invoice.receiver, invoice.receiverDetails))
        }

        guard !parties.isEmpty else { return startY }

        var deepest = startY + 34

        for (index, party) in parties.enumerated() {
            let x = margin + CGFloat(index) * (columnWidth + 20)
            party.label.draw(at: CGPoint(x: x, y: startY), withAttributes: labelAttrs)
            party.name.draw(at: CGPoint(x: x, y: startY + 14), withAttributes: valueAttrs)

            var lineY = startY + 32
            for detail in party.details {
                detail.draw(at: CGPoint(x: x, y: lineY), withAttributes: detailAttrs)
                lineY += 13
            }
            deepest = max(deepest, lineY + (party.details.isEmpty ? 2 : 4))
        }

        return deepest
    }
    
    private static func drawTableHeader(language: PDFLanguage, startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 8 * fontScale, weight: .bold),
            .foregroundColor: UIColor.gray,
            .kern: 1.5
        ]
        
        let contentWidth = pageWidth - margin * 2
        let cols = columnLayout(contentWidth: contentWidth)
        
        "#".draw(at: CGPoint(x: margin, y: startY), withAttributes: attrs)
        language.itemHeader.draw(at: CGPoint(x: margin + cols.indexW, y: startY), withAttributes: attrs)
        
        let qtySize = (language.qtyHeader as NSString).size(withAttributes: attrs)
        language.qtyHeader.draw(
            at: CGPoint(x: margin + cols.indexW + cols.nameW + (cols.qtyW - qtySize.width) / 2, y: startY),
            withAttributes: attrs
        )
        
        let priceSize = (language.priceHeader as NSString).size(withAttributes: attrs)
        language.priceHeader.draw(
            at: CGPoint(x: margin + cols.indexW + cols.nameW + cols.qtyW + (cols.priceW - priceSize.width) / 2, y: startY),
            withAttributes: attrs
        )
        
        let totalSize = (language.totalHeader as NSString).size(withAttributes: attrs)
        language.totalHeader.draw(
            at: CGPoint(x: pageWidth - margin - totalSize.width, y: startY),
            withAttributes: attrs
        )
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: startY + 16))
        line.addLine(to: CGPoint(x: pageWidth - margin, y: startY + 16))
        UIColor.lightGray.setStroke()
        line.lineWidth = 0.5
        line.stroke()
        
        return startY + 24
    }
    
    private static func drawTableRow(index: Int, item: InvoiceSnapshot.Item, startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11 * fontScale, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11 * fontScale, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let contentWidth = pageWidth - margin * 2
        let cols = columnLayout(contentWidth: contentWidth)
        let textColumnX = margin + cols.indexW
        let textColumnWidth = itemColumnWidth(contentWidth: contentWidth)

        "\(index)".draw(at: CGPoint(x: margin, y: startY), withAttributes: valueAttrs)

        (item.name as NSString).draw(
            with: CGRect(
                x: textColumnX,
                y: startY,
                width: textColumnWidth,
                height: nameHeight(for: item, contentWidth: contentWidth)
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: nameAttrs,
            context: nil
        )

        if let colorsText = colorsText(for: item) {
            let colorsBox = CGRect(
                x: textColumnX,
                y: startY + nameHeight(for: item, contentWidth: contentWidth),
                width: textColumnWidth,
                height: colorsHeight(for: item, contentWidth: contentWidth)
            )
            (colorsText as NSString).draw(
                with: colorsBox,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: colorsAttrs,
                context: nil
            )
        }

        let qtyText = item.itemsPerUnit > 1 ? "\(item.unitCount) × \(item.itemsPerUnit)" : "\(item.unitCount)"
        let qtySize = (qtyText as NSString).size(withAttributes: valueAttrs)
        qtyText.draw(
            at: CGPoint(x: margin + cols.indexW + cols.nameW + (cols.qtyW - qtySize.width) / 2, y: startY),
            withAttributes: valueAttrs
        )
        
        let priceText = formatNumber(item.price)
        let priceSize = (priceText as NSString).size(withAttributes: valueAttrs)
        priceText.draw(
            at: CGPoint(x: margin + cols.indexW + cols.nameW + cols.qtyW + (cols.priceW - priceSize.width) / 2, y: startY),
            withAttributes: valueAttrs
        )
        
        let lineTotal = formatNumber(item.totalForItem)
        let lineTotalSize = (lineTotal as NSString).size(withAttributes: totalAttrs)
        lineTotal.draw(
            at: CGPoint(x: pageWidth - margin - lineTotalSize.width, y: startY),
            withAttributes: totalAttrs
        )

        return startY + rowHeight(for: item, contentWidth: contentWidth)
    }

    private static let wrappingParagraphStyle: NSParagraphStyle = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 2
        return paragraph
    }()

    private static let nameAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 11 * fontScale, weight: .medium),
        .foregroundColor: UIColor.black,
        .paragraphStyle: wrappingParagraphStyle
    ]

    private static let colorsAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.monospacedSystemFont(ofSize: 8 * fontScale, weight: .regular),
        .foregroundColor: UIColor.darkGray,
        .paragraphStyle: wrappingParagraphStyle
    ]

    private static let rowBottomInset: CGFloat = 4
    private static let colorsBottomInset: CGFloat = 6

    private static func colorsText(for item: InvoiceSnapshot.Item) -> String? {
        let breakdown = item.colorBreakdown
        guard !breakdown.isEmpty else { return nil }
        return breakdown
            .map { "\($0.color) \($0.packs)" }
            .joined(separator: " · ")
    }

    private static func itemColumnWidth(contentWidth: CGFloat) -> CGFloat {
        columnLayout(contentWidth: contentWidth).nameW - 8
    }

    private static func height(of text: String, attributes: [NSAttributedString.Key: Any], width: CGFloat) -> CGFloat {
        ceil(
            (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            ).height
        )
    }

    private static func nameHeight(for item: InvoiceSnapshot.Item, contentWidth: CGFloat) -> CGFloat {
        height(
            of: item.name.isEmpty ? " " : item.name,
            attributes: nameAttrs,
            width: itemColumnWidth(contentWidth: contentWidth)
        )
    }

    private static func colorsHeight(for item: InvoiceSnapshot.Item, contentWidth: CGFloat) -> CGFloat {
        guard let text = colorsText(for: item) else { return 0 }
        return height(of: text, attributes: colorsAttrs, width: itemColumnWidth(contentWidth: contentWidth))
    }

    private static func rowHeight(for item: InvoiceSnapshot.Item, contentWidth: CGFloat) -> CGFloat {
        let name = nameHeight(for: item, contentWidth: contentWidth)
        let colors = colorsHeight(for: item, contentWidth: contentWidth)
        guard colors > 0 else { return name + rowBottomInset }
        return name + colors + colorsBottomInset
    }


    private static func drawTotal(total: Double, language: PDFLanguage, currencySymbol: String, startY: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: startY))
        line.addLine(to: CGPoint(x: pageWidth - margin, y: startY))
        UIColor.black.setStroke()
        line.lineWidth = 1
        line.stroke()
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 10 * fontScale, weight: .bold),
            .foregroundColor: UIColor.gray,
            .kern: 4
        ]
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 22 * fontScale, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        
        language.totalLabel.draw(at: CGPoint(x: margin, y: startY + 16), withAttributes: labelAttrs)
        
        let totalText = currencySymbol.isEmpty ? formatNumber(total) : "\(formatNumber(total)) \(currencySymbol)"
        let totalSize = (totalText as NSString).size(withAttributes: totalAttrs)
        totalText.draw(
            at: CGPoint(x: pageWidth - margin - totalSize.width, y: startY + 12),
            withAttributes: totalAttrs
        )
        
        return startY + 50
    }
    
    private static func drawFooter(invoice: InvoiceSnapshot, language: PDFLanguage, pageRect: CGRect) {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 7, weight: .regular),
            .foregroundColor: UIColor.lightGray,
            .kern: 2
        ]
        let baseline = pageRect.height - margin / 2

        let footerSize = (language.footerText as NSString).size(withAttributes: footerAttrs)
        language.footerText.draw(
            at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: baseline),
            withAttributes: footerAttrs
        )

        guard invoice.number > 0 else { return }
        let numberText = "\(language.numberPrefix)\(invoice.number)"
        let numberSize = (numberText as NSString).size(withAttributes: footerAttrs)
        numberText.draw(
            at: CGPoint(x: (pageRect.width - numberSize.width) / 2, y: baseline - numberSize.height - 3),
            withAttributes: footerAttrs
        )
    }
    
    
    private struct ColumnLayout {
        let indexW: CGFloat
        let nameW: CGFloat
        let qtyW: CGFloat
        let priceW: CGFloat
        let totalW: CGFloat
    }
    
    private static func columnLayout(contentWidth: CGFloat) -> ColumnLayout {
        let indexW: CGFloat = 30
        let totalW: CGFloat = 90
        let qtyW: CGFloat = 80
        let priceW: CGFloat = 70
        let nameW = contentWidth - indexW - qtyW - priceW - totalW
        return ColumnLayout(indexW: indexW, nameW: nameW, qtyW: qtyW, priceW: priceW, totalW: totalW)
    }
    
    private static func formatNumber(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
