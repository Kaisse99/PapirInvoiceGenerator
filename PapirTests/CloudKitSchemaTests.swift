//
//  CloudKitSchemaTests.swift
//  The rules CloudKit mirroring imposes on the schema, asserted against the
//  schema itself rather than discovered on her phone. A private-database
//  container refuses to open at all if a relationship has no inverse, if a
//  stored property is neither optional nor defaulted, or if anything carries a
//  unique constraint, and the failure arrives at launch as a store that will
//  not open. These held once and were then broken by three relationships that
//  read fine locally, so they are written down here instead: adding a model or
//  a property without an inverse now fails in the suite rather than in her
//  hands the first time she turns iCloud on.
//

import Foundation
import SwiftData
import Testing
@testable import Papir

struct CloudKitSchemaTests {
    private var schema: Schema {
        Schema(versionedSchema: PapirSchemaV1.self)
    }

    @Test func everyRelationshipHasAnInverse() {
        var missing: [String] = []
        for entity in schema.entities {
            for relationship in entity.relationships where relationship.inverseName == nil {
                missing.append("\(entity.name).\(relationship.name)")
            }
        }
        #expect(missing.isEmpty, "CloudKit needs an inverse on: \(missing.joined(separator: ", "))")
    }

    @Test func everyStoredPropertyIsOptionalOrDefaulted() {
        var bare: [String] = []
        for entity in schema.entities {
            for attribute in entity.attributes where !attribute.isOptional && attribute.defaultValue == nil {
                bare.append("\(entity.name).\(attribute.name)")
            }
        }
        #expect(bare.isEmpty, "CloudKit needs optional or defaulted: \(bare.joined(separator: ", "))")
    }

    @Test func everyRelationshipIsOptional() {
        var required: [String] = []
        for entity in schema.entities {
            for relationship in entity.relationships where !relationship.isOptional {
                required.append("\(entity.name).\(relationship.name)")
            }
        }
        #expect(required.isEmpty, "CloudKit needs optional relationships: \(required.joined(separator: ", "))")
    }

    @Test func nothingCarriesAUniqueConstraint() {
        var unique: [String] = []
        for entity in schema.entities {
            for attribute in entity.attributes where attribute.isUnique {
                unique.append("\(entity.name).\(attribute.name)")
            }
        }
        #expect(unique.isEmpty, "CloudKit rejects unique constraints on: \(unique.joined(separator: ", "))")
    }

    @Test func everyModelInTheSchemaIsTheOneTheAppOpens() {
        let names = Set(schema.entities.map(\.name))
        #expect(names == [
            "ItemRow",
            "Invoice",
            "ShipmentLine",
            "StockLine",
            "StockModel",
            "StockMovement",
            "Contact"
        ])
    }
}
