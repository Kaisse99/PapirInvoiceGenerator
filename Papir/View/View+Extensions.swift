//
//  View+Extensions.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-15.
//

import SwiftUI

extension View {
    func limitInput(_ text: Binding<String>, to limit: Int) -> some View {
        self.onChange(of: text.wrappedValue) { _, newValue in
            if newValue.count > limit {
                text.wrappedValue = String(newValue.prefix(limit))
            }
        }
    }
}
