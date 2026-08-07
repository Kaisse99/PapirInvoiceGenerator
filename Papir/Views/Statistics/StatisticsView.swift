//
//  StatisticsView.swift
//  What the invoices add up to. Swipe right from home, the direction the home
//  screen has been advertising since the arrows were named.
//  The money leads in the same oversized monospaced treatment the stock total
//  and the invoice total use, because it is the one number worth reading from
//  across the room, with the shipped and draft split beneath it so a large
//  figure cannot hide the fact that most of it has not left the shelf. Below
//  that, who buys and what sells, five each, ranked by money rather than by
//  count: a customer taking two expensive orders matters more than one taking
//  six small ones. Last, what the shelf itself is worth, which is the only
//  figure here that comes from stock rather than from invoices, and which says
//  out loud how many models it had to leave out for want of a price.
//  Every list says so plainly when it has nothing to show, since a business
//  in its first week should see empty cards rather than an empty screen.
//  Counts under a name are a glyph and a number rather than a number and a
//  noun, because the noun would have to decline: one invoice, two invoices,
//  five invoices are three different words in Ukrainian and Russian, and this
//  app has no machinery for that.
//  Used by: HomeView.
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Binding var currentScreen: HomeViewModel.Screen

    @Query(sort: \Invoice.date, order: .reverse)
    private var allInvoices: [Invoice]

    @Query(sort: \StockModel.code)
    private var stockModels: [StockModel]

    private var invoices: [Invoice] {
        viewModel.invoices(allInvoices)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    periodBar
                    revenueHeader
                    PaperclipDivider(iconSize: 36)
                    customersCard
                    modelsCard
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
            ForEach(StatsPeriod.allCases) { option in
                Button {
                    Haptics.light()
                    withAnimation(AppAnimation.list) {
                        viewModel.period = option
                    }
                } label: {
                    Label(
                        option.title,
                        systemImage: viewModel.period == option ? "checkmark" : "calendar"
                    )
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                Text(viewModel.period.title)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)).raisedShadow())
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.40), lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private var revenueHeader: some View {
        VStack(spacing: 4) {
            Text(L.t(.earnedCaps))
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(6)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(PriceText.display(viewModel.revenue(invoices)))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())

                Text(AppSettings.currencySymbol)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                statusPill(.shipped, amount: viewModel.revenue(invoices, status: .shipped))
                statusPill(.draft, amount: viewModel.revenue(invoices, status: .draft))
            }
            .padding(.top, 8)

            HStack(spacing: 14) {
                footnote("\(invoices.count)", L.t(.invoices))
                footnote(PriceText.display(viewModel.averageInvoice(invoices).rounded()), L.t(.averageInvoice))
                footnote("\(viewModel.packsShipped(invoices))", L.t(.packsLower))
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func statusPill(_ status: InvoiceStatus, amount: Double) -> some View {
        HStack(spacing: 6) {
            Text(status.label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            Text(PriceText.display(amount))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(status.tint)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(.secondarySystemGroupedBackground)))
        .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }

    private func footnote(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var customersCard: some View {
        card(L.t(.topCustomersCaps), entries: viewModel.topCustomers(invoices), icon: "doc.text")
    }

    private var modelsCard: some View {
        card(L.t(.topModelsCaps), entries: viewModel.topModels(invoices), icon: "shippingbox")
    }

    private func card(_ title: String, entries: [StatsEntry], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Text(L.t(.nothingHereYet))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        entryRow(entry, icon: icon)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)).raisedShadow())
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
        .padding(.horizontal, 20)
    }

    private func entryRow(_ entry: StatsEntry, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 9))

                    Text("\(entry.count)" + (entry.detail.map { " · \($0)" } ?? ""))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(PriceText.display(entry.amount))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(AppSettings.currencySymbol)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shelfCard: some View {
        let shelf = viewModel.stockValue(stockModels)

        return VStack(alignment: .leading, spacing: 10) {
            Text(L.t(.shelfWorthCaps))
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(PriceText.display(shelf.value))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(AppSettings.currencySymbol)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if shelf.unpriced > 0 {
                Text("\(shelf.unpriced) \(L.t(.modelsWithoutPrice))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)).raisedShadow())
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
        .padding(.horizontal, 20)
    }
}
