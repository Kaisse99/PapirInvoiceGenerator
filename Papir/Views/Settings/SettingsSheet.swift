//
//  SettingsSheet.swift
//  Preferences, reached from the gear on the home screen: the language the app
//  speaks, the currency every amount is written in, the name that goes in the
//  sender field, the two numbers a new invoice row is prefilled with, the count
//  a colour is called low at, the export and backup buttons, the iCloud toggle,
//  and clearing the movement log. Zero in either prefill number means start
//  that field empty. Preferences write straight to UserDefaults through
//  @AppStorage, so a change is live the moment it is tapped; the iCloud toggle
//  is the exception and asks for a restart, because the store is built one way
//  or the other once per launch.
//  Set in the rounded face rather than the monospaced one the rest of the app
//  uses: monospace earns its place where columns of numbers have to line up,
//  and a settings list is prose with a control beside it.
//  Used by: HomeView.
//

import SwiftUI
import os
import SwiftData
import UniformTypeIdentifiers

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppSettings.languageKey)
    private var languageRaw: String = AppLanguage.english.rawValue

    @AppStorage(AppSettings.currencyKey)
    private var currencyRaw: String = AppCurrency.hryvnia.rawValue

    @AppStorage(AppSettings.unitsKey)
    private var defaultUnits: Int = AppSettings.fallbackUnits

    @AppStorage(AppSettings.itemsPerUnitKey)
    private var defaultItemsPerUnit: Int = AppSettings.fallbackItemsPerUnit

    @AppStorage(AppSettings.lowStockKey)
    private var lowStockThreshold: Int = AppSettings.fallbackLowStock

    @AppStorage(AppSettings.defaultSenderKey)
    private var defaultSender: String = ""

    @AppStorage(AppSettings.cloudSyncKey)
    private var cloudSyncEnabled: Bool = false

    @State private var showRestartNotice = false
    @State private var showClearHistoryAlert = false
    @State private var clearHistoryError: String? = nil
    @State private var exportURLs: [URL] = []
    @State private var exportError: String? = nil
    @State private var showRestoreImporter = false
    @State private var pendingRestore: Data? = nil
    @State private var restoreResult: String? = nil

#if DEBUG
    @State private var showDebugWipeAlert = false
    @State private var debugResult: String? = nil
#endif

    @Query private var allInvoices: [Invoice]
    @Query private var allStock: [StockModel]
    @Query private var allContacts: [Contact]
    @Query private var allMovements: [StockMovement]

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .english
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    languageSection
                    currencySection
                    senderSection
                    defaultsSection
                    stockSection
                    exportSection
                    syncSection
                    historySection
#if DEBUG
                    debugSection
