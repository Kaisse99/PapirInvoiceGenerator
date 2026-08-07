//
//  StockModelCard.swift
//  One model as a card in the stock list. The code leads, the pack total sits
//  opposite it as the one number worth reading at a glance, and the colors run
//  underneath the way she says them out loud, "Black 5, White 10, Blue 0".
//  The colors carry their own state and say it in their own chips, so the code
//  no longer wears a badge summarising them: it repeated in words what the row
//  underneath already says in colour. The total is coloured by the total
//  alone, so one color at zero does not paint a full shelf as a problem, and
//  colors sitting at zero stay on the card in orange, because being out of a
//  color is the thing she most needs to see.
//  Used by: StockView.
//

import SwiftUI

struct StockModelCard: View {
    let model: StockModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(model.code)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("\(model.totalPacks)")
                    .font(.system(size: 27, weight: .bold, design: .monospaced))
                    .foregroundStyle(model.totalState.tint)
                    .contentTransition(.numericText())
                    .animation(AppAnimation.quick, value: model.totalPacks)

                Text(L.t(.packsLower))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            Group {
                if model.allLines.isEmpty {
                    Text(L.t(.noColorsYet))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(model.orderedLines) { line in
                            colorChip(line)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 3)
    }

    private func colorChip(_ line: StockLine) -> some View {
        HStack(spacing: 6) {
            Text(line.color)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(line.state == .stocked ? .primary : line.state.tint)

            Text("\(line.packs)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(line.state.tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(line.state.isFlagged ? line.state.tint.opacity(0.12) : Color.primary.opacity(0.05)))
        .overlay(Capsule().stroke(line.state.isFlagged ? line.state.tint.opacity(0.45) : Color.primary.opacity(0.12), lineWidth: 0.8))
    }
}
