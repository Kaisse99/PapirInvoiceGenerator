//
//  View+Extensions.swift
//  The small shared pieces every screen reaches for: text-field modifiers that
//  clamp length and strip non-digits as the user types, tap-anywhere keyboard
//  dismissal, the Haptics vocabulary, and AppAnimation, the curves the whole
//  app animates with, kept here so motion stays consistent. AppAnimation.list
//  is the one collections re-flow with when their contents change, and
//  toolbarIcon is the single size every bar glyph is drawn at, because they
//  otherwise inherit whatever weight their symbol happens to carry.
//  Used by: every view and view model in the app.
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

    func decimalOnly(_ text: Binding<String>) -> some View {
        self.onChange(of: text.wrappedValue) { _, newValue in
            var seenDot = false
            let filtered = newValue.reduce(into: "") { result, character in
                if character.isNumber {
                    result.append(character)
                } else if character == "." && !seenDot {
                    result.append(character)
                    seenDot = true
                }
            }
            if filtered != newValue {
                text.wrappedValue = filtered
            }
        }
    }
}

extension View {
    @ViewBuilder
    func sharedFocus<Value: Hashable>(_ binding: FocusState<Value?>.Binding?, equals value: Value?) -> some View {
        if let binding, let value {
            self.focused(binding, equals: value)
        } else {
            self
        }
    }

    func toolbarIcon() -> some View {
        font(.system(size: 16, weight: .medium))
    }

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
    static let list = Animation.spring(response: 0.28, dampingFraction: 0.85)
}
