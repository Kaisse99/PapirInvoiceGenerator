//
//  PapirSchema.swift
//  The versioned schema and its migration plan. Version one simply names the
//  models as they stand; its value is the discipline it imposes on everything
//  after it. SwiftData does not backfill defaults onto rows that already
//  exist, and a rename or a retype without a migration stage silently nulls a
//  column, which for an app holding a year of invoices is the failure that
//  ends the business rather than the app. From here, any change to a stored
//  property gets a new PapirSchemaV and an explicit stage in the plan, so the
//  store is carried forward on purpose instead of by luck.
//  The model classes stay top-level rather than nested in the version enum,
//  because only one version exists; the day V2 appears, V1 gets frozen copies.
//  Used by: PapirApp.
//

import Foundation
import SwiftData

enum PapirSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            ItemRow.self,
            Invoice.self,
            ShipmentLine.self,
            StockLine.self,
            StockModel.self,
            StockMovement.self,
            Contact.self
        ]
    }
}

enum PapirMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PapirSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
