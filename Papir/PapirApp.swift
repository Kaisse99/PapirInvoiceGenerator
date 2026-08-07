//
//  PapirApp.swift
//  App entry point. Builds the on-disk SwiftData container through the
//  versioned schema and its migration plan and hands it to HomeView, the only
//  scene; everything else is reached by swiping from there.
//  iCloud sync is opt-in, so the container is built one of two ways at launch:
//  mirrored to the private CloudKit database when the setting is on, purely
//  local when it is off. That choice can only be made once per launch, which
//  is why turning the setting on asks for a restart rather than pretending to
//  switch live. A CloudKit container that fails to open, which is what happens
//  when nobody is signed into iCloud, falls back to the local store and leaves
//  a flag behind so settings can say so instead of failing silently. The
//  reason it refused is logged rather than dropped: "nobody is signed in" and
//  "the schema holds a relationship CloudKit will not mirror" look identical
//  from the settings screen, and only the log tells them apart.
//  A local store that also refuses to open used to be a fatalError, which
//  died on her without a word. Now it is a screen: the error, a retry, and a
//  start-empty behind a confirmation, because a frozen app with no way out is
//  the one behaviour worse than losing the morning's work.
//  Used by: the app target.
//

import SwiftUI
import os
import SwiftData

enum StoreState {
    case ready(ModelContainer)
    case failed(String)
}

enum StoreLoader {
    static func load() -> StoreState {
        let schema = Schema(versionedSchema: PapirSchemaV1.self)

        if AppSettings.cloudSyncEnabled {
            let cloud = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(AppSettings.cloudContainerID)
            )
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: PapirMigrationPlan.self,
                    configurations: [cloud]
                )
                AppSettings.recordCloudSyncFailure(false)
                return .ready(container)
            } catch {
                AppSettings.recordCloudSyncFailure(true)
                AppLog.store.error(
                    "CloudKit container failed to open, falling back to local: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: PapirMigrationPlan.self,
                configurations: [local]
            )
            return .ready(container)
        } catch {
            AppLog.store.critical("Local store failed to open: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
    }

    static func reset() {
        let fm = FileManager.default
        guard let support = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        for suffix in ["default.store", "default.store-shm", "default.store-wal"] {
            try? fm.removeItem(at: support.appendingPathComponent(suffix))
        }
        AppLog.store.warning("Store reset by the user after a failed open")
    }
}

@main
struct PapirApp: App {
    @State private var store = StoreLoader.load()

    var body: some Scene {
        WindowGroup {
            switch store {
            case .ready(let container):
                HomeView()
                    .modelContainer(container)
                    .task {
                        InvoiceNumbering.backfill(context: container.mainContext)
                    }
            case .failed(let message):
                StoreFailureView(
                    message: message,
                    onRetry: { store = StoreLoader.load() },
                    onReset: {
                        StoreLoader.reset()
                        store = StoreLoader.load()
                    }
                )
            }
        }
    }
}
