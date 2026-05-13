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
    var Items : [ItemRow]
    var id : UUID = UUID()
    var date : Date = Date.now
    var sender : String
    var receiver : String
    
    init(Items : [ItemRow], date : Date, sender : String, receiver : String){
        self.Items = Items
        self.date = date
        self.sender = sender
        self.receiver = receiver
    }
    
    var TotalInvoicePrice : Double {
        return calculateTotal()
    }
    
    func calculateTotal() -> Double {
        var x = 0.00
        for item in Items {
            x += item.totalForItems
        }
        return x
    }
}
