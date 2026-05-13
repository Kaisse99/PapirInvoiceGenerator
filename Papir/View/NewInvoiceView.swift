//
//  NewInvoiceView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct NewInvoiceView: View {
    @Binding var currentScreen: HomeView.Screen
    var body: some View {
        VStack(spacing: 20) {
            Text("New Invoice")
                .font(.largeTitle)
                .fontDesign(.monospaced)
            
            Button("Back") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentScreen = .home
                                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


