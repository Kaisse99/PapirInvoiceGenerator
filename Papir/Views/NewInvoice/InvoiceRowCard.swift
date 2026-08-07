//
//  InvoiceRowCard.swift
//  One editable invoice row. Name, units × per-unit × price, and a color list
//  that grows a badge per entry; the running subtotal appears as soon as the
//  three numbers parse. Filling a numeric field to its limit jumps focus to the
//  next one, so a row can be typed without reaching for the screen. The badge
//  in the top corner is the row's state at a glance: a ring that closes a
//  quarter at a time as the four required fields are filled, then a solid ink
//  disc with a tick when the row is whole. It sits there from the first
//  keystroke rather than appearing only at the end, so the row says how far
//  off it is while there is still something to do about it, and it mirrors the
//  lock opposite it so the two corners read as a pair. Amber with a bang means
//  the row is complete but carries something worth a second look, today a
//  breakdown that does not add up or a price that is not the shelf price;
//  neither blocks saving.
//  Locking collapses the card to a read-only summary and can only happen once
//  the row is complete. The card starts locked when an existing invoice is
//  reopened.
//  Long-pressing an unlocked card offers to delete it. Typing in the name
//  offers matching stock codes underneath it, the way a location field does,
//  because there are far too many models to list up front; a code that looks
//  like a model but is not on the shelf says so instead.
//  Once a row has colors on it the colors own the unit count: every add,
//  remove and stepper writes their sum into Units and the field goes read-only,
//  because typing the same total in two places is how the two ended up
//  disagreeing. Removing the last color leaves the number where it was rather
//  than resetting it to zero, and a row with no colors is typed by hand as
//  before. An old row whose stored breakdown does not add up still says so,
//  since nothing rewrites it until she touches a color.
//  A name that matches a stock model with a price fills the price in, and the
//  name owns that field from then on: pointing the row at another model
//  refills it, and pointing it at nothing empties it again, so a price left
//  over from a model that is no longer named cannot be signed off by accident.
//  A price typed on a row that never matched anything is hers and is left
//  alone. She may still overwrite a filled-in price; that is not an error, so
//  the field only goes amber and says what the shelf price was, and saving is
//  not blocked. What is saved is whatever the field says at that moment: the
//  invoice keeps its own number and never re-reads the model afterwards.
//  Used by: NewInvoiceView.
//

import SwiftUI

struct InvoiceRowCard: View {
    enum Field: Hashable {
        case name, units, perUnit, price
    }

    @FocusState private var focusedField: Field?
    
    let rowNumber: Int
    @Binding var name: String
    @Binding var unitCount: String
    @Binding var itemsPerUnit: String
    @Binding var price: String
    @Binding var colors: [String]
    @Binding var colorPacks: [Int]
    @Binding var isLocked: Bool
    
    let nameError: Bool
    let unitsError: Bool
    let perUnitError: Bool
    let priceError: Bool
    
    var stockSuggestions: [StockSuggestion] = []

    let onClearError: (Field?) -> Void
    let onClearNameError: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var newColorInput: String = ""
    @State private var visibleTotal: Double? = nil
    @State private var visibleSuggestions: [StockSuggestion] = []
    @State private var showsUnknownCode = false
    @State private var priceSourceCode: String? = nil
    
    private var cardBackground: Color {
        Color(.systemGray6)
    }
    
    private var isComplete: Bool {
        !name.isEmpty && !unitCount.isEmpty && !itemsPerUnit.isEmpty && !price.isEmpty
    }
    
    private var rowTotal: Double? {
        guard let u = Double(unitCount), let p = Double(itemsPerUnit), let pr = Double(price) else {
            return nil
        }
        return u * p * pr
    }
    
