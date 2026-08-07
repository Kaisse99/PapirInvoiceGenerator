//
//  StatisticsView.swift
//  What the shipped invoices add up to. Swipe right from home, the direction
//  the home screen has been advertising since the arrows were named.
//  Only shipped money is shown anywhere on this screen: a draft is a promise,
//  and a screen that added promises to takings taught the reader to distrust
//  every number on it. The period is a real month picked from the months that
//  hold invoices, or the year, or everything, so a question like what did
//  March do has a one-tap answer.
//  Under the money sits the same line chart the author's other app uses, on
//  Swift Charts: an area wash under an ink-blue line, zero-filled buckets so
//  empty days read as flat rather than skipped, and touch to inspect a single
//  day or month with the value on a chip. Blue because shipped has been blue
//  everywhere in the app since the invoice list, so the line reads as the
//  same fact drawn over time.
//  Then the breakdowns, each a ranked card of five: models by money, models by
//  packs, and buyers, since the most profitable model, the most moved model
//  and the best customer are three different questions with three different
//  answers. Model rows carry their colour chips so what sells and in which
//  colour is one glance, and buyers group by contact when the invoice was
//  addressed to one, by typed name when not. The shelf card stays last: it is
//  the one figure that comes from stock rather than from invoices.
//  Used by: HomeView.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Binding var currentScreen: HomeViewModel.Screen

    @State private var selectedDate: Date? = nil
    @State private var modelsShown = StatisticsView.modelPage
    @State private var buyersShown = StatisticsView.buyerPage

    private static let modelPage = 5
    private static let modelStep = 20
    private static let buyerPage = 5
    private static let buyerStep = 10

    @Query(sort: \Invoice.date, order: .reverse)
    private var allInvoices: [Invoice]

    @Query(sort: \StockModel.code)
    private var stockModels: [StockModel]

    private var shipped: [Invoice] {
        viewModel.shipped(allInvoices)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    periodBar
                    revenueHeader
                    chartCard
                    PaperclipDivider(iconSize: 36)
                    profitabilityCard
                    buyersCard
                    shelfCard
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
                .readableWidth()
                .animation(AppAnimation.list, value: viewModel.period)
            }
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .tint(Color.primary)
            .onChange(of: viewModel.period) { _, _ in
                selectedDate = nil
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Haptics.light()
                withAnimation(AppAnimation.smooth) {
                    currentScreen = .home
                }
            } label: {
                Image(systemName: "house")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.home))
        }

        ToolbarItem(placement: .principal) {
            Text(L.t(.statisticsTitle))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
        }
    }

    private var periodBar: some View {
        Menu {
            ForEach(viewModel.availableMonths(allInvoices), id: \.self) { month in
                Button {
                    Haptics.light()
                    withAnimation(AppAnimation.list) {
                        viewModel.period = .month(month)
                    }
                } label: {
                    Label(
                        StatsPeriod.monthTitle(month),
                        systemImage: viewModel.period == .month(month) ? "checkmark" : "calendar"
                    )
                }
            }

            Divider()

            periodButton(.thisYear)
            periodButton(.everything)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.scaled(size: 13, weight: .medium))
                Text(viewModel.period.title)
                    .font(.scaled(size: 15, weight: .semibold, design: .monospaced))
                Image(systemName: "chevron.down")
                    .font(.scaled(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)).raisedShadow())
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.40), lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private func periodButton(_ period: StatsPeriod) -> some View {
        Button {
            Haptics.light()
            withAnimation(AppAnimation.list) {
                viewModel.period = period
            }
        } label: {
            Label(
                period.title,
                systemImage: viewModel.period == period ? "checkmark" : "calendar"
            )
        }
    }

    private var revenueHeader: some View {
        VStack(spacing: 4) {
            Text(L.t(.earnedCaps))
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(6)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(PriceText.display(viewModel.revenue(shipped)))
                    .font(.scaled(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())

                Text(AppSettings.currencySymbol)
                    .font(.scaled(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                footnote("\(shipped.count)", L.t(.invoicesShipped))
                footnote(PriceText.display(viewModel.averageInvoice(shipped).rounded()), L.t(.averageInvoice))
                footnote("\(viewModel.packsSold(shipped))", L.t(AppSettings.sellsInPacks ? .packsSoldLower : .itemsSoldLower))
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func footnote(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.scaled(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(.scaled(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var chartCard: some View {
        let points = viewModel.series(shipped)
        let hasSales = points.contains { $0.amount > 0 }
        let bucketCount = points.filter { $0.amount > 0 }.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                caps(L.t(.salesOverTimeCaps))

                Spacer()

                if hasSales && bucketCount > 0 {
                    Text("≈\(compactMoney(viewModel.revenue(shipped) / Double(bucketCount))) \(L.t(viewModel.period.bucketsByMonth ? .perMonthLower : .perDayLower))")
                        .font(.scaled(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            if hasSales {
                chart(points)
            } else {
                Text(L.t(.noSalesInPeriod))
                    .font(.scaled(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding(.horizontal, 20)
    }

    private func chart(_ points: [StatsPoint]) -> some View {
        let lineColor = InvoiceStatus.shipped.tint
        let maxAmount = points.map(\.amount).max() ?? 0
        let selected = selectedPoint(points)

        return Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("date", point.date),
                    y: .value("amount", point.amount)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor.opacity(0.22), lineColor.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("date", point.date),
                    y: .value("amount", point.amount)
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(lineColor)
            }

            if let selected {
                RuleMark(x: .value("selected", selected.date))
                    .foregroundStyle(Color.primary.opacity(0.2))
                    .zIndex(-1)
                    .annotation(
                        position: .top,
                        spacing: 6,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        selectionChip(selected)
                    }

                PointMark(
                    x: .value("selected", selected.date),
                    y: .value("amount", selected.amount)
                )
                .symbolSize(80)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))

                PointMark(
                    x: .value("selected", selected.date),
                    y: .value("amount", selected.amount)
                )
                .symbol(.circle.strokeBorder(lineWidth: 2.2))
                .symbolSize(80)
                .foregroundStyle(lineColor)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: 0...(maxAmount > 0 ? maxAmount * 1.15 : 1))
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(compactMoney(amount))
                            .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues(points)) { _ in
                AxisValueLabel(format: xAxisFormat(points))
                    .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 190)
    }

    private func selectedPoint(_ points: [StatsPoint]) -> StatsPoint? {
        guard let selectedDate else { return nil }
        return points.last { $0.date <= selectedDate }
    }

    private func selectionChip(_ point: StatsPoint) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(PriceText.display(point.amount))
                    .font(.scaled(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text(AppSettings.currencySymbol)
                    .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text(chipDate(point.date))
                .font(.scaled(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
                .raisedShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.8)
        )
    }

    private func chipDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppSettings.language.locale
        formatter.dateFormat = viewModel.period.bucketsByMonth ? "LLLL yyyy" : "d MMMM"
        return formatter.string(from: date).capitalized
    }

    private func xAxisValues(_ points: [StatsPoint]) -> AxisMarkValues {
        if viewModel.period.bucketsByMonth {
            return .stride(by: .month, count: max(1, points.count / 6))
        }
        return .stride(by: .day, count: max(1, points.count / 5))
    }

    private func xAxisFormat(_ points: [StatsPoint]) -> Date.FormatStyle {
        guard viewModel.period.bucketsByMonth else {
            return .dateTime.day()
        }
        if points.count > 12 {
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
        return .dateTime.month(.abbreviated)
    }

    private func compactMoney(_ value: Double) -> String {
        if value >= 1_000_000 {
            return "\(shortNumber(value / 1_000_000))M"
        }
        if value >= 1_000 {
            return "\(shortNumber(value / 1_000))K"
        }
        return "\(Int(value.rounded()))"
    }

    private func shortNumber(_ value: Double) -> String {
        value >= 100
            ? "\(Int(value.rounded()))"
            : String(format: "%.1f", value).replacingOccurrences(of: ".0", with: "")
    }

    private var profitabilityCard: some View {
        let all = viewModel.byProfit(shipped)
        let shown = Array(all.prefix(modelsShown))

        return VStack(alignment: .leading, spacing: 14) {
            caps(L.t(.profitabilityCaps))

            if all.isEmpty {
                emptyLine
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, stat in
                        modelRow(rank: index + 1, stat: stat)
                    }
                }

                expander(
                    shown: modelsShown,
                    total: all.count,
                    step: Self.modelStep,
                    reset: Self.modelPage
                ) { modelsShown = $0 }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding(.horizontal, 20)
    }

    private func modelRow(rank: Int, stat: ModelStat) -> some View {
        HStack(alignment: .top, spacing: 10) {
            rankBadge(rank)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(stat.name)
                        .font(.scaled(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 8)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(PriceText.display(stat.money))
                            .font(.scaled(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.primary)
                        Text(AppSettings.currencySymbol)
                            .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(L.t(AppSettings.sellsInPacks ? .packsSoldLabel : .itemsSoldLabel)): \(stat.packs)")
                    .font(.scaled(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                if !stat.colors.isEmpty {
                    colorChips(stat.colors)
                }
            }
        }
    }

    private func expander(
        shown: Int,
        total: Int,
        step: Int,
        reset: Int,
        set: @escaping (Int) -> Void
    ) -> some View {
        Group {
            if total > reset {
                let remaining = max(0, total - shown)
                Button {
                    Haptics.light()
                    withAnimation(AppAnimation.list) {
                        set(remaining > 0 ? min(total, shown + step) : reset)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: remaining > 0 ? "chevron.down" : "chevron.up")
                            .font(.scaled(size: 10, weight: .bold))
                        Text(
                            remaining > 0
                                ? String(format: L.t(.showMoreFormat), min(step, remaining))
                                : L.t(.showLess)
                        )
                        .font(.scaled(size: 12, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    private func colorChips(_ colors: [ColorAllocation]) -> some View {
        FlowLayout(spacing: 5) {
            ForEach(colors, id: \.color) { allocation in
                chip("\(allocation.color) \(allocation.packs)")
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.scaled(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.primary.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.primary.opacity(0.05)))
            .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }

    private var buyersCard: some View {
        let all = viewModel.allBuyers(shipped)
        let shown = Array(all.prefix(buyersShown))

        return VStack(alignment: .leading, spacing: 14) {
            caps(L.t(.topBuyersCaps))

            if all.isEmpty {
                emptyLine
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, buyer in
                        buyerRow(rank: index + 1, buyer: buyer)
                    }
                }

                expander(
                    shown: buyersShown,
                    total: all.count,
                    step: Self.buyerStep,
                    reset: Self.buyerPage
                ) { buyersShown = $0 }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding(.horizontal, 20)
    }

    private func buyerRow(rank: Int, buyer: BuyerStat) -> some View {
        HStack(alignment: .center, spacing: 10) {
            rankBadge(rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(buyer.name)
                    .font(.scaled(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(L.t(.ordersMade)): \(buyer.invoices)")
                    .font(.scaled(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(PriceText.display(buyer.money))
                    .font(.scaled(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(AppSettings.currencySymbol)
                    .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shelfCard: some View {
        let shelf = viewModel.stockValue(stockModels)

        return VStack(alignment: .leading, spacing: 10) {
            caps(L.t(.inventoryValueCaps))

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(PriceText.display(shelf.value))
                    .font(.scaled(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(AppSettings.currencySymbol)
                    .font(.scaled(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(viewModel.unitsInStock(stockModels))")
                        .font(.scaled(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(L.t(.unitsInStock).uppercased())
                        .font(.scaled(size: 8, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if shelf.unpriced > 0 {
                Text("\(shelf.unpriced) \(L.t(.modelsWithoutPrice))")
                    .font(.scaled(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppWarning.tint)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding(.horizontal, 20)
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.scaled(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.primary.opacity(0.06)))
            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }

    private func caps(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .fontDesign(.monospaced)
            .fontWeight(.bold)
            .tracking(2)
            .foregroundStyle(.secondary)
    }

    private var emptyLine: some View {
        Text(L.t(.nothingHereYet))
            .font(.scaled(size: 14, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    func cardSurface() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .raisedShadow()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
            )
    }
}
