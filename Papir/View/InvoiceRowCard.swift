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
    
    @FocusState private var focusedField: Field?
    
    let rowNumber: Int
    @Binding var name: String
    @Binding var unitCount: String
    @Binding var itemsPerUnit: String
    @Binding var price: String
    @Binding var colors: [String]
    
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var newColorInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: Row number badge
            Text("#\(rowNumber)")
                .font(.caption)
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.systemBackground))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.primary)
                )
            
            // MARK: Name
            LabeledField(
                label: "Name",
                text: $name,
                showClearButton: true
            )
            .limitInput($name, to: 40)
            
            // MARK: Numeric fields
            HStack(spacing: 10) {
                LabeledField(
                    label: "Units",
                    text: $unitCount,
                    placeholder: "0",
                    keyboardType: .numberPad,
                    centerAlign: true,
                    focusBinding: $focusedField,
                    focusValue: .units
                )
                .limitInput($unitCount, to: 4)
                .onChange(of: unitCount) { _, newValue in
                    if newValue.count == 4 {
                        focusedField = .perUnit
                    }
                }
                
                Text("×")
                    .font(.title3)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                LabeledField(
                    label: "Per unit",
                    text: $itemsPerUnit,
                    placeholder: "0",
                    keyboardType: .numberPad,
                    centerAlign: true,
                    focusBinding: $focusedField,
                    focusValue: .perUnit
                )
                .limitInput($itemsPerUnit, to: 4)
                .onChange(of: itemsPerUnit) { _, newValue in
                    if newValue.count == 4 {
                        focusedField = .price
                    }
                }
                
                Text("×")
                    .font(.title3)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                LabeledField(
                    label: "Price",
                    text: $price,
                    placeholder: "0",
                    keyboardType: .decimalPad,
                    centerAlign: true,
                    focusBinding: $focusedField,
                    focusValue: .price
                )
                .onChange(of: price) { _, newValue in
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
            }
            
            // MARK: Colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                FlowLayout(spacing: 6) {
                    ForEach(colors, id: \.self) { color in
                        colorBadge(color)
                    }
                    
                    colorInputField
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .primary.opacity(0.08), radius: 18, y: 3)
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showDeleteConfirmation = true
        }
        .confirmationDialog(
            "Delete row #\(rowNumber)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private func colorBadge(_ color: String) -> some View {
        HStack(spacing: 4) {
            Text(color)
                .font(.callout)
                .fontDesign(.monospaced)
            
            Button {
                colors.removeAll { $0 == color }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
        )
        .overlay(
            Capsule()
                .stroke(.primary.opacity(0.3), lineWidth: 0.5)
        )
        .foregroundStyle(.primary)
    }
    
    private var colorInputField: some View {
        TextField("+ add", text: $newColorInput)
            .fontDesign(.monospaced)
            .font(.callout)
            .fixedSize()
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .submitLabel(.done)
            .limitInput($newColorInput, to: 10)
            .onChange(of: newColorInput) { _, newValue in
                if newValue.contains(" ") {
                    commitColor()
                }
            }
            .onSubmit { commitColor() }
    }
    
    private func commitColor() {
        let trimmed = newColorInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !colors.contains(trimmed) {
            colors.append(trimmed)
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
    
    var body: some View {
        InvoiceRowCard(
            rowNumber: 1,
            name: $name,
            unitCount: $unitCount,
            itemsPerUnit: $itemsPerUnit,
            price: $price,
            colors: $colors,
            onDelete: {}
        )
        .padding()
    }
}
