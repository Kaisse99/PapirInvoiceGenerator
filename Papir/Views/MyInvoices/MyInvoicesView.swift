//
//  MyInvoicesView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI
import SwiftData

struct MyInvoicesView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = MyInvoicesViewModel()
    @Binding var currentScreen: HomeViewModel.Screen
    @Binding var deepLinkInvoice: Invoice?
    
    @State private var navigationPath = NavigationPath()
    
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
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(invoices) { invoice in
                                    invoiceRow(for: invoice)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, viewModel.isEditing ? 100 : 40)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .dismissKeyboardOnTap()
            .background(backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                if viewModel.isEditing && !viewModel.selectedIDs.isEmpty {
                    batchActionBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert(
                "Delete this invoice?",
                isPresented: Binding(
                    get: { viewModel.invoiceToDelete != nil },
                    set: { if !$0 { viewModel.invoiceToDelete = nil } }
                ),
                presenting: viewModel.invoiceToDelete
            ) { invoice in
                Button("Delete", role: .destructive) {
                    viewModel.delete(invoice, context: modelContext)
                }
                Button("Cancel", role: .cancel) {
                    viewModel.invoiceToDelete = nil
                }
            } message: { _ in
                Text("This action cannot be undone.")
            }
            .alert(
                "Delete \(viewModel.selectedIDs.count) invoice\(viewModel.selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $viewModel.showBatchDeleteAlert
            ) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteSelected(from: allInvoices, context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .onChange(of: allInvoices.count) { _, newCount in
                viewModel.exitEditingIfEmpty(invoiceCount: newCount)
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
                    get: { viewModel.shareInvoiceURL != nil },
                    set: { if !$0 { viewModel.shareInvoiceURL = nil } }
                )
            ) {
                if let url = viewModel.shareInvoiceURL {
                    ShareSheet(items: [url])
                }
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
        }
    }
    
    private var backgroundGradient: some View {
        RadialGradient(
            colors: [
                Color(.systemBackground),
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.gray.opacity(0.25)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 500
        )
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
                    Image(systemName: "house.fill")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text(viewModel.isEditing ? viewModel.selectionTitle : "Invoices")
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            if !allInvoices.isEmpty {
                Button {
                    viewModel.toggleEditing()
                } label: {
                    Text(viewModel.isEditing ? "Done" : "Select")
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    private var searchAndSortBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                TextField("Search invoices...", text: $viewModel.searchText)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.primary.opacity(0.40), lineWidth: 1)
            )
            
            Menu {
                ForEach(MyInvoicesViewModel.SortOption.allCases) { option in
                    Button {
                        Haptics.light()
                        withAnimation(AppAnimation.fast) {
                            viewModel.sortOption = option
                        }
                    } label: {
                        Label(
                            option.rawValue,
                            systemImage: viewModel.sortOption == option ? "checkmark" : option.systemImage
                        )
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.primary.opacity(0.55), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func invoiceRow(for invoice: Invoice) -> some View {
        if viewModel.isEditing {
            Button {
                viewModel.toggleSelection(invoice.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.selectedIDs.contains(invoice.id)
                          ? "checkmark.circle.fill"
                          : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(viewModel.selectedIDs.contains(invoice.id)
                                         ? Color.blue
                                         : Color.secondary.opacity(0.4))
                    
                    InvoiceRowItem(invoice: invoice)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(viewModel.selectedIDs.contains(invoice.id)
                                        ? Color.blue
                                        : Color.clear,
                                        lineWidth: 2.5)
                        )
                }
                .animation(AppAnimation.quick, value: viewModel.isEditing)
                .animation(AppAnimation.fast, value: viewModel.selectedIDs.contains(invoice.id))
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: invoice) {
                InvoiceRowItem(invoice: invoice)
            }
            .buttonStyle(PressableStyle())
            .contextMenu {
                contextMenuButtons(for: invoice)
            }
        }
    }
    
    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20))
            .foregroundStyle(isSelected ? Color.blue : Color.secondary.opacity(0.5))
            .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
    }
    
    @ViewBuilder
    private func contextMenuButtons(for invoice: Invoice) -> some View {
        Button {
            viewModel.previewPDF(for: invoice)
        } label: {
            Label("View PDF", systemImage: "doc.text.magnifyingglass")
        }
        .disabled(invoice.pdfFileName == nil)
        
        Button {
            viewModel.sharePDF(for: invoice)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .disabled(invoice.pdfFileName == nil)
        
        Button {
            viewModel.duplicate(invoice, context: modelContext)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.invoiceToDelete = invoice
        } label: {
            Label("Delete", systemImage: "trash")
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
                    Text("Delete (\(viewModel.selectedIDs.count))")
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(.red)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            Button {
                Haptics.medium()
                shareSelected()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share (\(viewModel.selectedIDs.count))")
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
    
    private func shareSelected() {
        let selected = allInvoices.filter { viewModel.selectedIDs.contains($0.id) }
        let urls = selected.compactMap { invoice -> URL? in
            guard let fileName = invoice.pdfFileName else { return nil }
            return PDFStorage.pdfURL(fileName: fileName)
        }
        guard !urls.isEmpty else { return }
        viewModel.shareInvoiceURL = urls.first
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No invoices yet")
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            
            Text("Swipe down on home to create your first one")
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
            
            Text("No matches")
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

#Preview {
    MyInvoicesView(currentScreen: .constant(.menu), deepLinkInvoice: .constant(nil))
        .modelContainer(for: [Invoice.self, ItemRow.self], inMemory: true)
}
