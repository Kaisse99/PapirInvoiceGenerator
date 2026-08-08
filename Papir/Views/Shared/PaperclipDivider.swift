//
//  PaperclipDivider.swift
//  A section rule with the paperclip mark set into the middle of it, glowing
//  white on dark and gray on light. The same divider the home screen draws
//  around its icon.
//  Used by: NewInvoiceView, InvoiceDetailView.
//

import SwiftUI

struct PaperclipDivider: View {
    @Environment(\.colorScheme) var colorScheme
    var iconSize: CGFloat = 35
    
    private var glowColor: Color {
        colorScheme == .dark ? .white : .gray
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(.primary.opacity(0.8))
                .shadow(color: glowColor.opacity(0.75), radius: 4)
            
            AppMark(size: iconSize)
            
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(.primary.opacity(0.8))
                .shadow(color: glowColor.opacity(0.75), radius: 4)
        }
        .padding(.horizontal, 16)
    }
}
