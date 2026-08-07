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
//  it. The buttons sit where the system puts them: padding them off the keys
//  moved the glyphs without moving the bar itself, which read worse than the
//  thing it was meant to fix. Done is the keyboard glyph rather than the word,
//  which needed no translating and left the bar quieter.
//  Used by: ContactEditorSheet. The invoice screens went without one: a
//  keyboard toolbar declared inside a card inside a scroll view never appeared
//  there, and a row already jumps focus by itself once a number field fills.
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
                    .font(.scaled(size: 16, weight: .semibold))
            }
            .disabled(!canGoBack)

            Button {
                Haptics.light()
                onForward()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.scaled(size: 16, weight: .semibold))
            }
            .disabled(!canGoForward)

            Spacer()

            Button {
                Haptics.light()
                onDone()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.scaled(size: 16, weight: .semibold))
            }
            .accessibilityLabel(L.t(.done))
        }
    }
}
