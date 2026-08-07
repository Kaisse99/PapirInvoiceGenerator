//
//  ShipmentSheet.swift
//  The last look before an invoice moves stock. It reports rather than edits:
//  the invoice already carries a pack count per color, so an override here
//  would leave the shelf and the document describing different shipments, and
//  the invoice is the one of those two that gets sent to a customer. Anything
//  wrong is wrong on the invoice and belongs fixed there.
//  Rows are grouped under the model they come off, each color showing what it
//  takes against what is on hand, and anything that cannot move stock is listed
//  separately with the reason instead of being dropped, so nothing is deducted
//  or skipped without being seen. Taking more than is on hand is allowed and
//  shown in orange first.
//  Used by: InvoiceDetailView.
//

import SwiftUI
import SwiftData

struct ShipmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let invoice: Invoice
    let stock: [StockModel]
    let onShipped: (Int) -> Void

    @State private var drafts: [ShipmentDraft] = []
    @State private var loaded = false
    @State private var errorMessage: String? = nil

    private var actionable: [ShipmentDraft] {
        drafts.filter(\.isActionable)
    }

    private var skipped: [ShipmentDraft] {
        drafts.filter { !$0.isActionable }
    }

    private var totalPacks: Int {
        actionable.reduce(0) { $0 + $1.packs }
    }

    private var groups: [(code: String, entries: [ShipmentDraft])] {
        var order: [String] = []
        var buckets: [String: [ShipmentDraft]] = [:]

        for draft in actionable {
            guard let code = draft.modelCode else { continue }
            if buckets[code] == nil {
                order.append(code)
                buckets[code] = []
            }
            buckets[code]?.append(draft)
        }

        return order.map { (code: $0, entries: buckets[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    if !groups.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(groups, id: \.code) { group in
                                modelCard(group.code, entries: group.entries)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !skipped.isEmpty {
                        skippedSection
                    }

                    confirmButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 12)
            }
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L.t(.shipment))
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.black)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Text(L.t(.cancel))
                            .font(.scaled(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .tint(Color.primary)
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            drafts = ShipmentPlanner.plan(for: invoice, stock: stock)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(L.t(.packsLeavingStock).uppercased())
                .font(.scaled(size: 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            Text("\(totalPacks)")
                .font(.scaled(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)

            Text(L.t(.shipmentHint))
                .font(.scaled(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 2)
        }
    }

    private func modelCard(_ code: String, entries: [ShipmentDraft]) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(code)
                    .font(.scaled(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("\(entries.reduce(0) { $0 + $1.packs }) \(L.t(.packsLower))")
                    .font(.scaled(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    colorLine(entry)

                    if index < entries.count - 1 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }

    private func colorLine(_ draft: ShipmentDraft) -> some View {
        let onHand = ShipmentPlanner.available(draft, in: stock) ?? 0
        let short = max(0, draft.packs - onHand)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(draft.color)
                        .font(.scaled(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(L.t(.inStock)): \(onHand)")
                        .font(.scaled(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(short > 0 ? AppWarning.tint : .secondary)
                }

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("−\(draft.packs)")
                        .font(.scaled(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(short > 0 ? AppWarning.tint : .primary)

                    Text(L.t(draft.packs == 1 ? .pack : .packsLower))
                        .font(.scaled(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            if short > 0 {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.scaled(size: 11))
                        .foregroundStyle(AppWarning.tint)

                    Text("+\(short) \(L.t(.moreThanOnHand))")
                        .font(.scaled(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(AppWarning.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppWarning.fill))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.t(.notDeducted).uppercased())
                .font(.scaled(size: 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            VStack(spacing: 8) {
                ForEach(skipped) { draft in
                    HStack(spacing: 12) {
                        Image(systemName: "minus.circle")
                            .font(.scaled(size: 14))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.modelCode ?? draft.itemName)
                                .font(.scaled(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(draft.isMatched ? L.t(.noColorOnRow) : L.t(.notInStockHint))
                                .font(.scaled(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground).opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.10), lineWidth: 0.8))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var confirmButton: some View {
        Button {
            Haptics.medium()
            confirm()
        } label: {
            Text(L.t(.confirmShipment))
                .font(.scaled(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(Color(.systemBackground))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primary.opacity(actionable.isEmpty ? 0.3 : 0.9))
                )
        }
        .buttonStyle(.plain)
        .disabled(actionable.isEmpty)
        .padding(.horizontal, 20)
    }

    private func confirm() {
        do {
            let shortfall = try ShipmentPlanner.apply(drafts, to: invoice, stock: stock, context: modelContext)
            Haptics.success()
            onShipped(shortfall)
            dismiss()
        } catch {
            Haptics.error()
            errorMessage = "\(L.t(.couldNotSave)): \(error.localizedDescription)"
        }
    }
}
