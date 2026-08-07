//
//  InvoiceDetailView.swift
//  One saved invoice as a paper receipt: parties, every row with its colors,
//  and the total. Three actions sit on top: open the stored PDF, re-generate
//  it in another language, or reopen the whole thing in NewInvoiceView through
//  the EditInvoiceSheet at the bottom of this file, which is a full-screen
//  cover that dismisses itself the moment that screen reports it is done.
//  View PDF stays disabled until a PDF exists on disk, and editing is closed
//  off entirely once the invoice is shipped: the packs it took are already
//  written down, so changing the rows underneath that record would leave stock
//  and invoice describing different shipments. Returning it to draft puts the
//  packs back and reopens editing.
//  Used by: MyInvoicesView, as its navigation destination for an Invoice.
//

import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let invoice: Invoice
    
    @StateObject private var viewModel = InvoiceDetailViewModel()
    @State private var showEditSheet = false
    @State private var showShipment = false
    @State private var shipmentNotice: String? = nil
    @State private var showStatusExplanation = false

    @Query(sort: \StockModel.code)
    private var stockModels: [StockModel]
    
    private static let totalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()
    
    private func formatted(_ value: Double) -> String {
        Self.totalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                actionButtons
                receiptHeader
                PaperclipDivider(iconSize: 36)
                rowsSection
                PaperclipDivider(iconSize: 36)
                totalSection
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(invoice.receiver.isEmpty ? L.t(.invoice) : invoice.receiver)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.black)
                    .padding(.horizontal, 4)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showStatusExplanation = true
                } label: {
                    Image(systemName: invoice.status.icon)
                        .toolbarIcon()
                        .foregroundStyle(invoice.status.tint)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(invoice.status.label)

                Button {
                    Haptics.medium()
                    if invoice.status == .shipped {
                        revertShipment()
                    } else {
                        showShipment = true
                    }
                } label: {
                    Image(systemName: invoice.status.actionIcon)
                        .toolbarIcon()
                        .foregroundStyle(Color.primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(invoice.status.actionLabel)
            }
        }
        .alert(
            invoice.status.label,
            isPresented: $showStatusExplanation
        ) {
            Button(L.t(.ok), role: .cancel) { showStatusExplanation = false }
        } message: {
            Text(invoice.status.explanation)
        }
        .sheet(isPresented: $viewModel.showLanguagePicker) {
            LanguagePickerSheet { language in
                viewModel.showLanguagePicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.generatePDF(for: invoice, language: language, context: modelContext)
                }
            }
            .presentationDetents([.height(338)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            EditInvoiceSheet(invoice: invoice)
        }
        .sheet(isPresented: $showShipment) {
            ShipmentSheet(invoice: invoice, stock: stockModels) { shortfall in
                shipmentNotice = shortfall > 0
                    ? "\(L.t(.stockUpdated)). \(L.t(.shortfallOnShipment))"
                    : L.t(.stockUpdated)
            }
        }
        .alert(
            L.t(.stockUpdated),
            isPresented: Binding(
                get: { shipmentNotice != nil },
                set: { if !$0 { shipmentNotice = nil } }
            )
        ) {
            Button(L.t(.ok), role: .cancel) { shipmentNotice = nil }
        } message: {
            Text(shipmentNotice ?? "")
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.pdfPreviewURL != nil },
                set: { if !$0 { viewModel.pdfPreviewURL = nil } }
            )
        ) {
            if let url = viewModel.pdfPreviewURL {
                PDFPreviewView(url: url, title: viewModel.pdfPreviewTitle)
            }
        }
        .alert(
            L.t(.couldNotGeneratePDF),
            isPresented: Binding(
                get: { viewModel.generationError != nil },
                set: { if !$0 { viewModel.generationError = nil } }
            )
        ) {
            Button(L.t(.ok), role: .cancel) {
                viewModel.generationError = nil
            }
        } message: {
            Text(viewModel.generationError ?? "")
        }
    }
    
    
    private func revertShipment() {
        do {
            try ShipmentPlanner.revert(invoice, stock: stockModels, context: modelContext)
            Haptics.success()
            shipmentNotice = L.t(.stockReturned)
        } catch {
            Haptics.error()
            shipmentNotice = "\(L.t(.couldNotSave)): \(error.localizedDescription)"
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Haptics.medium()
                    viewModel.viewExistingPDF(for: invoice)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.callout)
                        Text(L.t(.viewPDF))
                            .fontDesign(.monospaced)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(Color(.systemBackground))
                    .background(RoundedRectangle(cornerRadius: 12).fill(.primary))
                }
                .buttonStyle(.plain)
                .disabled(invoice.pdfFileName == nil)
                .opacity(invoice.pdfFileName == nil ? 0.4 : 1)
                
                Button {
                    Haptics.medium()
                    viewModel.showLanguagePicker = true
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGeneratingPDF {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.callout)
                        }
                        Text(viewModel.isGeneratingPDF ? "..." : L.t(.regenerate))
                            .fontDesign(.monospaced)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isGeneratingPDF)
            }
            
            if invoice.status == .shipped {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text(L.t(.lockedWhileShipped))
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.5))
                )
            } else {
                Button {
                    Haptics.medium()
                    showEditSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.callout)
                        Text(L.t(.makeChanges))
                            .fontDesign(.monospaced)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var receiptHeader: some View {
        VStack(spacing: 8) {
            if !invoice.sender.isEmpty {
                receiptRow(label: L.t(.from), value: invoice.sender)
            }
            if !invoice.receiver.isEmpty {
                receiptRow(label: L.t(.to), value: invoice.receiver)
            }
            receiptRow(label: L.t(.date), value: Self.dateFormatter.string(from: invoice.date))
            receiptRow(label: L.t(.items), value: "\(invoice.allItems.count)")
        }
        .padding(.horizontal, 24)
    }
    
    private func receiptRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.primary)
        }
    }
    
    private var rowsSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(invoice.orderedItems.enumerated()), id: \.element.id) { index, item in
                rowEntry(index: index + 1, item: item)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func rowEntry(index: Int, item: ItemRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("#\(index)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(item.name)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)

                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(item.unitCount)")
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text("×")
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Text("\(item.itemsPerUnit)")
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text("×")
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Text(formatted(item.price))
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text(AppSettings.currencySymbol)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatted(item.totalForItem))
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(AppSettings.currencySymbol)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }
            
            if !item.colors.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(item.colorBreakdown, id: \.self) { allocation in
                        Text("\(allocation.color) \(allocation.packs)")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(.systemBackground)))
                            .overlay(Capsule().stroke(.primary.opacity(0.35), lineWidth: 0.5))
                            .foregroundStyle(.primary.opacity(0.85))
                    }
                }
            }
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [3]))
                .frame(height: 1)
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 6)
        }
    }
    
    private var totalSection: some View {
        VStack(spacing: 6) {
            Text(L.t(.totalCaps))
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(6)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formatted(invoice.totalInvoicePrice))
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                
                Text(AppSettings.currencySymbol)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct EditInvoiceSheet: View {
    let invoice: Invoice
    @Environment(\.dismiss) var dismiss
    @State private var screen: HomeViewModel.Screen = .create
    @State private var deepLink: Invoice? = nil
    
    var body: some View {
        NewInvoiceView(
            viewModel: NewInvoiceViewModel(editingInvoice: invoice),
            currentScreen: $screen,
            deepLinkInvoice: $deepLink
        )
        .onChange(of: screen) { _, newScreen in
            if newScreen != .create {
                dismiss()
            }
        }
        .onChange(of: deepLink) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceDetailView(
            invoice: Invoice(
                items: [
                    ItemRow(name: "2337", unitCount: 6, itemsPerUnit: 1, price: 119, colors: ["чор", "біл"]),
                    ItemRow(name: "9813", unitCount: 3, itemsPerUnit: 1, price: 99, colors: ["кава"])
                ],
                date: .now,
                sender: "Anna",
                receiver: "Mom"
            )
        )
    }
    .modelContainer(for: [Invoice.self, ItemRow.self], inMemory: true)
}