    private static let totalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private func formatted(_ value: Double) -> String {
        Self.totalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if isLocked {
                lockedContent
            } else {
                editableContent
            }
            
            if let total = visibleTotal {
                rowSubtotal(total)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBackground)
                .stroke(.primary.opacity(0.30), lineWidth: 0.8)
                .raisedShadow()
        )
        .animation(AppAnimation.quick, value: isLocked)
        .onAppear { syncDerived(animated: false) }
        .onChange(of: name) { _, _ in
            syncDerived()
            applyStockPrice()
        }
        .onChange(of: unitCount) { _, _ in syncDerived() }
        .onChange(of: itemsPerUnit) { _, _ in syncDerived() }
        .onChange(of: price) { _, _ in syncDerived() }
        .onChange(of: focusedField) { _, _ in syncDerived() }
        .onChange(of: colors) { _, _ in syncUnitsToColors() }
        .onChange(of: colorPacks) { _, _ in syncUnitsToColors() }
        .overlay(alignment: .topLeading) {
            if !isLocked {
                statusBadge
                    .offset(x: -6, y: -6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            lockButton.offset(x: 6, y: -6)
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            if !isLocked {
                Haptics.medium()
                showDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "\(L.t(.deleteRow)) #\(rowNumber)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L.t(.delete), role: .destructive) { onDelete() }
            Button(L.t(.cancel), role: .cancel) {}
        } message: {
            Text(L.t(.cannotBeUndone))
        }
    }
    
    private var editableContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                rowNumberBadge
                
                LabeledField(
                    label: L.t(.name),
                    text: $name,
                    showClearButton: true,
                    isError: nameError,
                    errorMessage: nameError ? L.t(.required) : nil,
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .name
                )
                .limitInput($name, to: 40)
                .onChange(of: name) { _, _ in
                    if nameError { onClearNameError() }
                }
            }

            if !visibleSuggestions.isEmpty {
                suggestionList
                    .padding(.bottom, 4)
            } else if showsUnknownCode {
                Text(L.t(.notInStockYet))
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            } else if let matched = matchedModel {
                Text("\(L.t(.inStock)): \(matched.packs)")
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
            
            HStack(spacing: 10) {
                LabeledField(
                    label: L.t(.units),
                    text: $unitCount,
                    placeholder: "0",
                    keyboardType: .numberPad,
                    centerAlign: true,
                    isError: unitsError,
                    isDisabled: unitsFollowColors,
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .units
                )
                .digitsOnly($unitCount)
                .limitInput($unitCount, to: 4)
                .onChange(of: unitCount) { _, newValue in
                    if unitsError { onClearError(.units) }
                    if newValue.count == 4 && !unitsFollowColors { focusedField = .perUnit }
                }
                
                multiplySign
                
                LabeledField(
                    label: L.t(.perUnit),
                    text: $itemsPerUnit,
                    placeholder: "0",
                    keyboardType: .numberPad,
                    centerAlign: true,
                    isError: perUnitError,
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .perUnit
                )
                .digitsOnly($itemsPerUnit)
                .limitInput($itemsPerUnit, to: 4)
                .onChange(of: itemsPerUnit) { _, newValue in
                    if perUnitError { onClearError(.perUnit) }
                    if newValue.count == 4 { focusedField = .price }
                }
                
                multiplySign
                
                LabeledField(
                    label: L.t(.price),
                    text: $price,
                    placeholder: "0",
                    keyboardType: .decimalPad,
                    centerAlign: true,
                    isError: priceError,
                    isWarning: priceOffStock,
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .price
                )
                .onChange(of: price) { _, newValue in
                    if priceError { onClearError(.price) }
                    sanitizePrice(newValue)
                }
            }

            if priceOffStock, let stockPrice {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.scaled(size: 9))

                    Text("\(L.t(.differsFromStock)): \(PriceText.display(stockPrice)) \(AppSettings.currencySymbol)")
                        .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.orange)
                .padding(.leading, 6)
                .transition(.opacity)
            }

            if unitsFollowColors {
                Text(L.t(.unitsFollowColors))
                    .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
                    .transition(.opacity)
            }

