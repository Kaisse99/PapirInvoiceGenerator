//
//  StockMovement.swift
//  One recorded change to a stock count, so a number can always explain how it
//  got there. Every path that moves stock writes one of these: taking packs in,
//  taking them out by hand, an invoice being shipped or pulled back, and a
//  recount, which records the difference rather than the new figure so the log
//  reads as a run of changes rather than a list of snapshots.
//  packs is signed, positive into the shelf and negative off it. The invoice's
//  receiver is copied in rather than referenced, because the log should still
//  read correctly after that invoice is deleted.
//  kindRaw is stored as a plain string for the same reason every other enum
//  here is: SwiftData will not backfill a default onto rows that predate it.
//  Used by: StockViewModel, ShipmentPlanner, MovementLogView.
//

import Foundation
import SwiftData

@Model
final class StockMovement {
    var date: Date = Date.now
    var modelCode: String = ""
    var color: String = ""
    var packs: Int = 0
    var kindRaw: String? = nil
    var context: String? = nil

    init(date: Date = .now, modelCode: String, color: String, packs: Int, kind: StockMovementKind, context: String? = nil) {
        self.date = date
        self.modelCode = modelCode
        self.color = color
        self.packs = packs
        self.kindRaw = kind.rawValue
        self.context = context
    }

    var kind: StockMovementKind {
        StockMovementKind(rawValue: kindRaw ?? "") ?? .received
    }
}

enum StockMovementKind: String, CaseIterable {
    case received
    case removed
    case shipped
    case returned
    case recounted
}
