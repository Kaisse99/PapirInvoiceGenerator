//
//  TestSupport.swift
//  The one helper every model-touching test reaches for: an in-memory
//  SwiftData container holding the full schema, fresh per test so no test can
//  lean on another's leftovers. In memory because these tests are about
//  arithmetic and bookkeeping, not about disk.
//  Used by: ShipmentPlannerTests, StatisticsTests, InvoiceListTests.
//

import SwiftData
@testable import Papir

func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try ModelContainer(
        for: ItemRow.self,
        Invoice.self,
        ShipmentLine.self,
        StockLine.self,
        StockModel.self,
        StockMovement.self,
        Contact.self,
        configurations: configuration
    )
}
