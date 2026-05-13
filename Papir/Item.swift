//
//  Item.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
