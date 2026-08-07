//
//  InvoiceRowItem.swift
//  One invoice as a card in the list. The total leads, because that is what she
//  scans for; the receiver sits under it as the label rather than the headline.
//  The old card spent its height on a "PDF ready" line that was true on every
//  invoice and so told her nothing, so only the absence of a PDF is worth a
//  word now.
//  Status is the sheet of coloured paper the card sits on: a second card of the
//  same shape, taller by a strip, showing along the bottom edge in the status
//  colour with the word on it. It replaced a badge tucked in beside the
//  receiver, which had to be read to be found; a colour running the width of
//  the row is legible while scrolling, and reads as the invoice being filed
//  under something rather than as a warning attached to it. Every row carries
//  one, so drafts and shipped invoices are told apart by colour rather than by
//  one of them having a badge at all. The card's bottom corners are drawn
//  tighter than its top ones so it sits into the strip instead of floating
//  above it, and the item count is centred on the total rather than sharing
//  its baseline, since a capsule hung off a baseline reads as having slipped.
//  The card casts a real shadow onto the strip, two of them, a wide soft one
//  and a tight one at the edge, because without it two flat rectangles of the
//  same width read as one shape with a coloured end rather than as a card
//  lying on a sheet of paper.
//  Used by: MyInvoicesView.
//

import SwiftUI

struct InvoiceRowItem: View {
    let invoice: Invoice

    private static let totalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var formattedTotal: String {
        Self.totalFormatter.string(from: NSNumber(value: invoice.totalInvoicePrice))
            ?? "\(Int(invoice.totalInvoicePrice))"
    }

    private var receiverName: String {
        invoice.receiver.isEmpty ? L.t(.noReceiver) : invoice.receiver
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formattedTotal)
                        .font(.scaled(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text(AppSettings.currencySymbol)
                        .font(.scaled(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.scaled(size: 10))
                    Text("\(invoice.allItems.count)")
                        .font(.scaled(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Capsule().fill(.primary.opacity(0.06)))
                .offset(y: -2)
            }

            HStack(spacing: 8) {
                Text(receiverName)
                    .font(.scaled(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if invoice.pdfFileName == nil {
                    Text(L.t(.noPDF).uppercased())
                        .font(.scaled(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppWarning.tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppWarning.fill))
                }

                Spacer(minLength: 6)

                Text(Self.dateFormatter.string(from: invoice.date))
                    .font(.scaled(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardShape.fill(Color(.secondarySystemGroupedBackground)).raisedShadow())
        .overlay(cardShape.stroke(.primary.opacity(0.12), lineWidth: 0.8))
        .padding(.bottom, Self.statusStrip)
        .background(statusPlate)
        .animation(AppAnimation.quick, value: invoice.status)
    }

    private static let statusStrip: CGFloat = 24

    private var cardShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: 20
        )
    }

    private var statusPlate: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(invoice.status.plateTint)
            .overlay(alignment: .bottomLeading) {
                Text(invoice.status.label.uppercased())
                    .font(.scaled(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(invoice.status.plateText)
                    .padding(.leading, 18)
                    .padding(.bottom, 6)
                    .contentTransition(.opacity)
            }
    }
}
