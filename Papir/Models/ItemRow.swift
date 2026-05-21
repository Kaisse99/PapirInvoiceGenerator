//
//  ItemRow.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import Foundation
import SwiftData

@Model
final class ItemRow {
    var name: String
    var unitCount: UInt16
    var itemsPerUnit: UInt16
    var price: Double
    var colors: [String]
    
    init(name: String, unitCount: UInt16, itemsPerUnit: UInt16, price: Double, colors: [String]) {
        self.name = name
        self.unitCount = unitCount
        self.itemsPerUnit = itemsPerUnit
        self.price = price
        self.colors = colors
    }
    
    var totalForItem: Double {
        Double(unitCount) * Double(itemsPerUnit) * price
    }
}
