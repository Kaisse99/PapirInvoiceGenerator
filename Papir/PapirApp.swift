//
//  PapirApp.swift
//  App entry point. Builds the one on-disk SwiftData container for invoices
//  and stock and hands it to HomeView, which is the only scene; everything
//  else is reached by swiping from there.
//  iCloud sync is opt-in, so the container is built one of two ways at launch:
//  mirrored to the private CloudKit database when the setting is on, purely
//  local when it is off. That choice can only be made once per launch, which
//  is why turning the setting on asks for a restart rather than pretending to
//  switch live. A CloudKit container that fails to open, which is what happens
//  when nobody is signed into iCloud, falls back to the local store and leaves
//  a flag behind so settings can say so instead of failing silently. Only a
//  local store that also refuses to open is fatal, because at that point there
//  is nothing for the app to work with.
//  Used by: the app target.
//

import SwiftUI
import SwiftData

@main
struct PapirApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ItemRow.self,
            Invoice.self,
            ShipmentLine.self,
            StockLine.self,
            StockModel.self,
            StockMovement.self
        ])

        if AppSettings.cloudSyncEnabled {
            let cloud = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(AppSettings.cloudContainerID)
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
                AppSettings.recordCloudSyncFailure(false)
                return container
            }
            AppSettings.recordCloudSyncFailure(true)
        }

        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
