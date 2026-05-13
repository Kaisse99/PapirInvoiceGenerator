//
//  Invoice.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import Foundation
import SwiftData

@Model
class Invoice {
    @Relationship(deleteRule: .cascade)
    var items : [ItemRow]
    var id : UUID = UUID()
    var date : Date = Date.now
    var sender : String
    var receiver : String
    
    init(items : [ItemRow], date : Date, sender : String, receiver : String){
        self.items = items
        self.date = date
        self.sender = sender
        self.receiver = receiver
    }
    
    var totalInvoicePrice : Double {
        return calculateTotal()
    }
    
    func calculateTotal() -> Double {
        var x = 0.00
        for item in items {
            x += item.totalForItem
        }
        return x
    }
}
