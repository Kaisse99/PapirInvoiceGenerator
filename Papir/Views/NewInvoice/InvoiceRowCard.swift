//
//  InvoiceRowCard.swift
//  One editable invoice row. Name, units × per-unit × price, and a color list
//  that grows a badge per entry; the running subtotal appears as soon as the
//  three numbers parse. Filling a numeric field to its limit jumps focus to the
//  next one, so a row can be typed without reaching for the screen. Locking
//  collapses the card to a read-only summary and can only happen once the row
//  is complete. The card starts locked when an existing invoice is reopened.
//  Long-pressing an unlocked card offers to delete it. Typing in the name
//  offers matching stock codes underneath it, the way a location field does,
//  because there are far too many models to list up front; a code that looks
//  like a model but is not on the shelf says so instead.
//  Used by: NewInvoiceView.
//

import SwiftUI

struct InvoiceRowCard: View {
    enum Field: Hashable {
        case name, units, perUnit, price
    }
    
    @Environment(\.colorScheme) var colorScheme
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
                .shadow(color: .primary.opacity(0.10), radius: 8, y: 4)
        )
        .animation(AppAnimation.quick, value: isLocked)
        .onAppear { syncDerived(animated: false) }
        .onChange(of: name) { _, _ in syncDerived() }
        .onChange(of: unitCount) { _, _ in syncDerived() }
        .onChange(of: itemsPerUnit) { _, _ in syncDerived() }
        .onChange(of: price) { _, _ in syncDerived() }
        .onChange(of: focusedField) { _, _ in syncDerived() }
        .overlay(alignment: .topLeading) {
            if isComplete && !isLocked {
                completeCheckmark.offset(x: -6, y: -6)
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
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .units
                )
                .digitsOnly($unitCount)
                .limitInput($unitCount, to: 4)
                .onChange(of: unitCount) { _, newValue in
                    if unitsError { onClearError(.units) }
                    if newValue.count == 4 { focusedField = .perUnit }
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
                    backgroundFill: cardBackground,
                    focusBinding: $focusedField,
                    focusValue: .price
                )
                .onChange(of: price) { _, newValue in
                    if priceError { onClearError(.price) }
                    sanitizePrice(newValue)
                }
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

    private var matchedModel: StockSuggestion? {
        if let exact = stockSuggestions.first(where: { $0.code == typedCode }) {
            return exact
        }
        for token in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
            let candidate = String(token).uppercased()
            if let hit = stockSuggestions.first(where: { $0.code == candidate }) {
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
        name.trimmingCharacters(in: .whitespaces).uppercased()
    }

    private var matchingCodes: [StockSuggestion] {
        guard focusedField == .name, !typedCode.isEmpty else { return [] }
        guard !stockSuggestions.contains(where: { $0.code == typedCode }) else { return [] }

        let starting = stockSuggestions.filter { $0.code.hasPrefix(typedCode) }
        let containing = stockSuggestions.filter { !$0.code.hasPrefix(typedCode) && $0.code.contains(typedCode) }
        return Array((starting + containing).prefix(5))
    }

    private var showsUnknownCodeHint: Bool {
        guard focusedField == .name, !stockSuggestions.isEmpty else { return false }
        guard StockModel.normalizedCode(typedCode) != nil else { return false }
        return !stockSuggestions.contains { $0.code == typedCode }
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
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text(suggestion.code)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(suggestion.packs) \(L.t(.packsLower))")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
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
    
    private var completeCheckmark: some View {
        Image(systemName: breakdownMismatch ? "exclamationmark" : "checkmark")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(breakdownMismatch ? Color.orange : Color.green))
            .transition(.scale.combined(with: .opacity))
            .animation(AppAnimation.fast, value: breakdownMismatch)
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
                .font(.system(size: 11, weight: .semibold))
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

                reconciliationLine
            }

            if !suggestedColors.isEmpty {
                stockColorOptions
            }

            HStack(spacing: 10) {
                TextField(L.t(.addColor), text: $newColorInput)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .submitLabel(.done)
                    .limitInput($newColorInput, to: 12)
                    .onSubmit { commitColor() }
                
                Button {
                    commitColor()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
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
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(known ? Color.primary : Color.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if !known {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.orange)
                    }
                }

                if let onHand {
                    Text("\(L.t(.inStock)): \(onHand)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(onHand < packs(at: index) ? Color.orange : .secondary)
                }
            }

            Spacer(minLength: 6)

            Text("\(packs(at: index))")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
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
                    .font(.system(size: 10, weight: .bold))
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
            if breakdownMismatch {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.orange)
            }

            Text("\(assignedPacks) / \(unitsValue) \(L.t(.assignedToColors))")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(breakdownMismatch ? Color.orange : .secondary)

            Spacer()
        }
        .padding(.top, 2)
    }

    private var stockColorOptions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t(.colorsOnTheShelf).uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.secondary)

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
                                .font(.system(size: 9, weight: .bold))
                            Text(option)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
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