            colorsSection
        }
    }
    
    private func syncDerived(animated: Bool = true) {
        let total = rowTotal
        let codes = matchingCodes
        let unknown = showsUnknownCodeHint

        let resizes = (total != nil) != (visibleTotal != nil)
            || codes.map(\.code) != visibleSuggestions.map(\.code)
            || unknown != showsUnknownCode

        guard animated && resizes else {
            visibleTotal = total
            visibleSuggestions = codes
            showsUnknownCode = unknown
            return
        }

        withAnimation(AppAnimation.fast) {
            visibleTotal = total
            visibleSuggestions = codes
            showsUnknownCode = unknown
        }
    }

    private var unitsFollowColors: Bool {
        !colors.isEmpty && colorPacks.count == colors.count
    }

    private func syncUnitsToColors() {
        guard unitsFollowColors else { return }
        let total = colorPacks.reduce(0, +)
        guard total > 0 else { return }
        let text = "\(total)"
        guard unitCount != text else { return }
        unitCount = text
    }

    private var stockPrice: Double? {
        guard let model = matchedModel, model.pricePerPiece > 0 else { return nil }
        return model.pricePerPiece
    }

    private var priceOffStock: Bool {
        guard let stockPrice, let typed = Double(price) else { return false }
        return typed != stockPrice
    }

    private func applyStockPrice() {
        guard let model = matchedModel, model.pricePerPiece > 0 else {
            guard priceSourceCode != nil else { return }
            priceSourceCode = nil
            price = ""
            return
        }

        guard priceSourceCode != model.code else { return }
        priceSourceCode = model.code
        price = PriceText.editable(model.pricePerPiece)
    }

    private var matchedModel: StockSuggestion? {
        if let exact = stockSuggestions.first(where: { $0.code.caseInsensitiveCompare(typedCode) == .orderedSame }) {
            return exact
        }
        for token in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
            let candidate = String(token)
            if let hit = stockSuggestions.first(where: { $0.code.caseInsensitiveCompare(candidate) == .orderedSame }) {
                return hit
            }
        }
        return nil
    }

    private var suggestedColors: [String] {
        guard let model = matchedModel else { return [] }
        return model.colors.filter { option in
            !colors.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
        }
    }

    private func isKnownColor(_ color: String) -> Bool {
        guard let model = matchedModel else { return true }
        return model.colors.contains { $0.caseInsensitiveCompare(color) == .orderedSame }
    }

    private var assignedPacks: Int {
        colorPacks.reduce(0, +)
    }

    private var unitsValue: Int {
        Int(unitCount) ?? 0
    }

    private var breakdownMismatch: Bool {
        !colors.isEmpty && unitsValue > 0 && assignedPacks != unitsValue
    }

    private func packs(at index: Int) -> Int {
        index < colorPacks.count ? colorPacks[index] : 0
    }

    private func setPacks(_ value: Int, at index: Int) {
        guard index < colors.count else { return }
        while colorPacks.count < colors.count { colorPacks.append(1) }
        colorPacks[index] = max(0, value)
    }

    private var typedCode: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var matchingCodes: [StockSuggestion] {
        guard focusedField == .name, !typedCode.isEmpty else { return [] }
        guard !stockSuggestions.contains(where: { $0.code.caseInsensitiveCompare(typedCode) == .orderedSame }) else {
            return []
        }

        let needle = typedCode.lowercased()
        let starting = stockSuggestions.filter { $0.code.lowercased().hasPrefix(needle) }
        let containing = stockSuggestions.filter {
            let code = $0.code.lowercased()
            return !code.hasPrefix(needle) && code.contains(needle)
        }
        return Array((starting + containing).prefix(5))
    }

    private var showsUnknownCodeHint: Bool {
        guard focusedField == .name, !stockSuggestions.isEmpty else { return false }
        guard typedCode.count >= 3, matchingCodes.isEmpty else { return false }
        return matchedModel == nil
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleSuggestions.enumerated()), id: \.element.code) { index, suggestion in
                Button {
                    Haptics.light()
                    name = suggestion.code
                    focusedField = nil
                    if nameError { onClearNameError() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "shippingbox")
                            .font(.scaled(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text(suggestion.code)
                            .font(.scaled(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(suggestion.packs) \(L.t(.packsLower))")
                            .font(.scaled(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < visibleSuggestions.count - 1 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 1)
                        .padding(.leading, 42)
                        .padding(.trailing, 14)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground).opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.15), lineWidth: 1))
        .transition(.opacity)
    }

    private var multiplySign: some View {
        Text("×")
            .font(.title3)
            .fontDesign(.monospaced)
            .foregroundStyle(.secondary)
    }
    
    private func sanitizePrice(_ newValue: String) {
        let filtered = newValue.filter { "0123456789.".contains($0) }
        let dots = filtered.filter { $0 == "." }.count
        
        if dots > 1 {
            var seen = false
            price = filtered.reduce(into: "") { result, char in
                if char == "." {
                    if !seen { result.append(char); seen = true }
                } else {
                    result.append(char)
                }
            }
        } else if filtered != newValue {
            price = filtered
        } else if newValue.count > 7 {
            price = String(newValue.prefix(7))
        }
    }
    
    private var lockedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("\(L.t(.row)) #\(rowNumber):")
                    .font(.body)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(name)
                    .font(.body)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Text(unitCount)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary)
                multiplySign
                Text(itemsPerUnit)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary)
                multiplySign
                Text(price)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary)
                Text(AppSettings.currencySymbol)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            if !colors.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(colors.enumerated()), id: \.element) { index, color in
                        Text("\(color) \(packs(at: index))")
                            .font(.callout)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(.systemBackground).opacity(0.1)))
                            .overlay(Capsule().stroke(.primary.opacity(0.35), lineWidth: 0.6))
                    }
                }
            }
        }
    }
    
    private func rowSubtotal(_ total: Double) -> some View {
        HStack(spacing: 6) {
            Spacer()
            Text("\(L.t(.subtotal)): ")
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            Text(formatted(total))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(AppSettings.currencySymbol)
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    
    private var rowNumberBadge: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                Spacer()
                Text("#\(rowNumber)")
                    .font(.scaled(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(width: 68, height: 56)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.55), lineWidth: 1))
            
            Text(L.t(.row))
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .background(cardBackground)
                .offset(x: 14, y: -8)
        }
    }
    
    private var filledFieldCount: Int {
        [name, unitCount, itemsPerUnit, price]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .count
    }

    private var completion: Double {
        Double(filledFieldCount) / 4
    }

    private var needsAttention: Bool {
        isComplete && (breakdownMismatch || priceOffStock)
    }

    private var statusTint: Color {
        needsAttention ? .orange : .primary
    }

    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(cardBackground)

            Circle()
                .fill(statusTint)
                .opacity(isComplete ? 1 : 0)

            Circle()
                .stroke(Color.primary.opacity(0.18), lineWidth: 2)
                .opacity(isComplete ? 0 : 1)

            Circle()
                .trim(from: 0, to: completion)
                .stroke(Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(isComplete ? 0 : 1)

            Image(systemName: needsAttention ? "exclamationmark" : "checkmark")
                .font(.scaled(size: 11, weight: .heavy))
                .foregroundStyle(Color(.systemBackground))
                .contentTransition(.symbolEffect(.replace))
                .opacity(isComplete ? 1 : 0)
                .scaleEffect(isComplete ? 1 : 0.4)
        }
        .frame(width: 24, height: 24)
        .animation(AppAnimation.quick, value: completion)
        .animation(AppAnimation.quick, value: needsAttention)
    }
    
    private var lockButton: some View {
        Button {
            if !isLocked && !isComplete {
                Haptics.warning()
                return
            }
            Haptics.light()
            withAnimation(AppAnimation.quick) {
                isLocked.toggle()
            }
            if isLocked { focusedField = nil }
        } label: {
            Image(systemName: isLocked ? "lock.fill" : "lock")
                .font(.scaled(size: 11, weight: .semibold))
                .foregroundStyle(isLocked ? Color(.systemBackground) : .primary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(isLocked ? Color.primary : Color(.systemBackground)))
                .overlay(Circle().stroke(.primary.opacity(0.3), lineWidth: 0.8))
                .opacity(!isLocked && !isComplete ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.t(.colorsCaps))
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)
            
            if !colors.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(colors.enumerated()), id: \.element) { index, color in
                        colorRow(color, at: index)
                    }
                }

                if breakdownMismatch {
                    reconciliationLine
                }
            }

            if !suggestedColors.isEmpty {
                stockColorOptions
            }

            HStack(spacing: 10) {
                TextField(L.t(.addColor), text: $newColorInput)
                    .font(.scaled(size: 15, weight: .medium, design: .monospaced))
                    .submitLabel(.done)
                    .limitInput($newColorInput, to: 12)
                    .onSubmit { commitColor() }
                
                Button {
                    commitColor()
                } label: {
                    Image(systemName: "plus")
                        .font(.scaled(size: 14, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.primary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground).opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.15), lineWidth: 1))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground).opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.primary.opacity(0.08), lineWidth: 1))
    }
    
    private func colorRow(_ color: String, at index: Int) -> some View {
        let known = isKnownColor(color)
        let onHand = matchedModel?.packs(for: color)

        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(color)
                        .font(.scaled(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(known ? Color.primary : Color.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if !known {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.scaled(size: 10))
                            .foregroundStyle(Color.orange)
                    }
                }

                if let onHand {
                    Text("\(L.t(.inStock)): \(onHand)")
                        .font(.scaled(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(onHand < packs(at: index) ? Color.orange : .secondary)
                }
            }

            Spacer(minLength: 6)

            Text("\(packs(at: index))")
                .font(.scaled(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.primary)
                .frame(minWidth: 22, alignment: .trailing)
                .contentTransition(.numericText())
                .animation(AppAnimation.quick, value: packs(at: index))

            Stepper("", value: Binding(
                get: { packs(at: index) },
                set: { setPacks($0, at: index) }
            ), in: 1...999)
                .labelsHidden()
                .fixedSize()

            Button {
                withAnimation(AppAnimation.quick) {
                    if index < colorPacks.count { colorPacks.remove(at: index) }
                    colors.remove(at: index)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.scaled(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 50)
        .background(RoundedRectangle(cornerRadius: 12).fill(known ? Color.primary.opacity(0.06) : Color.orange.opacity(0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(known ? Color.primary.opacity(0.12) : Color.orange.opacity(0.5), lineWidth: 1)
        )
    }

    private var reconciliationLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.scaled(size: 11))
                .foregroundStyle(Color.orange)

            Text("\(assignedPacks) / \(unitsValue) \(L.t(.assignedToColors))")
                .font(.scaled(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.orange)

            Spacer()
        }
        .padding(.top, 2)
    }

    private var stockColorOptions: some View {
        FlowLayout(spacing: 6) {
            ForEach(suggestedColors, id: \.self) { option in
                Button {
                    Haptics.light()
                    withAnimation(AppAnimation.quick) {
                        colors.append(option)
                        colorPacks.append(1)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.scaled(size: 9, weight: .bold))
                        Text(option)
                            .font(.scaled(size: 13, weight: .medium, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Capsule().fill(Color.primary.opacity(0.05)))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.8))
                    .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func commitColor() {
        let trimmed = newColorInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !colors.contains(trimmed) {
            withAnimation(AppAnimation.quick) {
                colors.append(trimmed)
                colorPacks.append(1)
            }
        }
        newColorInput = ""
    }
}

struct StockSuggestion: Identifiable, Equatable {
    let code: String
    let packs: Int
    let pricePerPiece: Double
    let colorStock: [ColorAllocation]

    var id: String { code }

    var colors: [String] {
        colorStock.map(\.color)
    }

    func packs(for color: String) -> Int? {
        colorStock.first { $0.color.caseInsensitiveCompare(color) == .orderedSame }?.packs
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var name = ""
    @State private var unitCount = ""
    @State private var itemsPerUnit = ""
    @State private var price = ""
    @State private var colors: [String] = []
    @State private var colorPacks: [Int] = []
    @State private var isLocked = false
    
    var body: some View {
        InvoiceRowCard(
            rowNumber: 1,
            name: $name,
            unitCount: $unitCount,
            itemsPerUnit: $itemsPerUnit,
            price: $price,
            colors: $colors,
            colorPacks: $colorPacks,
            isLocked: $isLocked,
            nameError: false,
            unitsError: false,
            perUnitError: false,
            priceError: false,
            onClearError: { _ in },
            onClearNameError: {},
            onDelete: {}
        )
        .padding()
    }
}
