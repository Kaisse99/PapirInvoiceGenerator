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
    var isError: Bool = false
    var errorMessage: String? = nil
    var isDisabled: Bool = false
    var backgroundFill: Color = Color(.secondarySystemGroupedBackground)
    
    var focusBinding: FocusState<FocusValue?>.Binding?
    var focusValue: FocusValue?
    
    @FocusState private var isFocused: Bool
    
    private var borderColor: Color {
        if isError { return .red }
        if isFocused { return .blue.opacity(0.9) }
        return .primary.opacity(0.55)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                HStack(spacing: 10) {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .keyboardType(keyboardType)
                        .multilineTextAlignment(centerAlign ? .center : .leading)
                        .foregroundStyle(.primary)
                        .disabled(isDisabled)
                        .focused($isFocused)
                        .frame(maxWidth: .infinity, alignment: centerAlign ? .center : .leading)
                    
                    if showClearButton && !text.isEmpty && !isDisabled {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(backgroundFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .onTapGesture { isFocused = true }
                
                Text(label)
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(isError ? .red : (isFocused ? Color.accentColor : .secondary))
                    .padding(.horizontal, 6)
                    .background(backgroundFill)
                    .offset(x: 14, y: -8)
            }
            
            if let errorMessage, isError {
                Text(errorMessage)
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.red)
                    .padding(.leading, 6)
            }
        }
        .opacity(isDisabled ? 0.5 : 1)
        .animation(AppAnimation.fast, value: isFocused)
        .animation(AppAnimation.fast, value: isError)
    }
}

extension LabeledField where FocusValue == Int {
    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        showClearButton: Bool = false,
        keyboardType: UIKeyboardType = .default,
        centerAlign: Bool = false,
        isError: Bool = false,
        errorMessage: String? = nil,
        isDisabled: Bool = false,
        backgroundFill: Color = Color(.secondarySystemGroupedBackground)
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.showClearButton = showClearButton
        self.keyboardType = keyboardType
        self.centerAlign = centerAlign
        self.isError = isError
        self.errorMessage = errorMessage
        self.isDisabled = isDisabled
        self.backgroundFill = backgroundFill
        self.focusBinding = nil
        self.focusValue = nil
    }
}
