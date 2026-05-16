//
//  LabeledField.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-16.
//

import SwiftUI

struct LabeledField<FocusValue: Hashable>: View {
    let label: String
    @Binding var text: String
    
    var placeholder: String = ""
    var showClearButton: Bool = false
    var keyboardType: UIKeyboardType = .default
    var centerAlign: Bool = false
    
    var focusBinding: FocusState<FocusValue?>.Binding?
    var focusValue: FocusValue?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                let field = TextField(placeholder, text: $text)
                    .fontDesign(.monospaced)
                    .keyboardType(keyboardType)
                    .multilineTextAlignment(centerAlign ? .center : .leading)
                
                if let focusBinding, let focusValue {
                    field.focused(focusBinding, equals: focusValue)
                } else {
                    field
                }
                
                if showClearButton && !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, centerAlign ? 10 : 14)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary.opacity(0.3), lineWidth: 1)
            )
            
            Text(label)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .background(Color(.secondarySystemGroupedBackground))
                .offset(x: 10, y: -6)
        }
    }
}

// Convenience initializer for non-focused fields (no need to specify generic type)
extension LabeledField where FocusValue == Int {
    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        showClearButton: Bool = false,
        keyboardType: UIKeyboardType = .default,
        centerAlign: Bool = false
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.showClearButton = showClearButton
        self.keyboardType = keyboardType
        self.centerAlign = centerAlign
        self.focusBinding = nil
        self.focusValue = nil
    }
}
