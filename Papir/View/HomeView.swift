//
//  HomeView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct HomeView: View {
    @State private var dragOffset: CGFloat = 0
    @State private var currentScreen: Screen = .home
    @State private var lastHapticOffset: CGFloat = 0
    @State private var passedThreshold1: Bool = false
    
    enum Screen {
        case home, history, newInvoice
    }
    
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let threshold1 = screenHeight * 0.15
            let threshold2 = screenHeight * 0.30
            
            ZStack {
                switch currentScreen {
                case .home:
                    homeContent
                        .offset(y: rubberBand(dragOffset))
                        .gesture(dragGesture(threshold1: threshold1, threshold2: threshold2))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                case .history:
                    MyInvoicesView(currentScreen: $currentScreen)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                case .newInvoice:
                    NewInvoiceView(currentScreen: $currentScreen)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private var homeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "DOWN")
                }.padding(.leading, 40).padding(.bottom, 20)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(dash: [5]))
                .frame(height: 1)
                .padding(.horizontal, 6)
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "UP")
                }.padding(.leading, 40).padding(.top, 20)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    
    private func rubberBand(_ value: CGFloat) -> CGFloat {
        value / 2.5
    }
    
    private func dragGesture(threshold1: CGFloat, threshold2: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
                if abs(dragOffset - lastHapticOffset) > 30 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
                    lastHapticOffset = dragOffset
                }
                
                let absolute = abs(dragOffset)
                
                // Threshold 1 medium tap
                if absolute > threshold1 && !passedThreshold1 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    passedThreshold1 = true
                } else if absolute < threshold1 && passedThreshold1 {
                    passedThreshold1 = false
                }
                
                // Threshold 2 immediate commit
                if absolute > threshold2 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    commit()
                }
            }
            .onEnded { value in
                let absolute = abs(value.translation.height)
                if absolute > threshold1 {
                    commit()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                    lastHapticOffset = 0
                    passedThreshold1 = false
                }
            }
    }
    
    private func commit() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if dragOffset < 0 {
                currentScreen = .history
            } else if dragOffset > 0 {
                currentScreen = .newInvoice
            }
            dragOffset = 0
        }
        lastHapticOffset = 0
        passedThreshold1 = false
    }
}

struct ScrollText: View {
    var body: some View {
        Text("Scroll")
            .font(.callout)
            .fontDesign(.monospaced)
            .fontWeight(.black)
            .fontWidth(.standard)
    }
}

struct DirectionText: View {
    let direction : String
    var body: some View {
        Text(direction)
            .font(.largeTitle)
            .fontDesign(.monospaced)
            .fontWeight(.medium)
            .fontWidth(.expanded)
    }
}

#Preview {
    HomeView()
}
