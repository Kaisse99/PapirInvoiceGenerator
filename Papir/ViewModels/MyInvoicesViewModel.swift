//
//  MyInvoicesViewModel.swift
//  Everything the invoice list does to itself: search across both parties and
//  item names, the four sort orders, multi-select mode with batch delete, and
//  the per-invoice preview, share, duplicate, and delete actions. Sharing
//  collects every selected invoice that actually has a PDF on disk and hands
//  the whole set to one share sheet. Deleting an invoice deletes its PDF from
//  disk first, since nothing else would ever go looking for that orphaned file.
//  Holds no invoices of its own: the view owns the @Query and hands the array
//  in.
//  Used by: MyInvoicesView.
//

import SwiftUI
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
    
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .newest
    @Published var isEditing: Bool = false
    @Published var selectedIDs: Set<UUID> = []
    @Published var invoiceToDelete: Invoice? = nil
    @Published var showBatchDeleteAlert: Bool = false
    @Published var previewURL: URL? = nil
    @Published var previewTitle: String = ""
    @Published var shareURLs: [URL] = []
    
    func filteredAndSorted(_ invoices: [Invoice]) -> [Invoice] {
        var result = invoices
        
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
        withAnimation(AppAnimation.snappy) {
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
        previewTitle = invoice.receiver.isEmpty ? "Invoice" : invoice.receiver
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
        let copiedItems = invoice.orderedItems.map { item in
            ItemRow(
                name: item.name,
                unitCount: item.unitCount,
                itemsPerUnit: item.itemsPerUnit,
                price: item.price,
                colors: item.colors
            )
        }
        let copy = Invoice(items: copiedItems, date: .now, sender: invoice.sender, receiver: invoice.receiver)
        context.insert(copy)
        try? context.save()
    }
    
    func delete(_ invoice: Invoice, context: ModelContext) {
        Haptics.warning()
        if let fileName = invoice.pdfFileName {
            PDFStorage.deletePDF(fileName: fileName)
        }
        withAnimation(AppAnimation.quick) {
            context.delete(invoice)
            try? context.save()
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
            try? context.save()
            selectedIDs.removeAll()
        }
    }
}
