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
    
    func digitsOnly(_ text: Binding<String>) -> some View {
        self.onChange(of: text.wrappedValue) { _, newValue in
            let filtered = newValue.filter { $0.isNumber }
            if filtered != newValue {
                text.wrappedValue = filtered
            }
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

enum AppAnimation {
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let smooth = Animation.spring(response: 0.38, dampingFraction: 0.85)
    static let fast = Animation.easeOut(duration: 0.15)
    static let snappy = Animation.easeInOut(duration: 0.18)
}
