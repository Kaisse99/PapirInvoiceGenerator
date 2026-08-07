//
//  AppBackground.swift
//  The one radial wash every screen sits on. It lives here because each screen
//  used to build its own copy and the create screen had drifted to a different
//  radius and tint, which showed as a visible seam mid-swipe when one screen
//  slid over another.
//  Used by: HomeView, NewInvoiceView, MyInvoicesView, InvoiceDetailView,
//  StockView, StockModelDetailView.
//

import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RadialGradient(
            colors: [
                Color(.systemBackground),
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.gray.opacity(0.25)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 500
        )
        .ignoresSafeArea()
    }
}
