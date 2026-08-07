//
//  NewInvoiceView.swift
//  The form for writing an invoice: an optional sender and receiver header, a
//  stack of InvoiceRowCards, the running total, and save. Serves editing too:
//  when its view model was handed an existing invoice the labels and the button
//  change wording, and saving updates that invoice instead of adding one. A
//  finished save hands the invoice up through deepLinkInvoice and switches to
//  the list, which opens it.
//  Used by: HomeView, EditInvoiceSheet in InvoiceDetailView.
//

import SwiftUI
import SwiftData

struct NewInvoiceView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject var viewModel: NewInvoiceViewModel
    @Binding var currentScreen: HomeViewModel.Screen
    @Binding var deepLinkInvoice: Invoice?
    
    @FocusState private var isAnyFieldFocused: Bool

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
    
    private func formattedTotal(_ value: Double) -> String {
        Self.totalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    senderReceiverSection
                    rowsSection
                    addRowButton
                    PaperclipDivider()
                    totalSection
                    actionButtons
                }
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
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
        }
        
        ToolbarItem(placement: .principal) {
            Text(L.t(viewModel.isEditMode ? .editInvoice : .newInvoice))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
        }

    }
    
    private var senderReceiverSection: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.soft()
                withAnimation(AppAnimation.snappy) {
                    viewModel.showHeader.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.showHeader ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    Spacer()
                    Text(L.t(.senderAndReceiver))
                        .font(.callout)
                        .fontDesign(.monospaced)
                    Spacer()
                    Image(systemName: viewModel.showHeader ? "chevron.down" : "chevron.left")
                        .font(.caption)
                }
                .foregroundStyle(.primary.opacity(0.9))
            }
            
            if viewModel.showHeader {
                VStack(spacing: 0) {
                    Divider()
                    VStack(spacing: 14) {
                        senderReceiverField(label: L.t(.sender), text: $viewModel.sender)
                        senderReceiverField(label: L.t(.receiver), text: $viewModel.receiver)
                    }
                    .padding(.vertical, 14)
                    Divider()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private func senderReceiverField(label: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            TextField(label, text: text)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.leading)
                .limitInput(text, to: 40)
                .frame(maxWidth: .infinity)
            
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.0 : 0.04), radius: 8, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var rowsSection: some View {
        VStack(spacing: 16) {
            ForEach($viewModel.rows) { $row in
                InvoiceRowCard(
                    rowNumber: (viewModel.rows.firstIndex(where: { $0.id == row.id }) ?? 0) + 1,
                    name: $row.name,
                    unitCount: $row.unitCount,
                    itemsPerUnit: $row.itemsPerUnit,
                    price: $row.price,
                    colors: $row.colors,
                    colorPacks: $row.colorPacks,
                    isLocked: $row.isLocked,
                    nameError: row.nameError,
                    unitsError: row.unitsError,
                    perUnitError: row.perUnitError,
                    priceError: row.priceError,
                    stockSuggestions: stockModels.map { model in
                        StockSuggestion(
                            code: model.code,
                            packs: model.totalPacks,
                            colorStock: model.orderedLines.map { ColorAllocation(color: $0.color, packs: $0.packs) }
                        )
                    },
                    onClearError: { field in
                        viewModel.clearError(for: row.id, field: field)
                    },
                    onClearNameError: {
                        viewModel.clearNameError(for: row.id)
                    },
                    onDelete: {
                        viewModel.deleteRow(id: row.id)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var addRowButton: some View {
        Button {
            viewModel.addRow()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                Text(L.t(.addNewRow))
                    .fontDesign(.monospaced)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
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
                Text(formattedTotal(viewModel.liveTotal))
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.9))
                    .contentTransition(.numericText())
                    .animation(AppAnimation.quick, value: viewModel.liveTotal)
                
                Text(AppSettings.currencySymbol)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.medium()
                handleSave()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(Color(.systemBackground))
                            .controlSize(.small)
                    } else {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.callout)
                    }
                    Text(saveButtonLabel)
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(Color(.systemBackground))
                .background(RoundedRectangle(cornerRadius: 14).fill(.primary.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
            
            if let errorMsg = viewModel.saveErrorMessage {
                Text(errorMsg)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private var saveButtonLabel: String {
        if viewModel.isSaving {
            return L.t(viewModel.isEditMode ? .updating : .saving)
        }
        return L.t(viewModel.isEditMode ? .update : .saveInvoice)
    }
    
    private func handleSave() {
        viewModel.saveAndGeneratePDF(context: modelContext) { saved in
            guard let saved else { return }
            deepLinkInvoice = saved
            withAnimation(AppAnimation.smooth) {
                currentScreen = .menu
            }
        }
    }
}
