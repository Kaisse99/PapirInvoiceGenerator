//
//  PaperclipDivider.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-20.
//
import SwiftUI

struct PaperclipDivider: View {
    @Environment(\.colorScheme) var colorScheme
    var iconSize: CGFloat = 50
    
    private var glowColor: Color {
        colorScheme == .dark ? .white : .gray
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(.primary.opacity(0.8))
                .shadow(color: glowColor.opacity(0.75), radius: 4)
            
            Image("smallIcon")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(.primary)
            
            Rectangle()
                .frame(height: 1.5)
                .foregroundStyle(.primary.opacity(0.8))
                .shadow(color: glowColor.opacity(0.75), radius: 4)
        }
        .padding(.horizontal, 16)
    }
}
