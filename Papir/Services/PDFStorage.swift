//
//  PDFStorage.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-19.
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
    
    static func savePDF(_ data: Data, for invoice: Invoice, language: PDFLanguage) throws -> String {
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
    
    private static func generateFileName(for invoice: Invoice, language: PDFLanguage) -> String {
        let langPrefix: String
        switch language {
        case .english:   langPrefix = "EN"
        case .ukrainian: langPrefix = "UA"
        case .russian:   langPrefix = "RU"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy"
        let dateStr = dateFormatter.string(from: Date())
        
        let cleanedReceiver = sanitizeForFilename(invoice.receiver)
        let receiverPart = cleanedReceiver.isEmpty ? randomFourDigits() : cleanedReceiver
        
        return "\(langPrefix)-Invoice-\(dateStr)-\(receiverPart).pdf"
    }
    
    private static func sanitizeForFilename(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = trimmed.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    private static func randomFourDigits() -> String {
        "\(Int.random(in: 1000...9999))"
    }
}