#endif
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .dismissKeyboardOnTap()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L.t(.settings, language))
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Text(L.t(.done, language))
                            .font(.scaled(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .alert(
                L.t(.clearHistory, language),
                isPresented: $showClearHistoryAlert
            ) {
                Button(L.t(.delete, language), role: .destructive) { clearHistory() }
                Button(L.t(.cancel, language), role: .cancel) {}
            } message: {
                Text(L.t(.clearHistoryWarning, language))
            }
            .sheet(
                isPresented: Binding(
                    get: { !exportURLs.isEmpty },
                    set: { if !$0 { exportURLs = [] } }
                )
            ) {
                ShareSheet(items: exportURLs)
            }
            .fileImporter(
                isPresented: $showRestoreImporter,
                allowedContentTypes: [.json]
            ) { result in
                receiveRestoreFile(result)
            }
            .alert(
                L.t(.restoreConfirmTitle, language),
                isPresented: Binding(
                    get: { pendingRestore != nil },
                    set: { if !$0 { pendingRestore = nil } }
                )
            ) {
                Button(L.t(.restore, language), role: .destructive) {
                    if let pendingRestore {
                        performRestore(pendingRestore)
                    }
                }
                Button(L.t(.cancel, language), role: .cancel) { pendingRestore = nil }
            } message: {
                Text(L.t(.cannotBeUndone, language))
            }
            .alert(
                L.t(.restored, language),
                isPresented: Binding(
                    get: { restoreResult != nil },
                    set: { if !$0 { restoreResult = nil } }
                )
            ) {
                Button(L.t(.ok, language), role: .cancel) { restoreResult = nil }
            } message: {
                Text(restoreResult ?? "")
            }
        }
    }

    private var languageSection: some View {
        section(title: L.t(.language, language)) {
            VStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { option in
                    optionRow(
                        leading: option.flag,
                        title: option.displayName,
                        isSelected: option == language
                    ) {
                        Haptics.light()
                        withAnimation(AppAnimation.fast) {
                            languageRaw = option.rawValue
                        }
                    }
                }
            }
        }
    }

    private var currencySection: some View {
        section(title: L.t(.currency, language)) {
            VStack(spacing: 8) {
                ForEach(AppCurrency.allCases) { option in
                    optionRow(
                        leading: option.symbol,
                        title: option.code,
                        isSelected: option.rawValue == currencyRaw
                    ) {
                        Haptics.light()
                        withAnimation(AppAnimation.fast) {
                            currencyRaw = option.rawValue
                        }
                    }
                }
            }
        }
    }

    private var senderSection: some View {
        section(title: L.t(.sender, language)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TextField(L.t(.defaultSenderPlaceholder, language), text: $defaultSender)
                        .font(.scaled(size: 17, weight: .medium, design: .rounded))
                        .autocorrectionDisabled()
                        .limitInput($defaultSender, to: 40)

                    if !defaultSender.isEmpty {
                        Button {
                            defaultSender = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))

                Text(L.t(.defaultSenderCaption, language))
                    .font(.scaled(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
        }
    }

    private var defaultsSection: some View {
        section(title: L.t(.newRowDefaults, language)) {
            VStack(spacing: 10) {
                numberRow(
                    label: L.t(.units, language),
                    caption: L.t(.unitsSettingCaption, language),
                    value: $defaultUnits
                )
                numberRow(
                    label: L.t(.perUnit, language),
                    caption: L.t(.perUnitSettingCaption, language),
                    value: $defaultItemsPerUnit
                )

                Text(L.t(.zeroLeavesEmpty, language))
                    .font(.scaled(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
            }
        }
    }

    private var exportSection: some View {
        section(title: L.t(.dataCaps, language)) {
            VStack(spacing: 8) {
                Button {
                    Haptics.medium()
                    exportEverything()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.scaled(size: 15, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L.t(.exportEverything, language))
                                .font(.scaled(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(L.t(.exportCaption, language))
                                .font(.scaled(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .frame(minHeight: 72)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                dataRow(
                    icon: "arrow.down.document",
                    title: L.t(.backup, language),
                    caption: L.t(.backupCaption, language),
                    tint: .primary
                ) {
                    Haptics.medium()
                    backupEverything()
                }

                dataRow(
                    icon: "arrow.counterclockwise",
                    title: L.t(.restore, language),
                    caption: L.t(.restoreCaption, language),
                    tint: .red
                ) {
                    Haptics.warning()
                    showRestoreImporter = true
                }

                if let exportError {
                    noticeLine(exportError, tint: .red)
                }
            }
        }
    }

    private func dataRow(
        icon: String,
        title: String,
        caption: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.scaled(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.scaled(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(tint)
                    Text(caption)
                        .font(.scaled(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 72)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private func backupEverything() {
        do {
            exportURLs = [try Backup.write(context: modelContext)]
            exportError = nil
            Haptics.success()
        } catch {
            Haptics.error()
            AppLog.export.error("Backup failed: \(error.localizedDescription, privacy: .public)")
            exportError = "\(L.t(.couldNotSave, language)): \(error.localizedDescription)"
        }
    }

    private func receiveRestoreFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped { url.stopAccessingSecurityScopedResource() }
            }
            pendingRestore = try Data(contentsOf: url)
            exportError = nil
        } catch {
            Haptics.error()
            AppLog.export.error("Restore file read failed: \(error.localizedDescription, privacy: .public)")
            exportError = "\(L.t(.couldNotSave, language)): \(error.localizedDescription)"
        }
    }

    private func performRestore(_ data: Data) {
        do {
            let counts = try Backup.restore(data, context: modelContext)
            restoreResult = "\(L.t(.invoices, language)): \(counts.invoices) · \(L.t(.stockTitle, language)): \(counts.models) · \(L.t(.addressBook, language)): \(counts.contacts)"
            Haptics.success()
        } catch {
            Haptics.error()
            AppLog.export.error("Restore failed: \(error.localizedDescription, privacy: .public)")
            exportError = "\(L.t(.couldNotSave, language)): \(error.localizedDescription)"
        }
        pendingRestore = nil
    }

    private func exportEverything() {
        do {
            exportURLs = [try DataExport.write(
                invoices: allInvoices,
                stock: allStock,
                contacts: allContacts,
                movements: allMovements,
                currencySymbol: AppSettings.currencySymbol
            )]
            exportError = nil
            Haptics.success()
        } catch {
            Haptics.error()
            AppLog.export.error("Export failed: \(error.localizedDescription, privacy: .public)")
            exportError = "\(L.t(.couldNotSave, language)): \(error.localizedDescription)"
        }
    }

    private var historySection: some View {
        section(title: L.t(.history, language)) {
            VStack(spacing: 8) {
                Button {
                    Haptics.warning()
                    showClearHistoryAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.scaled(size: 15, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L.t(.clearHistory, language))
                                .font(.scaled(size: 17, weight: .medium, design: .rounded))
                            Text(L.t(.clearHistoryCaption, language))
                                .font(.scaled(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 72)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.30), lineWidth: 0.8))
                }
                .buttonStyle(.plain)

                if let clearHistoryError {
                    noticeLine(clearHistoryError, tint: .red)
                }
            }
        }
    }

    private func clearHistory() {
        do {
            try modelContext.delete(model: StockMovement.self)
            try modelContext.save()
            Haptics.success()
            clearHistoryError = nil
        } catch {
            Haptics.error()
            clearHistoryError = "\(L.t(.couldNotSave, language)): \(error.localizedDescription)"
        }
    }

    private var syncSection: some View {
        section(title: L.t(.iCloudSync, language)) {
            VStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { cloudSyncEnabled },
                    set: { newValue in
                        Haptics.light()
                        cloudSyncEnabled = newValue
                        showRestartNotice = true
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t(.iCloudSync, language))
                            .font(.scaled(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(L.t(.iCloudSyncCaption, language))
                            .font(.scaled(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(InvoiceStatus.shipped.tint)
                .padding(.horizontal, 18)
                .frame(minHeight: 72)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))

                if cloudSyncEnabled && AppSettings.cloudSyncUnavailable {
                    noticeLine(L.t(.iCloudUnavailable, language), tint: .orange)
                } else if showRestartNotice {
                    noticeLine(L.t(.restartToApply, language), tint: .secondary)
                }
            }
        }
    }

#if DEBUG
    private var debugSection: some View {
        section(title: "Debug") {
            VStack(spacing: 8) {
                dataRow(
                    icon: "wand.and.stars",
                    title: "Fill with sample data",
                    caption: "A shelf and eight months of trade, so every screen has something in it",
                    tint: .primary
                ) {
                    Haptics.medium()
                    runDebug { try DebugData.populate(context: modelContext) }
                }

                dataRow(
                    icon: "trash.slash",
                    title: "Delete everything",
                    caption: "Invoices, stock, contacts, history and the PDFs on disk",
                    tint: .red
                ) {
                    Haptics.warning()
                    showDebugWipeAlert = true
                }

                if let debugResult {
                    noticeLine(debugResult, tint: .secondary)
                }

                noticeLine("Debug builds only. This section is not compiled into a release.", tint: .secondary)
            }
        }
        .alert("Delete everything?", isPresented: $showDebugWipeAlert) {
            Button("Delete", role: .destructive) {
                runDebug { try DebugData.wipe(context: modelContext) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every invoice, model, contact and PDF goes. This cannot be undone.")
        }
    }

    private func runDebug(_ work: () throws -> String) {
        do {
            debugResult = try work()
            Haptics.success()
        } catch {
            Haptics.error()
            AppLog.data.error("Debug action failed: \(error.localizedDescription, privacy: .public)")
            debugResult = error.localizedDescription
        }
    }
#endif

    private func noticeLine(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.scaled(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.top, 2)
    }

    private var stockSection: some View {
        section(title: L.t(.stockTitle, language)) {
            numberRow(
                label: L.t(.lowStockThreshold, language),
                caption: L.t(.lowStockCaption, language),
                value: $lowStockThreshold
            )
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.scaled(size: 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            content()
        }
        .padding(.horizontal, 20)
    }

    private func optionRow(leading: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(leading)
                    .font(.scaled(size: 20, weight: .semibold, design: .rounded))
                    .frame(width: 34, alignment: .leading)

                Text(title)
                    .font(.scaled(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.scaled(size: 20))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.35))
            }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(isSelected ? 0.45 : 0.12), lineWidth: isSelected ? 1.4 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func numberRow(label: String, caption: String, value: Binding<Int>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.scaled(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                Text(caption)
                    .font(.scaled(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(value.wrappedValue)")
                .font(.scaled(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(minWidth: 34, alignment: .trailing)
                .contentTransition(.numericText())
                .animation(AppAnimation.quick, value: value.wrappedValue)

            Stepper("", value: value, in: 0...99)
                .labelsHidden()
                .fixedSize()
        }
        .padding(.horizontal, 18)
        .frame(height: 72)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }
}
