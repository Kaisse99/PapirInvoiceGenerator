//
//  MovementLogView.swift
//  Everything that has moved on or off the shelf, newest first. This is what
//  makes a count answerable: when a number looks wrong the question is always
//  "what happened to it", and a running list of changes answers that where a
//  single figure never can. Newest first, grouped by day, each group announced
//  by a centred rule carrying that date; the rule scrolls away with its entries
//  rather than pinning, because a heading stuck to the top of a log claims to
//  describe rows it no longer covers. Two filters sit above it, by model and by
//  day, because a month of use makes the unfiltered list long by design.
//  Opening it from a model's own screen starts filtered to that model. Changing
//  a filter animates on the identity of the entries on screen, the same way the
//  invoice list does, so rows leave and arrive rather than the page redrawing
//  under the finger.
//  Used by: StockView, StockModelDetailView.
//

import SwiftUI
import SwiftData

struct MovementLogView: View {
    @Environment(\.dismiss) private var dismiss

    var modelCode: String? = nil

    @Query(sort: \StockMovement.date, order: .reverse)
    private var allMovements: [StockMovement]

    @State private var selectedModel: String? = nil
    @State private var selectedDay: Date? = nil
    @State private var loaded = false

    private static func dayFormatter(_ language: AppLanguage) -> DateFormatter {
        let f = DateFormatter()
        f.locale = language.locale
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    private var movements: [StockMovement] {
        allMovements.filter { movement in
            let modelMatches = selectedModel == nil || movement.modelCode == selectedModel
            let dayMatches = selectedDay == nil
                || Calendar.current.isDate(movement.date, inSameDayAs: selectedDay!)
            return modelMatches && dayMatches
        }
    }

    private var knownModels: [String] {
        Array(Set(allMovements.map(\.modelCode))).sorted()
    }

    private var knownDays: [Date] {
        Array(Set(allMovements.map { Calendar.current.startOfDay(for: $0.date) }))
            .sorted(by: >)
    }

    private var days: [(key: Date, entries: [StockMovement])] {
        let grouped = Dictionary(grouping: movements) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped
            .map { (key: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !allMovements.isEmpty {
                        filterBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    if movements.isEmpty {
                        emptyState
                            .transition(.opacity)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(days, id: \.key) { day in
                                dayRule(day.key)
                                    .transition(.opacity)

                                ForEach(day.entries, id: \.persistentModelID) { movement in
                                    entryRow(movement)
                                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
                .animation(AppAnimation.list, value: movements.map(\.persistentModelID))
            }
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L.t(.history))
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Text(L.t(.done))
                            .font(.callout)
                            .fontDesign(.monospaced)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .tint(Color.primary)
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            selectedModel = modelCode
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            filterMenu(
                title: selectedModel ?? L.t(.allModels),
                isActive: selectedModel != nil,
                icon: "shippingbox"
            ) {
                Button(L.t(.allModels)) {
                    Haptics.light()
                    withAnimation(AppAnimation.list) { selectedModel = nil }
                }
                ForEach(knownModels, id: \.self) { code in
                    Button(code) {
                        Haptics.light()
                        withAnimation(AppAnimation.list) { selectedModel = code }
                    }
                }
            }

            filterMenu(
                title: selectedDay.map { Self.dayFormatter(AppSettings.language).string(from: $0) } ?? L.t(.allDays),
                isActive: selectedDay != nil,
                icon: "calendar"
            ) {
                Button(L.t(.allDays)) {
                    Haptics.light()
                    withAnimation(AppAnimation.list) { selectedDay = nil }
                }
                ForEach(knownDays, id: \.self) { day in
                    Button(Self.dayFormatter(AppSettings.language).string(from: day)) {
                        Haptics.light()
                        withAnimation(AppAnimation.list) { selectedDay = day }
                    }
                }
            }
        }
    }

    private func filterMenu<Content: View>(
        title: String,
        isActive: Bool,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(isActive ? 0.12 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(isActive ? 0.40 : 0.15), lineWidth: 1)
            )
        }
        .tint(Color.primary)
        .animation(AppAnimation.list, value: isActive)
    }

    private func dayRule(_ date: Date) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.primary.opacity(0.14))
                .frame(height: 1)

            Text(Self.dayFormatter(AppSettings.language).string(from: date))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.secondary)
                .fixedSize()

            Rectangle()
                .fill(Color.primary.opacity(0.14))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private func entryRow(_ movement: StockMovement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: movement.kind.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(movement.kind.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(movement.modelCode)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)

                    Text(movement.color)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 5) {
                    Text(movement.kind.label)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)

                    if let context = movement.context {
                        Text("· \(context)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            Text(movement.packs > 0 ? "+\(movement.packs)" : "\(movement.packs)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(movement.packs >= 0 ? Color.primary : Color.orange)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L.t(allMovements.isEmpty ? .noMovements : .noMatches))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 110)
        .frame(maxWidth: .infinity)
    }
}

extension StockMovementKind {
    var icon: String {
        switch self {
        case .received:   return "arrow.down.circle.fill"
        case .removed:    return "arrow.up.circle.fill"
        case .shipped:    return "shippingbox.fill"
        case .returned:   return "arrow.uturn.backward.circle.fill"
        case .recounted:  return "equal.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .received:   return Color(red: 0.13, green: 0.50, blue: 0.29)
        case .removed:    return .orange
        case .shipped:    return Color(red: 0.20, green: 0.48, blue: 0.90)
        case .returned:   return .secondary
        case .recounted:  return .secondary
        }
    }

    var label: String {
        switch self {
        case .received:   return L.t(.movementReceived)
        case .removed:    return L.t(.movementRemoved)
        case .shipped:    return L.t(.shipped)
        case .returned:   return L.t(.movementReturned)
        case .recounted:  return L.t(.movementRecounted)
        }
    }
}
