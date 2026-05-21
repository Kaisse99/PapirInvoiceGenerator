//
//  InvoiceRowCard.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-15.
//

import SwiftUI

struct InvoiceRowCard: View {
    enum Field: Hashable {
        case units, perUnit, price
    }
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?
    
    let rowNumber: Int
    @Binding var name: String
    @Binding var unitCount: String
    @Binding var itemsPerUnit: String
    @Binding var price: String
    @Binding var colors: [String]
    @Binding var isLocked: Bool
    
    let nameError: Bool
    let unitsError: Bool
    let perUnitError: Bool
    let priceError: Bool
    
    let onClearError: (Field?) -> Void
    let onClearNameError: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var newColorInput: String = ""
    
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
            
            if let total = rowTotal {
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
        .animation(AppAnimation.fast, value: rowTotal != nil)
        .animation(AppAnimation.quick, value: isLocked)
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
            "Delete row #\(rowNumber)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var editableContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                rowNumberBadge
                
                LabeledField(
                    label: "Name",
                    text: $name,
                    showClearButton: true,
                    isError: nameError,
                    errorMessage: nameError ? "Required" : nil,
                    backgroundFill: cardBackground
                )
                .limitInput($name, to: 40)
                .onChange(of: name) { _, _ in
                    if nameError { onClearNameError() }
                }
            }
            
            HStack(spacing: 10) {
                LabeledField(
                    label: "Units",
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
                    label: "Per unit",
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
                    label: "Price",
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
                Text("Row #\(rowNumber):")
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
                Text("₴")
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            if !colors.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(colors, id: \.self) { color in
                        Text(color)
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
            Text("Subtotal: ")
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            Text(formatted(total))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("₴")
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
            
            Text("Row")
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
        Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.green))
            .transition(.scale.combined(with: .opacity))
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
            Text("COLORS")
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)
            
            if !colors.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        colorBadge(color)
                    }
                }
            }
            
            HStack(spacing: 10) {
                TextField("Add color...", text: $newColorInput)
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
    
    private func colorBadge(_ color: String) -> some View {
        HStack(spacing: 6) {
            Text(color)
                .font(.callout)
                .fontDesign(.monospaced)
            
            Button {
                withAnimation(AppAnimation.quick) {
                    colors.removeAll { $0 == color }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Capsule().fill(Color.primary.opacity(0.08)))
        .overlay(Capsule().stroke(.primary.opacity(0.12), lineWidth: 1))
    }
    
    private func commitColor() {
        let trimmed = newColorInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !colors.contains(trimmed) {
            withAnimation(AppAnimation.quick) {
                colors.append(trimmed)
            }
        }
        newColorInput = ""
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
    @State private var isLocked = false
    
    var body: some View {
        InvoiceRowCard(
            rowNumber: 1,
            name: $name,
            unitCount: $unitCount,
            itemsPerUnit: $itemsPerUnit,
            price: $price,
            colors: $colors,
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
