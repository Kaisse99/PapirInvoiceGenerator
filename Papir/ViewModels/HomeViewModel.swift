//
//  HomeViewModel.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-22.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum Screen {
        case home, create, menu
    }
    
    @Published var currentScreen: Screen = .home
    @Published var dragOffset: CGFloat = 0
    @Published var shimmerOffset: CGFloat = -1
    @Published var deepLinkInvoice: Invoice? = nil
    
    private var lastHapticOffset: CGFloat = 0
    private var passedThreshold1 = false
    private var isCommitting = false
    private(set) var commitDirection: CGFloat = 0
    
    func rubberBand(_ value: CGFloat) -> CGFloat {
        value / 2.5
    }
    
    func handleDragChange(_ translationHeight: CGFloat, threshold1: CGFloat, threshold2: CGFloat) {
        guard !isCommitting else { return }
        dragOffset = translationHeight
        
        if abs(dragOffset - lastHapticOffset) > 30 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
            lastHapticOffset = dragOffset
        }
        
        let absolute = abs(dragOffset)
        
        if absolute > threshold1 && !passedThreshold1 {
            Haptics.medium()
            passedThreshold1 = true
        } else if absolute < threshold1 && passedThreshold1 {
            passedThreshold1 = false
        }
        
        if absolute > threshold2 {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            commit()
        }
    }
    
    func handleDragEnd(_ translationHeight: CGFloat, threshold1: CGFloat) {
        let absolute = abs(translationHeight)
        if absolute > threshold1 {
            commit()
        } else {
            withAnimation(AppAnimation.smooth) {
                dragOffset = 0
            }
            lastHapticOffset = 0
            passedThreshold1 = false
        }
    }
    
    func commit() {
        guard !isCommitting else { return }
        isCommitting = true
        commitDirection = dragOffset
        
        withAnimation(AppAnimation.smooth) {
            if commitDirection < 0 {
                currentScreen = .create
            } else if commitDirection > 0 {
                currentScreen = .menu
            }
            dragOffset = 0
        }
        lastHapticOffset = 0
        passedThreshold1 = false
    }
    
    func resetOnReturnHome() {
        dragOffset = 0
        lastHapticOffset = 0
        passedThreshold1 = false
        isCommitting = false
        commitDirection = 0
    }
    
    func goHome() {
        Haptics.light()
        withAnimation(AppAnimation.smooth) {
            currentScreen = .home
        }
    }
}
