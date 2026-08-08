//
//  MyInvoicesViewModel.swift
//  Everything the invoice list does to itself: search across both parties and
//  item names, the four sort orders, multi-select mode with batch delete, and
//  the per-invoice preview, share, duplicate, and delete actions. Sharing
//  collects every selected invoice that actually has a PDF on disk and hands
//  the whole set to one share sheet. Deleting an invoice deletes its PDF from
//  disk first, since nothing else would ever go looking for that orphaned file.
//  A duplicate copies the colour breakdown and the contact link as well as the
//  numbers, because a copy that quietly redistributes the packs is worse than
//  no copy at all. Every write goes through one save that reports what went
//  wrong rather than dropping it, the way the stock and contact screens do.
//  Holds no invoices of its own: the view owns the @Query and hands the array
//  in.
//  Used by: MyInvoicesView.
//

import SwiftUI
import os
import SwiftData
import Combine

@MainActor
final class MyInvoicesViewModel: ObservableObject {
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case lowest = "Lowest Price"
        case highest = "Highest Price"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .newest:  return L.t(.newest)
            case .oldest:  return L.t(.oldest)
            case .lowest:  return L.t(.lowestPrice)
            case .highest: return L.t(.highestPrice)
            }
        }

        var systemImage: String {
            switch self {
            case .newest:  return "arrow.down"
            case .oldest:  return "arrow.up"
            case .lowest:  return "arrow.down.right"
            case .highest: return "arrow.up.right"
            }
        }
    }
    
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all, drafts, shipped

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:     return L.t(.allInvoices)
            case .drafts:  return L.t(.draftsOnly)
            case .shipped: return L.t(.shippedOnly)
            }
        }

        var systemImage: String {
            switch self {
            case .all:     return "tray.full"
            case .drafts:  return "pencil.line"
            case .shipped: return "shippingbox"
            }
        }

        func matches(_ invoice: Invoice) -> Bool {
            switch self {
            case .all:     return true
            case .drafts:  return invoice.status == .draft
            case .shipped: return invoice.status == .shipped
            }
        }
    }

    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .newest
    @Published var statusFilter: StatusFilter = .all
    @Published var isEditing: Bool = false
    @Published var selectedIDs: Set<UUID> = []
    @Published var invoiceToDelete: Invoice? = nil
    @Published var showBatchDeleteAlert: Bool = false
    @Published var previewURL: URL? = nil
    @Published var previewTitle: String = ""
    @Published var shareURLs: [URL] = []
    @Published var saveError: String? = nil
    
    func filteredAndSorted(_ invoices: [Invoice]) -> [Invoice] {
        var result = invoices.filter { statusFilter.matches($0) }
        
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { invoice in
                let receiver = invoice.receiver.lowercased()
                let sender = invoice.sender.lowercased()
                let itemMatch = invoice.allItems.contains { $0.name.lowercased().contains(query) }
                return receiver.contains(query) || sender.contains(query) || itemMatch
            }
        }
        
        switch sortOption {
        case .newest:
            result.sort { $0.date > $1.date }
        case .oldest:
            result.sort { $0.date < $1.date }
        case .lowest:
            result.sort { $0.totalInvoicePrice < $1.totalInvoicePrice }
        case .highest:
            result.sort { $0.totalInvoicePrice > $1.totalInvoicePrice }
        }
        
        return result
    }
    
    var selectionTitle: String {
        selectedIDs.isEmpty ? L.t(.selectInvoices) : "\(selectedIDs.count) \(L.t(.selected))"
    }
    
    func toggleEditing() {
        Haptics.light()
        withAnimation(AppAnimation.smooth) {
            isEditing.toggle()
            if !isEditing { selectedIDs.removeAll() }
        }
    }
    
    func toggleSelection(_ id: UUID) {
        Haptics.light()
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    func exitEditingIfEmpty(invoiceCount: Int) {
        if invoiceCount == 0 && isEditing {
            isEditing = false
            selectedIDs.removeAll()
        }
    }
    
    func previewPDF(for invoice: Invoice) {
        Haptics.light()
        guard let fileName = invoice.pdfFileName,
              let url = PDFStorage.pdfURL(fileName: fileName) else { return }
        previewTitle = invoice.receiver.isEmpty ? L.t(.invoice) : invoice.receiver
        previewURL = url
    }
    
    func sharePDF(for invoice: Invoice) {
        Haptics.light()
        guard let url = pdfURL(for: invoice) else { return }
        shareURLs = [url]
    }

    func shareSelected(from invoices: [Invoice]) {
        Haptics.medium()
        let urls = invoices
            .filter { selectedIDs.contains($0.id) }
            .compactMap(pdfURL(for:))
        guard !urls.isEmpty else { return }
        shareURLs = urls
    }

    private func pdfURL(for invoice: Invoice) -> URL? {
        guard let fileName = invoice.pdfFileName else { return nil }
        return PDFStorage.pdfURL(fileName: fileName)
    }
    
    func duplicate(_ invoice: Invoice, context: ModelContext) {
        Haptics.light()
        let copiedItems = invoice.orderedItems.map { item -> ItemRow in
            let copy = ItemRow(
                name: item.name,
                unitCount: item.unitCount,
                itemsPerUnit: item.itemsPerUnit,
                price: item.price,
                colors: item.colors
            )
            copy.colorPacks = item.colorPacks
            return copy
        }
        let copy = Invoice(items: copiedItems, date: .now, sender: invoice.sender, receiver: invoice.receiver)
        copy.receiverContact = invoice.receiverContact
        copy.number = InvoiceNumbering.next(in: context)
        copy.currencyCode = invoice.currencyCode ?? AppSettings.currency.rawValue
        context.insert(copy)
        save(context)
    }

    func delete(_ invoice: Invoice, context: ModelContext) {
        Haptics.warning()
        if let fileName = invoice.pdfFileName {
            PDFStorage.deletePDF(fileName: fileName)
        }
        withAnimation(AppAnimation.quick) {
            context.delete(invoice)
            save(context)
        }
        invoiceToDelete = nil
    }

    func deleteSelected(from invoices: [Invoice], context: ModelContext) {
        Haptics.warning()
        let toDelete = invoices.filter { selectedIDs.contains($0.id) }
        withAnimation(AppAnimation.quick) {
            for invoice in toDelete {
                if let fileName = invoice.pdfFileName {
                    PDFStorage.deletePDF(fileName: fileName)
                }
                context.delete(invoice)
            }
            save(context)
            selectedIDs.removeAll()
        }
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            Haptics.error()
            AppLog.data.error("Invoice list save failed: \(error.localizedDescription, privacy: .public)")
            saveError = error.localizedDescription
        }
    }
}
