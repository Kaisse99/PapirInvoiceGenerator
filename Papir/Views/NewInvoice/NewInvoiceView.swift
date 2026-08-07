//
//  NewInvoiceView.swift
//  The form for writing an invoice: an optional sender and receiver header, a
//  stack of InvoiceRowCards, the running total, and save. Serves editing too:
//  when its view model was handed an existing invoice the labels and the button
//  change wording, and saving updates that invoice instead of adding one. A
//  finished save hands the invoice up through deepLinkInvoice and switches to
//  the list, which opens it.
//  The receiver offers matching contacts under it the way a row's name offers
//  stock codes, and for the same reason: three at most, only once there is a
//  letter to match on, so tapping into the field does not throw a list over
//  the form. The sender gets none of that; it arrives already filled from the
//  name in settings and is only ever typed over. What is showing is held in
//  state and swapped inside an animation, because the rows below have to move
//  down to make room and a list that appears under a moving form reads as a
//  glitch.
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
    
    enum HeaderField: Hashable {
        case sender, receiver
    }

    @FocusState private var focusedHeaderField: HeaderField?

    @Query(sort: \StockModel.code)
    private var stockModels: [StockModel]

    @Query(sort: [SortDescriptor(\Contact.lastName), SortDescriptor(\Contact.firstName)])
    private var contacts: [Contact]

    @State private var visibleContacts: [Contact] = []

    private var contactSuggestions: [Contact] {
        guard focusedHeaderField == .receiver, !contacts.isEmpty else { return [] }

        let typed = viewModel.receiver.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return [] }
        guard !contacts.contains(where: { $0.displayName.caseInsensitiveCompare(typed) == .orderedSame }) else {
            return []
        }

        return Array(contacts.filter { $0.matches(typed) }.prefix(3))
    }

    private func pickContact(_ contact: Contact) {
        viewModel.pick(contact)
        focusedHeaderField = nil
    }

    private func syncContactSuggestions() {
        let next = contactSuggestions
        guard next.map(\.persistentModelID) != visibleContacts.map(\.persistentModelID) else { return }
        withAnimation(AppAnimation.fast) {
            visibleContacts = next
        }
    }
    
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
                .readableWidth()
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onChange(of: viewModel.receiver) { _, _ in syncContactSuggestions() }
            .onChange(of: focusedHeaderField) { _, _ in syncContactSuggestions() }
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
                        senderReceiverField(
                            label: L.t(.sender),
                            text: $viewModel.sender,
                            focus: .sender
                        )

                        senderReceiverField(
                            label: L.t(.receiver),
                            text: $viewModel.receiver,
                            focus: .receiver
                        )

                        if focusedHeaderField == .receiver && !visibleContacts.isEmpty {
                            contactSuggestionList
                        }
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
    
    private func senderReceiverField(
        label: String,
        text: Binding<String>,
        focus: HeaderField
    ) -> some View {
        HStack(spacing: 12) {
            TextField(label, text: text)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .autocorrectionDisabled()
                .multilineTextAlignment(.leading)
                .limitInput(text, to: 40)
                .focused($focusedHeaderField, equals: focus)
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
                .stroke(
                    focusedHeaderField == focus
                        ? Color.blue.opacity(0.9)
                        : Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.15),
                    lineWidth: 1
                )
        )
        .animation(AppAnimation.fast, value: focusedHeaderField == focus)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { focusedHeaderField = focus }
    }
    
    private var contactSuggestionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleContacts.enumerated()), id: \.element.persistentModelID) { index, contact in
                Button {
                    Haptics.light()
                    pickContact(contact)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(contact.displayName)
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if !contact.whereTo.isEmpty {
                                Text(contact.whereTo)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 6)

                        if !contact.phone.isEmpty {
                            Text(contact.phone)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < visibleContacts.count - 1 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 1)
                        .padding(.leading, 42)
                        .padding(.trailing, 14)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground).opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.15), lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .top)))
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
                            pricePerPiece: model.pricePerPiece,
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
