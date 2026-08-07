//
//  View+Extensions.swift
//  The small shared pieces every screen reaches for: text-field modifiers that
//  clamp length and strip non-digits as the user types, tap-anywhere keyboard
//  dismissal, the Haptics vocabulary, and AppAnimation, the curves the whole
//  app animates with, kept here so motion stays consistent. AppAnimation.list
//  is the one collections re-flow with when their contents change, and
//  toolbarIcon is the single size every bar glyph is drawn at, because they
//  otherwise inherit whatever weight their symbol happens to carry.
//  raisedShadow is the one lift every card, row and bar in the app sits on. It
//  is two layers because one cannot do both jobs: a black one that shows where
//  a card overlaps something pale, and a faint primary one that reads as a
//  glow on a dark screen and as a second soft shadow on a light one.
//  It goes on the shape a card is filled with, never on the card as a whole. A
//  shadow applied to a composed view is cast by everything drawn inside it, so
//  hanging it on the card gave every field box and every notched label its own
//  little halo, which read as grubby rather than as raised.
//  Font.scaled is how every fixed-size font in the app honours the system
//  text size: the point size the design was tuned at, run through
//  UIFontMetrics so a user who set larger text actually gets it. The
//  semantic styles scale on their own; this exists for the sizes chosen by
//  eye, and at the default setting it returns them untouched.
//  readableWidth is what keeps the app from turning into a wall on an iPad:
//  every screen is a single column of cards written for a phone, so past a
//  point the column stops growing and centres instead of stretching a row of
//  four numbers across ten inches.
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
        font(.scaled(size: 16, weight: .medium))
    }

    func raisedShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
            .shadow(color: .primary.opacity(0.06), radius: 6, y: 2)
    }

    func readableWidth(_ limit: CGFloat = 640) -> some View {
        frame(maxWidth: limit)
            .frame(maxWidth: .infinity)
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

extension Font {
    static func scaled(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: design)
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
