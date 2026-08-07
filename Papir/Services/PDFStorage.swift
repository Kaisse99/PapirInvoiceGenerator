//
//  PDFStorage.swift
//  The PapirMyInvoices folder in Documents, where every generated PDF lives.
//  Invoices persist only the file name, so each lookup rebuilds the URL and
//  reports nil when the file is gone. Names are built from language, the
//  invoice's own date, the receiver, and a short slice of the invoice id. The
//  id is what keeps the name unique: without it two invoices to the same
//  receiver on the same day produce one file, and the second save overwrites
//  the first while the first still claims to own it. Regenerating one invoice
//  still lands on its own name and replaces only its own file.
//  Used by: NewInvoiceViewModel, InvoiceDetailViewModel, MyInvoicesViewModel,
//  MyInvoicesView.
//

import Foundation

enum PDFStorage {
    static let folderName = "PapirMyInvoices"
    
    static func papirFolderURL() throws -> URL {
        let fm = FileManager.default
        let documents = try fm.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = documents.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    static func savePDF(_ data: Data, for invoice: InvoiceSnapshot, language: PDFLanguage) throws -> String {
        let fileName = generateFileName(for: invoice, language: language)
        let folder = try papirFolderURL()
        let fileURL = folder.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }
    
    static func pdfURL(fileName: String) -> URL? {
        guard let folder = try? papirFolderURL() else { return nil }
        let url = folder.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    static func deletePDF(fileName: String) {
        guard let folder = try? papirFolderURL() else { return }
        let url = folder.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
    
    private static func generateFileName(for invoice: InvoiceSnapshot, language: PDFLanguage) -> String {
        let langPrefix: String
        switch language {
        case .english:   langPrefix = "EN"
        case .ukrainian: langPrefix = "UA"
        case .russian:   langPrefix = "RU"
        case .polish:    langPrefix = "PL"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "ddMMyyyy"
        let dateStr = dateFormatter.string(from: invoice.date)

        let receiverPart = sanitizeForFilename(invoice.receiver)
        let namePart = receiverPart.isEmpty ? "" : "-\(receiverPart)"
        let idPart = invoice.id.uuidString.prefix(4).lowercased()

        return "\(langPrefix)-Invoice-\(dateStr)\(namePart)-\(idPart).pdf"
    }
    
    private static func sanitizeForFilename(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = trimmed.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}
