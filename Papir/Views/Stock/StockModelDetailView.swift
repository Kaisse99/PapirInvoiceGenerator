//
//  StockModelDetailView.swift
//  One model's shelf. The head of the screen answers the only question worth
//  asking from across the room, how many packs are here, in the same oversized
//  monospaced treatment the invoice total uses, with every color under it
//  spelled out beneath. Below that, a card per color carrying a state stripe
//  down its edge: ink when stocked, amber at zero, red when the count has gone
//  negative. Taking stock out is the everyday action so it is the filled
//  button; recounting is the correction, so it is the quiet outlined one.
//  Taking stock in is also how a new color appears, so there is no separate
//  add-color step.
//  Used by: StockView.
//

import SwiftUI
import SwiftData

struct StockModelDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    let model: StockModel
    @ObservedObject var viewModel: StockViewModel

    @State private var showReceive = false
    @State private var withdrawTarget: StockLine? = nil
    @State private var recountTarget: StockLine? = nil
    @State private var showHistory = false

    private var lines: [StockLine] {
        model.orderedLines
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                totalHeader
                colorsOverview
                PaperclipDivider(iconSize: 36)

                if lines.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        ForEach(lines) { line in
                            lineCard(line)
                                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        }
                    }
                    .padding(.horizontal, 20)
                }

                receiveButton
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(AppAnimation.list, value: lines.map(\.color))
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(model.code)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.black)
                    .padding(.horizontal, 4)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .toolbarIcon()
                        .foregroundStyle(Color.primary)
                }
                .accessibilityLabel(L.t(.history))
            }
        }
        .fullScreenCover(isPresented: $showHistory) {
            MovementLogView(modelCode: model.code)
        }
        .sheet(isPresented: $showReceive) {
            ReceiveStockSheet(model: model) { color, packs in
                viewModel.receive(packs: packs, color: color, into: model, context: modelContext)
                showReceive = false
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $withdrawTarget) { line in
            WithdrawStockSheet(modelCode: model.code, line: line) { packs in
                viewModel.withdraw(packs: packs, from: line, in: model, context: modelContext)
                withdrawTarget = nil
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $recountTarget) { line in
            RecountStockSheet(modelCode: model.code, line: line) { packs in
                viewModel.recount(line: line, to: packs, in: model, context: modelContext)
                recountTarget = nil
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
    }


    private var totalHeader: some View {
        VStack(spacing: 4) {
            Text(L.t(.totalPacksCaps))
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(6)
                .foregroundStyle(.secondary)

            Text("\(model.totalPacks)")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(model.state.tint)
                .contentTransition(.numericText())
                .animation(AppAnimation.quick, value: model.totalPacks)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var colorsOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.t(.colorsCaps))
                .font(.caption)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(4)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if lines.isEmpty {
                Text(L.t(.noColorsYet))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.7))
            } else {
                FlowLayout(spacing: 7) {
                    ForEach(lines) { line in
                        overviewChip(line)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func overviewChip(_ line: StockLine) -> some View {
        HStack(spacing: 6) {
            Text(line.color)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(line.state == .stocked ? .primary : line.state.tint)

            Text("\(line.packs)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(line.state.tint)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(line.state.isFlagged ? line.state.tint.opacity(0.14) : Color.primary.opacity(0.06)))
        .overlay(Capsule().stroke(line.state.accent.opacity(line.state.isFlagged ? 0.7 : 0.4), lineWidth: 0.9))
    }

    private func lineCard(_ line: StockLine) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(line.color)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    if line.state.isFlagged {
                        Text(line.state.label.uppercased())
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(line.state.tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(line.state.tint.opacity(0.16)))
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: -2) {
                    Text("\(line.packs)")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(line.state.tint)
                        .contentTransition(.numericText())
                        .animation(AppAnimation.quick, value: line.packs)

                    Text(L.t(line.packs == 1 ? .pack : .packsLower))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 10) {
                takeOutButton(line)
                recountButton(line)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
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
        .contextMenu {
            Button(role: .destructive) {
                viewModel.removeLine(line, from: model, context: modelContext)
            } label: {
                Label("\(L.t(.remove)) \(line.color)", systemImage: "trash")
            }
        }
    }

    private func takeOutButton(_ line: StockLine) -> some View {
        Button {
            Haptics.light()
            withdrawTarget = line
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 13, weight: .medium))
                Text(L.t(.takeOut))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(Color(.systemBackground))
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.primary.opacity(0.88)))
        }
        .buttonStyle(.plain)
    }

    private func recountButton(_ line: StockLine) -> some View {
        Button {
            Haptics.light()
            recountTarget = line
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                Text(L.t(.recount))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(.secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.primary.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var receiveButton: some View {
        Button {
            Haptics.light()
            showReceive = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                Text(L.t(.takeStockIn))
                    .fontDesign(.monospaced)
            }
            .foregroundStyle(Color.primary)
            .padding(.vertical, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L.t(.nothingCounted))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}
