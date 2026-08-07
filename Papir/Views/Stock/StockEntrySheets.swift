//
//  StockEntrySheets.swift
//  The sheets that change one number on a model. Three of them move packs and
//  all ask for a count; the fourth sets the price per piece. Taking stock in
//  also takes a color, and offers the colors already under this model as taps
//  so the same color never gets typed two ways. Taking stock out says how much
//  is on hand up front, so a shortfall is a decision rather than a surprise.
//  Recounting replaces the number outright, which is what she has after
//  standing in front of the box. The price sheet opens on the current price so
//  a correction is an edit rather than a retype, and an emptied field means
//  no price rather than free.
//  Used by: StockModelDetailView.
//

import SwiftUI

struct ReceiveStockSheet: View {
    let model: StockModel
    let onCommit: (String, Int) -> Void

    @State private var color: String = ""
    @State private var packs: String = ""

    private var existingColors: [String] {
        model.orderedLines.map(\.color)
    }

    private var packCount: Int {
        Int(packs) ?? 0
    }

    private var canCommit: Bool {
        !color.trimmingCharacters(in: .whitespaces).isEmpty && packCount > 0
    }

    var body: some View {
        StockSheetFrame(title: L.t(.takeStockIn), subtitle: model.code) {
            VStack(spacing: 18) {
                if !existingColors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        StockSheetLabel(L.t(.color).uppercased())
                        FlowLayout(spacing: 6) {
                            ForEach(existingColors, id: \.self) { existing in
                                Button {
                                    Haptics.light()
                                    color = existing
                                } label: {
                                    Text(existing)
                                        .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(
                                                color.caseInsensitiveCompare(existing) == .orderedSame
                                                    ? Color.accentColor.opacity(0.25)
                                                    : Color.primary.opacity(0.06)
                                            )
                                        )
                                        .overlay(Capsule().stroke(.primary.opacity(0.15), lineWidth: 0.8))
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                StockSheetField(placeholder: L.t(.color), text: $color, keyboard: .default)
                    .limitInput($color, to: 16)

                StockSheetField(placeholder: L.t(.packs), text: $packs, keyboard: .numberPad)
                    .digitsOnly($packs)
                    .limitInput($packs, to: 4)

                StockSheetButton(title: L.t(.add), enabled: canCommit) {
                    onCommit(color, packCount)
                }
            }
        }
    }
}

struct WithdrawStockSheet: View {
    let modelCode: String
    let line: StockLine
    let onCommit: (Int) -> Void

    @State private var packs: String = ""

    private var packCount: Int { Int(packs) ?? 0 }

    private var shortfall: Int {
        max(0, packCount - line.packs)
    }

    var body: some View {
        StockSheetFrame(title: L.t(.takeStockOut), subtitle: "\(modelCode) \(line.color)") {
            VStack(spacing: 18) {
                Text("\(L.t(.onHand)): \(line.packs)")
                    .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                StockSheetField(placeholder: L.t(.packs), text: $packs, keyboard: .numberPad)
                    .digitsOnly($packs)
                    .limitInput($packs, to: 4)

                if shortfall > 0 {
                    Text("+\(shortfall) \(L.t(.moreThanOnHand))")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(AppWarning.tint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                } else if packCount > 0 {
                    Text("\(line.packs - packCount) \(L.t(.left))")
                        .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                StockSheetButton(title: L.t(shortfall > 0 ? .takeOutAnyway : .takeOut), enabled: packCount > 0) {
                    onCommit(packCount)
                }
            }
        }
    }
}

struct AddUpStockSheet: View {
    let modelCode: String
    let line: StockLine
    let onCommit: (Int) -> Void

    @State private var packs: String = ""

    private var packCount: Int { Int(packs) ?? 0 }

    var body: some View {
        StockSheetFrame(title: L.t(.addUp), subtitle: "\(modelCode) \(line.color)") {
            VStack(spacing: 18) {
                Text("\(L.t(.onHand)): \(line.packs)")
                    .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                StockSheetField(placeholder: L.t(.packs), text: $packs, keyboard: .numberPad)
                    .digitsOnly($packs)
                    .limitInput($packs, to: 4)

                if packCount > 0 {
                    Text("\(line.packs + packCount) \(L.t(.left))")
                        .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                StockSheetButton(title: L.t(.addUp), enabled: packCount > 0) {
                    onCommit(packCount)
                }
            }
        }
    }
}

struct RecountStockSheet: View {
    let modelCode: String
    let line: StockLine
    let onCommit: (Int) -> Void

    @State private var packs: String = ""
    @State private var loaded = false

    private var packCount: Int { Int(packs) ?? 0 }

    var body: some View {
        StockSheetFrame(title: L.t(.recount), subtitle: "\(modelCode) \(line.color)") {
            VStack(spacing: 18) {
                Text("\(L.t(.recorded)): \(line.packs)")
                    .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                StockSheetField(placeholder: L.t(.packsOnShelf), text: $packs, keyboard: .numberPad)
                    .digitsOnly($packs)
                    .limitInput($packs, to: 4)

                StockSheetButton(title: L.t(.saveCount), enabled: !packs.isEmpty) {
                    onCommit(packCount)
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            packs = "\(max(0, line.packs))"
        }
    }
}

struct SetPriceSheet: View {
    let model: StockModel
    let onCommit: (Double) -> Void

    @State private var price: String = ""
    @State private var loaded = false

    private var value: Double {
        max(0, Double(price) ?? 0)
    }

    var body: some View {
        StockSheetFrame(title: L.t(.pricePerPiece), subtitle: model.code) {
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    StockSheetField(placeholder: "0", text: $price, keyboard: .decimalPad)
                        .decimalOnly($price)
                        .limitInput($price, to: 7)

                    Text(AppSettings.currencySymbol)
                        .font(.scaled(size: 17, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                StockSheetButton(title: L.t(.setPrice), enabled: true) {
                    onCommit(value)
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            price = model.hasPrice ? PriceText.editable(model.pricePerPiece) : ""
        }
    }
}

private struct StockSheetFrame<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                content
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .dismissKeyboardOnTap()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct StockSheetLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontDesign(.monospaced)
            .fontWeight(.bold)
            .tracking(2)
            .foregroundStyle(.secondary)
    }
}

private struct StockSheetField: View {
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.scaled(size: 17, weight: .semibold, design: .monospaced))
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .padding(.horizontal, 16)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.25), lineWidth: 1))
    }
}

private struct StockSheetButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            Text(title)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(Color(.systemBackground))
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(enabled ? 0.9 : 0.3)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
