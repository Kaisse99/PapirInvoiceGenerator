//
//  HomeViewModel.swift
//  Drives the swipe on the home screen: which of the four screens is showing,
//  how far the drag has travelled, and the haptics along the way. The axis is
//  decided once, the first time a drag passes a few points, and then held for
//  the rest of that gesture. Recomputing it every frame meant a finger that
//  moved down and then sideways silently changed destination mid-drag, so once
//  a direction is claimed the only way out is back to the middle. On the
//  vertical axis there are two thresholds: past the first, letting go commits;
//  past the second, it commits under the finger. Horizontal has one, and each
//  direction carries the screen the arrow on that side points to: left opens
//  stock, right is where statistics will go and until it exists that drag
//  springs back with a warning rather than landing somewhere it did not
//  promise. isCommitting keeps a drag that is already
//  committing from firing a second time. Also holds deepLinkInvoice, the
//  invoice a save wants the list to open once it appears.
//  Used by: HomeView; the Screen case is passed around by NewInvoiceView,
//  MyInvoicesView, StockView, and EditInvoiceSheet.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum Screen {
        case home, create, menu, stock
    }

    struct DragLimits {
        let verticalCommit: CGFloat
        let verticalInstant: CGFloat
        let horizontalCommit: CGFloat
    }

    private enum Axis {
        case vertical, horizontal
    }

    @Published var currentScreen: Screen = .home
    @Published var dragOffset: CGSize = .zero
    @Published var shimmerOffset: CGFloat = -1
    @Published var deepLinkInvoice: Invoice? = nil

    private var lastHapticOffset: CGFloat = 0
    private var passedThreshold = false
    private var isCommitting = false
    private var lockedAxis: Axis? = nil

    private static let axisLockDistance: CGFloat = 8

    var displayOffset: CGSize {
        switch lockedAxis ?? .vertical {
        case .vertical:   return CGSize(width: 0, height: rubberBand(dragOffset.height))
        case .horizontal: return CGSize(width: rubberBand(dragOffset.width), height: 0)
        }
    }

    func rubberBand(_ value: CGFloat) -> CGFloat {
        value / 2.5
    }

    func handleDragChange(_ translation: CGSize, limits: DragLimits) {
        guard !isCommitting else { return }
        dragOffset = translation

        if lockedAxis == nil {
            let reach = max(abs(translation.width), abs(translation.height))
            guard reach >= Self.axisLockDistance else { return }
            lockedAxis = abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
        }

        let travelled = travel(of: translation)

        if abs(travelled - lastHapticOffset) > 30 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
            lastHapticOffset = travelled
        }

        let distance = abs(travelled)
        let commit = commitThreshold(for: translation, limits: limits)

        if distance > commit && !passedThreshold {
            Haptics.medium()
            passedThreshold = true
        } else if distance < commit && passedThreshold {
            passedThreshold = false
        }

        if lockedAxis == .vertical && distance > limits.verticalInstant {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            commitScreen(for: translation)
        }
    }

    func handleDragEnd(_ translation: CGSize, limits: DragLimits) {
        let distance = abs(travel(of: translation))

        if lockedAxis != nil && distance > commitThreshold(for: translation, limits: limits) {
            commitScreen(for: translation)
        } else {
            settle()
        }
    }

    func resetOnReturnHome() {
        dragOffset = .zero
        lastHapticOffset = 0
        passedThreshold = false
        isCommitting = false
        lockedAxis = nil
    }

    func goHome() {
        Haptics.light()
        withAnimation(AppAnimation.smooth) {
            currentScreen = .home
        }
    }

    private func commitScreen(for translation: CGSize) {
        guard !isCommitting, let axis = lockedAxis else { return }

        let destination: Screen?
        switch axis {
        case .horizontal:
            destination = translation.width < 0 ? .stock : nil
        case .vertical:
            destination = translation.height < 0 ? .create : .menu
        }

        guard let destination else {
            Haptics.warning()
            settle()
            return
        }

        isCommitting = true

        withAnimation(AppAnimation.smooth) {
            currentScreen = destination
            dragOffset = .zero
        }
        lastHapticOffset = 0
        passedThreshold = false
        lockedAxis = nil
    }

    private func settle() {
        withAnimation(AppAnimation.smooth) {
            dragOffset = .zero
        }
        lastHapticOffset = 0
        passedThreshold = false
        lockedAxis = nil
    }

    private func travel(of translation: CGSize) -> CGFloat {
        lockedAxis == .horizontal ? translation.width : translation.height
    }

    private func commitThreshold(for translation: CGSize, limits: DragLimits) -> CGFloat {
        lockedAxis == .horizontal ? limits.horizontalCommit : limits.verticalCommit
    }
}
