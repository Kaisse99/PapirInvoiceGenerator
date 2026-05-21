//
//  NewInvoiceViewModel.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-19.
//

import SwiftUI
import SwiftData
import Combine

struct InvoiceRowDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var unitCount: String = ""
    var itemsPerUnit: String = ""
    var price: String = ""
    var colors: [String] = []
    var isLocked: Bool = false
    
    var nameError: Bool = false
    var unitsError: Bool = false
    var perUnitError: Bool = false
    var priceError: Bool = false
}

@MainActor
final class NewInvoiceViewModel: ObservableObject {
    @Published var showHeader = false
    @Published var sender: String = ""
    @Published var receiver: String = ""
    @Published var rows: [InvoiceRowDraft] = [InvoiceRowDraft()]
    @Published var isSaving = false
    @Published var saveErrorMessage: String? = nil
    
    let editingInvoice: Invoice?
    
    var isEditMode: Bool { editingInvoice != nil }
    
    init(editingInvoice: Invoice? = nil) {
        self.editingInvoice = editingInvoice
        
        if let invoice = editingInvoice {
            sender = invoice.sender
            receiver = invoice.receiver
            showHeader = !invoice.sender.isEmpty || !invoice.receiver.isEmpty
            
            let drafts = invoice.items.map { item in
                InvoiceRowDraft(
                    name: item.name,
                    unitCount: "\(item.unitCount)",
                    itemsPerUnit: "\(item.itemsPerUnit)",
                    price: Self.formatPriceForEditing(item.price),
                    colors: item.colors,
                    isLocked: true
                )
            }
            rows = drafts.isEmpty ? [InvoiceRowDraft()] : drafts
        }
    }
    
    private static func formatPriceForEditing(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return "\(value)"
    }
    
    var liveTotal: Double {
        rows.reduce(0) { partial, row in
            guard let units = Double(row.unitCount.trimmingCharacters(in: .whitespaces)),
                  let perUnit = Double(row.itemsPerUnit.trimmingCharacters(in: .whitespaces)),
                  let price = Double(row.price.trimmingCharacters(in: .whitespaces))
            else { return partial }
            return partial + units * perUnit * price
        }
    }
    
    func addRow() {
        Haptics.light()
        withAnimation(AppAnimation.quick) {
            rows.append(InvoiceRowDraft())
        }
    }
    
    func deleteRow(id: UUID) {
        withAnimation(AppAnimation.quick) {
            rows.removeAll { $0.id == id }
        }
    }
    
    func clearError(for id: UUID, field: InvoiceRowCard.Field?) {
        guard let idx = rows.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(AppAnimation.fast) {
            switch field {
            case .units: rows[idx].unitsError = false
            case .perUnit: rows[idx].perUnitError = false
            case .price: rows[idx].priceError = false
            case .none: break
            }
        }
    }
    
    func clearNameError(for id: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(AppAnimation.fast) {
            rows[idx].nameError = false
        }
    }
    
    private func validate() -> Bool {
        var hasErrors = false
        for i in rows.indices {
            let row = rows[i]
            let nameMissing = row.name.trimmingCharacters(in: .whitespaces).isEmpty
            let unitsMissing = row.unitCount.trimmingCharacters(in: .whitespaces).isEmpty
            let perUnitMissing = row.itemsPerUnit.trimmingCharacters(in: .whitespaces).isEmpty
            let priceMissing = row.price.trimmingCharacters(in: .whitespaces).isEmpty
            
            withAnimation(AppAnimation.fast) {
                rows[i].nameError = nameMissing
                rows[i].unitsError = unitsMissing
                rows[i].perUnitError = perUnitMissing
                rows[i].priceError = priceMissing
            }
            
            if nameMissing || unitsMissing || perUnitMissing || priceMissing {
                hasErrors = true
            }
        }
        return !hasErrors
    }
    
    private func buildItems() -> [ItemRow] {
        rows.map { draft in
            ItemRow(
                name: draft.name,
                unitCount: UInt16(Double(draft.unitCount) ?? 0),
                itemsPerUnit: UInt16(Double(draft.itemsPerUnit) ?? 0),
                price: Double(draft.price) ?? 0,
                colors: draft.colors
            )
        }
    }
    
    func saveAndGeneratePDF(context: ModelContext, completion: @escaping (Invoice?) -> Void) {
        guard validate() else {
            Haptics.warning()
            completion(nil)
            return
        }
        
        isSaving = true
        saveErrorMessage = nil
        
        let items = buildItems()
        
        let result: Invoice
        do {
            if let existing = editingInvoice {
                existing.items = items
                existing.sender = sender
                existing.receiver = receiver
                if let oldFileName = existing.pdfFileName {
                    PDFStorage.deletePDF(fileName: oldFileName)
                    existing.pdfFileName = nil
                }
                try context.save()
                result = existing
            } else {
                let invoice = Invoice(items: items, date: .now, sender: sender, receiver: receiver)
                context.insert(invoice)
                try context.save()
                result = invoice
            }
        } catch {
            Haptics.error()
            isSaving = false
            saveErrorMessage = error.localizedDescription
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = PDFGenerator.generate(for: result, language: .ukrainian)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                do {
                    let fileName = try PDFStorage.savePDF(pdfData, for: result, language: .ukrainian)
                    result.pdfFileName = fileName
                    try context.save()
                    Haptics.success()
                } catch {
                    Haptics.error()
                }
                self.isSaving = false
                completion(result)
            }
        }
    }
}
