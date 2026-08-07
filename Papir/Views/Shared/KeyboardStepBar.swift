//
//  KeyboardStepBar.swift
//  The bar that sits above the keyboard on any form with more than one field:
//  up and down to step between them, and Done to put the keyboard away. It
//  exists because half the fields in this app are number pads, which have no
//  return key at all, so without it the only way out of a phone number or a
//  price is to tap somewhere else on the screen and hope.
//  It is ToolbarContent rather than a view so a caller drops it straight into
//  its own .toolbar alongside the title, and it decides nothing about which
//  field comes next; the caller owns the order because only the caller knows
//  it. Every button carries its own bottom padding, because the bar puts its
//  contents flush against the top of the keys otherwise and a round tap target
//  touching the key rows reads as a mistake. The padding sits on the button
//  and not on the glyph inside it: on the label it grows the round background
//  downwards instead, which leaves the glyph riding high in its own circle. Done is the keyboard glyph rather
//  than the word, which needed no translating and left the bar quieter.
//  Used by: ContactEditorSheet, InvoiceRowCard, NewInvoiceView.
//

import SwiftUI

struct KeyboardStepBar: ToolbarContent {
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void
    let onDone: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Button {
                Haptics.light()
                onBack()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
            }
            .disabled(!canGoBack)
            .padding(.bottom, 8)

            Button {
                Haptics.light()
                onForward()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
            }
            .disabled(!canGoForward)
            .padding(.bottom, 8)

            Spacer()

            Button {
                Haptics.light()
                onDone()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel(L.t(.done))
            .padding(.bottom, 8)
        }
    }
}
