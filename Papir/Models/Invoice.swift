//
//  Invoice.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import Foundation
import SwiftData

@Model
final class Invoice {
    @Relationship(deleteRule: .cascade)
    var items: [ItemRow]
    var id: UUID = UUID()
    var date: Date = Date.now
    var sender: String
    var receiver: String
    var pdfFileName: String? = nil
    
    init(items: [ItemRow], date: Date = .now, sender: String, receiver: String, pdfFileName: String? = nil) {
        self.items = items
        self.date = date
        self.sender = sender
        self.receiver = receiver
        self.pdfFileName = pdfFileName
    }
    
    var totalInvoicePrice: Double {
        items.reduce(0) { $0 + $1.totalForItem }
    }
}
