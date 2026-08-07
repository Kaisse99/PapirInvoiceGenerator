//
//  MyInvoicesView.swift
//  The saved-invoice list: search and sort on top, a card per invoice, and a
//  long-press menu for preview, share, duplicate, and delete. The checklist
//  button turns the rows into checkboxes with a batch bar along the bottom.
//  Owns the @Query and the navigation stack: tapping a card opens
//  InvoiceDetailView, and a freshly saved invoice arrives through
//  deepLinkInvoice and opens itself. Searching or re-sorting animates the rows
//  in and out because the stack animates on the identity of what it is showing,
//  not on the individual filter values.
//  The address book opens from here rather than from the home swipe, because
//  it is a thing you consult while writing or checking an invoice rather than
//  a destination of its own.
//  Selection mode does not swap the row for a different one: the same button
//  and the same card stay on screen and a checkbox slides in beside them, so
//  turning it on reads as the list making room rather than as every row being
//  replaced mid-animation by something that looks almost the same.
//  Used by: HomeView.
//

import SwiftUI
import SwiftData

struct MyInvoicesView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = MyInvoicesViewModel()
    @Binding var currentScreen: HomeViewModel.Screen
    @Binding var deepLinkInvoice: Invoice?
    
    @State private var navigationPath = NavigationPath()
    @State private var showAddressBook = false
    
    @Query(sort: \Invoice.date, order: .reverse)
    private var allInvoices: [Invoice]
    
    private var invoices: [Invoice] {
        viewModel.filteredAndSorted(allInvoices)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                if allInvoices.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        searchAndSortBar
                        
                        if invoices.isEmpty {
                            noResultsState
                                .transition(.opacity)
                        } else {
                            LazyVStack(spacing: 22) {
                                ForEach(invoices) { invoice in
                                    invoiceRow(for: invoice)
                                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, viewModel.isEditing ? 100 : 40)
                        }
                    }
                    .padding(.top, 12)
                    .readableWidth()
                    .animation(AppAnimation.list, value: invoices.map(\.id))
                }
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                if viewModel.isEditing && !viewModel.selectedIDs.isEmpty {
                    batchActionBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert(
                L.t(.deleteInvoiceTitle),
                isPresented: Binding(
                    get: { viewModel.invoiceToDelete != nil },
                    set: { if !$0 { viewModel.invoiceToDelete = nil } }
                ),
                presenting: viewModel.invoiceToDelete
            ) { invoice in
                Button(L.t(.delete), role: .destructive) {
                    viewModel.delete(invoice, context: modelContext)
                }
                Button(L.t(.cancel), role: .cancel) {
                    viewModel.invoiceToDelete = nil
                }
            } message: { _ in
                Text(L.t(.cannotBeUndone))
            }
            .alert(
                "Delete \(viewModel.selectedIDs.count) invoice\(viewModel.selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $viewModel.showBatchDeleteAlert
            ) {
                Button(L.t(.delete), role: .destructive) {
                    viewModel.deleteSelected(from: allInvoices, context: modelContext)
                }
                Button(L.t(.cancel), role: .cancel) {}
            } message: {
                Text(L.t(.cannotBeUndone))
            }
            .onChange(of: allInvoices.count) { _, newCount in
                viewModel.exitEditingIfEmpty(invoiceCount: newCount)
            }
            .alert(
                L.t(.couldNotSave),
                isPresented: Binding(
                    get: { viewModel.saveError != nil },
                    set: { if !$0 { viewModel.saveError = nil } }
                )
            ) {
                Button(L.t(.ok), role: .cancel) { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "")
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { viewModel.previewURL != nil },
                    set: { if !$0 { viewModel.previewURL = nil } }
                )
            ) {
                if let url = viewModel.previewURL {
                    PDFPreviewView(url: url, title: viewModel.previewTitle)
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { !viewModel.shareURLs.isEmpty },
                    set: { if !$0 { viewModel.shareURLs = [] } }
                )
            ) {
                ShareSheet(items: viewModel.shareURLs)
            }
            .onChange(of: deepLinkInvoice) { _, newValue in
                if let invoice = newValue {
                    navigationPath.append(invoice)
                    deepLinkInvoice = nil
                }
            }
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .fullScreenCover(isPresented: $showAddressBook) {
                AddressBookView()
            }
            .tint(Color.primary)
        }
    }
    
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !viewModel.isEditing {
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
        }
        
        ToolbarItem(placement: .principal) {
            Text(viewModel.isEditing ? viewModel.selectionTitle : L.t(.invoices))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
                .contentTransition(.opacity)
                .animation(AppAnimation.smooth, value: viewModel.isEditing)
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !viewModel.isEditing {
                Button {
                    Haptics.light()
                    showAddressBook = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .toolbarIcon()
                        .foregroundStyle(Color.primary)
                }
                .accessibilityLabel(L.t(.addressBook))
            }

            if !allInvoices.isEmpty {
                Button {
                    viewModel.toggleEditing()
                } label: {
                    Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "checklist")
                        .toolbarIcon()
                        .foregroundStyle(Color.primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(L.t(viewModel.isEditing ? .doneSelecting : .selectInvoices))
            }
        }
    }
    
    private var searchAndSortBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                TextField(L.t(.searchInvoices), text: $viewModel.searchText)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        withAnimation(AppAnimation.list) { viewModel.searchText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)).raisedShadow())
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.primary.opacity(0.40), lineWidth: 1)
            )
            .animation(AppAnimation.list, value: viewModel.searchText.isEmpty)
            
            Menu {
                ForEach(MyInvoicesViewModel.SortOption.allCases) { option in
                    Button {
                        Haptics.light()
                        withAnimation(AppAnimation.list) {
                            viewModel.sortOption = option
                        }
                    } label: {
                        Label(
                            option.title,
                            systemImage: viewModel.sortOption == option ? "checkmark" : option.systemImage
                        )
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)).raisedShadow())
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.55), lineWidth: 1)
                    )
            }
            .tint(Color.primary)
        }
        .padding(.horizontal, 20)
    }
    
    private func invoiceRow(for invoice: Invoice) -> some View {
        let isSelected = viewModel.selectedIDs.contains(invoice.id)

        return Button {
            if viewModel.isEditing {
                viewModel.toggleSelection(invoice.id)
            } else {
                Haptics.light()
                navigationPath.append(invoice)
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Color.blue : Color.secondary.opacity(0.4))
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                InvoiceRowItem(invoice: invoice)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2.5)
                            .animation(AppAnimation.fast, value: isSelected)
                    )
            }
        }
        .buttonStyle(PressableStyle())
        .contextMenu {
            contextMenuButtons(for: invoice)
        }
    }
    
    @ViewBuilder
    private func contextMenuButtons(for invoice: Invoice) -> some View {
        Button {
            viewModel.previewPDF(for: invoice)
        } label: {
            Label(L.t(.viewPDF), systemImage: "doc.text.magnifyingglass")
        }
        .disabled(invoice.pdfFileName == nil)
        
        Button {
            viewModel.sharePDF(for: invoice)
        } label: {
            Label(L.t(.share), systemImage: "square.and.arrow.up")
        }
        .disabled(invoice.pdfFileName == nil)
        
        Button {
            viewModel.duplicate(invoice, context: modelContext)
        } label: {
            Label(L.t(.duplicate), systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.invoiceToDelete = invoice
        } label: {
            Label(L.t(.delete), systemImage: "trash")
        }
    }
    
    private var batchActionBar: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                Haptics.medium()
                viewModel.showBatchDeleteAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("\(L.t(.delete)) (\(viewModel.selectedIDs.count))")
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(.red)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            Button {
                viewModel.shareSelected(from: allInvoices)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("\(L.t(.share)) (\(viewModel.selectedIDs.count))")
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(Color(.systemBackground))
                .background(RoundedRectangle(cornerRadius: 12).fill(.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text(L.t(.noInvoices))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            
            Text(L.t(.noInvoicesHint))
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text(L.t(.noMatches))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MyInvoicesView(currentScreen: .constant(.menu), deepLinkInvoice: .constant(nil))
        .modelContainer(for: [Invoice.self, ItemRow.self], inMemory: true)
}
