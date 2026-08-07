//
//  PressableStyle.swift
//  The press feedback every tappable card in the app uses: a small scale down
//  while the finger is on it, on the app's fast curve. It lives here rather
//  than beside the invoice list it was first written for, because the stock
//  list and the address book reach for it too and a shared control hidden at
//  the bottom of one screen's file is one nobody finds twice.
//  Used by: MyInvoicesView, StockView, AddressBookView.
//

import SwiftUI

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}
