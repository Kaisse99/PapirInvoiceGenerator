//
//  InvoiceDetailViewModel.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-22.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
final class InvoiceDetailViewModel: ObservableObject {
    @Published var showLanguagePicker = false
    @Published var isGeneratingPDF = false
    @Published var pdfPreviewURL: URL? = nil
    @Published var pdfPreviewTitle: String = ""
    @Published var generationError: String? = nil
    
    func viewExistingPDF(for invoice: Invoice) {
        guard let fileName = invoice.pdfFileName,
              let url = PDFStorage.pdfURL(fileName: fileName) else {
            generationError = "No PDF found for this invoice. Try Re-generate."
            return
        }
        pdfPreviewTitle = invoice.receiver.isEmpty ? "Invoice" : invoice.receiver
        pdfPreviewURL = url
    }
    
    func generatePDF(for invoice: Invoice, language: PDFLanguage, context: ModelContext) {
        isGeneratingPDF = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = PDFGenerator.generate(for: invoice, language: language)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                do {
                    if let old = invoice.pdfFileName {
                        PDFStorage.deletePDF(fileName: old)
                    }
                    let fileName = try PDFStorage.savePDF(pdfData, for: invoice, language: language)
                    invoice.pdfFileName = fileName
                    try context.save()
                    
                    if let url = PDFStorage.pdfURL(fileName: fileName) {
                        Haptics.success()
                        self.pdfPreviewTitle = invoice.receiver.isEmpty ? "Invoice" : invoice.receiver
                        self.pdfPreviewURL = url
                    }
                    self.isGeneratingPDF = false
                } catch {
                    self.generationError = error.localizedDescription
                    Haptics.error()
                    self.isGeneratingPDF = false
                }
            }
        }
    }
}
