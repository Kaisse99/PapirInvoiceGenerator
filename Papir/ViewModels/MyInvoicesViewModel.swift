//
//  MyInvoicesViewModel.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-19.
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
    @Published var shareInvoiceURL: URL? = nil
    
    func filteredAndSorted(_ invoices: [Invoice]) -> [Invoice] {
        var result = invoices
        
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { invoice in
                let receiver = invoice.receiver.lowercased()
                let sender = invoice.sender.lowercased()
                let itemMatch = invoice.items.contains { $0.name.lowercased().contains(query) }
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
        selectedIDs.isEmpty ? "Select" : "\(selectedIDs.count) selected"
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
        guard let fileName = invoice.pdfFileName,
              let url = PDFStorage.pdfURL(fileName: fileName) else { return }
        shareInvoiceURL = url
    }
    
    func duplicate(_ invoice: Invoice, context: ModelContext) {
        Haptics.light()
        let copiedItems = invoice.items.map { item in
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
