//
//  StockViewModel.swift
//  Everything the stock screens do to the store: search across model codes and
//  colors, create a model once its code is non-blank and not already taken,
//  take packs in, take packs out, and recount a color. Receiving into a color that has no
//  line yet creates that line, so adding a color and adding stock are one
//  action rather than two. A withdrawal that goes past what is on hand still
//  happens and reports its shortfall, which the view turns into a warning;
//  refusing it would only teach her to stop recording.
//  A code already on the shelf cannot be added again, matched without regard
//  to case. The check asks the store rather than only the array the view hands
//  in, because a filtered or stale list would let a duplicate through and
//  CloudKit cannot enforce uniqueness for us.
//  A model's price per piece is optional at creation and can be set or changed
//  at any time from the detail screen, because the code goes on the shelf
//  before anyone agrees what it sells for.
//  Holds no models of its own, the view owns the @Query and hands them in.
//  Used by: StockView, StockModelDetailView.
//

import SwiftUI
import os
import SwiftData
import Combine

@MainActor
final class StockViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var showAddModel: Bool = false
    @Published var newModelCode: String = ""
    @Published var newModelPrice: String = ""
    @Published var addModelError: String? = nil
    @Published var modelToDelete: StockModel? = nil
    @Published var notice: StockNotice? = nil

    func filtered(_ models: [StockModel]) -> [StockModel] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return models }
        return models.filter { model in
            model.code.lowercased().contains(query)
                || model.allLines.contains { $0.color.lowercased().contains(query) }
        }
    }

    func addModel(existing: [StockModel], context: ModelContext) {
        guard let code = StockModel.normalizedCode(newModelCode) else {
            Haptics.warning()
            addModelError = L.t(.modelCodeInvalid)
            return
        }

        let onShelf = existing + ((try? context.fetch(FetchDescriptor<StockModel>())) ?? [])
        if onShelf.contains(where: { $0.code.caseInsensitiveCompare(code) == .orderedSame }) {
            Haptics.warning()
            addModelError = "\(L.t(.modelExists)): \(code)"
            return
        }

        let model = StockModel(code: code, pricePerPiece: max(0, Double(newModelPrice) ?? 0).moneyRounded)
        context.insert(model)
        save(context)

        Haptics.success()
        newModelCode = ""
        newModelPrice = ""
        addModelError = nil
        showAddModel = false
    }

    func setPrice(_ price: Double, on model: StockModel, context: ModelContext) {
        model.pricePerPiece = max(0, price).moneyRounded
        save(context)
        Haptics.success()
    }

    func receive(packs: Int, color rawColor: String, into model: StockModel, context: ModelContext) {
        let color = rawColor.trimmingCharacters(in: .whitespaces)
        guard !color.isEmpty, packs > 0 else { return }

        let resolved: String
        if let line = model.line(for: color) {
            line.receive(packs)
            resolved = line.color
        } else {
            let created = StockLine(color: color.capitalized, packs: packs)
            model.addLine(created)
            resolved = created.color
        }

        context.insert(StockMovement(modelCode: model.code, color: resolved, packs: packs, kind: .received))
        save(context)
        Haptics.success()
    }

    func withdraw(packs: Int, from line: StockLine, in model: StockModel, context: ModelContext) {
        guard packs > 0 else { return }

        let shortfall = line.withdraw(packs)
        context.insert(StockMovement(modelCode: model.code, color: line.color, packs: -packs, kind: .removed))
        save(context)

        if shortfall > 0 {
            Haptics.warning()
            notice = StockNotice(
                title: L.t(.wentNegative),
                message: "\(model.code) \(line.color): \(L.t(.shortBy)) \(shortfall). \(L.t(.negativeExplanation))"
            )
        } else {
            Haptics.success()
        }
    }

    func recount(line: StockLine, to packs: Int, in model: StockModel, context: ModelContext) {
        let delta = packs - line.packs
        line.recount(to: packs)
        if delta != 0 {
            context.insert(StockMovement(modelCode: model.code, color: line.color, packs: delta, kind: .recounted))
        }
        save(context)
        Haptics.success()
    }

    func removeLine(_ line: StockLine, from model: StockModel, context: ModelContext) {
        Haptics.warning()
        withAnimation(AppAnimation.list) {
            model.removeLine(line)
            context.delete(line)
            save(context)
        }
    }

    func delete(_ model: StockModel, context: ModelContext) {
        Haptics.warning()
        withAnimation(AppAnimation.list) {
            context.delete(model)
            save(context)
        }
        modelToDelete = nil
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            Haptics.error()
            AppLog.data.error("Stock save failed: \(error.localizedDescription, privacy: .public)")
            notice = StockNotice(
                title: L.t(.couldNotSave),
                message: error.localizedDescription
            )
        }
    }
}

struct StockNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
