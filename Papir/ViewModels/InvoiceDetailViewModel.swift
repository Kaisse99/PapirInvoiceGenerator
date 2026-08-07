//
//  InvoiceDetailViewModel.swift
//  Opening and re-making the PDF for one invoice. Rendering takes a snapshot of
//  the invoice, draws it off the main thread, then returns here to write the
//  file, point the preview at the result, and only then drop the previous one:
//  deleting first meant a failed write left the invoice naming a file that was
//  already gone. An invoice whose file is missing reports it instead of showing
//  an empty viewer.
//  Used by: InvoiceDetailView.
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
        let snapshot = invoice.snapshot
        let currencySymbol = AppSettings.currencySymbol

        Task {
            let pdfData = await PDFGenerator.render(snapshot, language: language, currencySymbol: currencySymbol)
            do {
                let previous = invoice.pdfFileName
                let fileName = try PDFStorage.savePDF(pdfData, for: snapshot, language: language)
                invoice.pdfFileName = fileName
                try context.save()

                if let previous, previous != fileName {
                    PDFStorage.deletePDF(fileName: previous)
                }

                if let url = PDFStorage.pdfURL(fileName: fileName) {
                    Haptics.success()
                    pdfPreviewTitle = invoice.receiver.isEmpty ? "Invoice" : invoice.receiver
                    pdfPreviewURL = url
                }
            } catch {
                generationError = error.localizedDescription
                Haptics.error()
            }
            isGeneratingPDF = false
        }
    }
}
