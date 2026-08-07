//
//  InvoiceRowItem.swift
//  One invoice as a card in the list. The total leads, because that is what she
//  scans for; the receiver sits under it as the label rather than the headline.
//  The old card spent its height on a "PDF ready" line that was true on every
//  invoice and so told her nothing, so only the absence of a PDF is worth a
//  word now, and the shipped badge only appears once it means something.
//  Used by: MyInvoicesView.
//

import SwiftUI

struct InvoiceRowItem: View {
    @Environment(\.colorScheme) var colorScheme
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
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedTotal)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(AppSettings.currencySymbol)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 10))
                    Text("\(invoice.allItems.count)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.primary.opacity(0.06)))
            }

            HStack(spacing: 8) {
                Text(receiverName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if invoice.status == .shipped {
                    Text(L.t(.shipped).uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(InvoiceStatus.shipped.tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(InvoiceStatus.shipped.tint.opacity(0.18)))
                }

                if invoice.pdfFileName == nil {
                    Text(L.t(.noPDF).uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.18)))
                }

                Spacer(minLength: 6)

                Text(Self.dateFormatter.string(from: invoice.date))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.primary.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 3)
    }
}
