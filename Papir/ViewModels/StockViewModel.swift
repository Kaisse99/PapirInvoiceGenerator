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
//  The filter menu is the same shape as the invoice list's: one filter that
//  hides models and one order that rearranges them, both read by the same
//  pass. StockFilter.colorAtZero counts a negative color as well as a flat
//  zero, because minus two of a color is no more sellable than none of it and
//  a filter that hid the miscount would hide the thing worth acting on.
//  understocked asks the model's own total state instead, which is the
//  reorder question: how little is left of this model at all, whatever the
//  colors under it are doing. Sorting always breaks a tie on the code, so a
//  shelf full of equal numbers does not reshuffle itself when one count moves.
//  No order chosen means code order, which is why sortOption is optional and
//  the menu offers only the four real orders. There was a Model code entry
//  standing for the default and it read as an odd fifth thing beside them, so
//  the absence carries it instead. Nothing puts the code order back within a
//  session; a relaunch does, since none of this is stored.
//  Holds no models of its own, the view owns the @Query and hands them in.
//  Used by: StockView, StockModelDetailView.
//

import SwiftUI
import os
import SwiftData
import Combine

@MainActor
final class StockViewModel: ObservableObject {
    enum SortOption: String, CaseIterable, Identifiable {
        case mostPacks, fewestPacks, newest, oldest

        var id: String { rawValue }

        var title: String {
            switch self {
            case .mostPacks:   return L.t(.mostPacks)
            case .fewestPacks: return L.t(.fewestPacks)
            case .newest:      return L.t(.newest)
            case .oldest:      return L.t(.oldest)
            }
        }

        var systemImage: String {
            switch self {
            case .mostPacks:   return "arrow.down"
            case .fewestPacks: return "arrow.up"
            case .newest:      return "clock"
            case .oldest:      return "clock.arrow.circlepath"
            }
        }
    }

    enum StockFilter: String, CaseIterable, Identifiable {
        case all, colorAtZero, understocked

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:          return L.t(.allModels)
            case .colorAtZero:  return L.t(.colorAtZero)
            case .understocked: return L.t(.understocked)
            }
        }

        var systemImage: String {
            switch self {
            case .all:          return "shippingbox"
            case .colorAtZero:  return "0.circle"
            case .understocked: return "exclamationmark.triangle"
            }
        }

        func matches(_ model: StockModel) -> Bool {
            switch self {
            case .all:          return true
            case .colorAtZero:  return model.allLines.contains { $0.packs <= 0 }
            case .understocked: return model.totalState != .healthy
            }
        }
    }

    @Published var searchText: String = ""
    @Published var sortOption: SortOption? = nil
    @Published var stockFilter: StockFilter = .all
    @Published var showAddModel: Bool = false
    @Published var newModelCode: String = ""
    @Published var newModelPrice: String = ""
    @Published var addModelError: String? = nil
    @Published var modelToDelete: StockModel? = nil
    @Published var notice: StockNotice? = nil

    func filteredAndSorted(_ models: [StockModel]) -> [StockModel] {
        var result = models.filter { stockFilter.matches($0) }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { model in
                model.code.lowercased().contains(query)
                    || model.allLines.contains { $0.color.lowercased().contains(query) }
            }
        }

        switch sortOption {
        case .none:
            result.sort { byCode($0, $1) }
        case .mostPacks:
            result.sort { $0.totalPacks == $1.totalPacks ? byCode($0, $1) : $0.totalPacks > $1.totalPacks }
        case .fewestPacks:
            result.sort { $0.totalPacks == $1.totalPacks ? byCode($0, $1) : $0.totalPacks < $1.totalPacks }
        case .newest:
            result.sort { $0.createdAt == $1.createdAt ? byCode($0, $1) : $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt == $1.createdAt ? byCode($0, $1) : $0.createdAt < $1.createdAt }
        }

        return result
    }

    private func byCode(_ left: StockModel, _ right: StockModel) -> Bool {
        left.code.localizedStandardCompare(right.code) == .orderedAscending
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

        let model = StockModel(
            code: code,
            pricePerPiece: max(0, Double(newModelPrice) ?? 0).moneyRounded,
            piecesPerPack: max(1, AppSettings.defaultItemsPerUnit)
        )
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
