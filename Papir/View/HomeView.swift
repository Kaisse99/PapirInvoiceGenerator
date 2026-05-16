//
//  HomeView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var currentScreen: Screen = .home
    @State private var lastHapticOffset: CGFloat = 0
    @State private var passedThreshold1: Bool = false
    @State private var isCommitting: Bool = false
    @State private var commitDirection: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -1
    
    private var glowColor: Color {
        colorScheme == .dark ? .white : .gray
    }
    
    enum Screen {
        case home, history, newInvoice
    }
    
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let threshold1 = screenHeight * 0.20
            let threshold2 = screenHeight * 0.40
            
            ZStack {
                switch currentScreen {
                case .home:
                    homeContent
                        .offset(y: rubberBand(dragOffset))
                        .gesture(dragGesture(threshold1: threshold1, threshold2: threshold2))
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: commitDirection < 0 ? .top : .bottom).combined(with: .opacity)
                        ))

                case .history:
                    NewInvoiceView(currentScreen: $currentScreen)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .newInvoice:
                    MyInvoicesView(currentScreen: $currentScreen)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .background(
            RadialGradient(
                colors: [
                    Color(.systemBackground),
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.gray.opacity(0.25)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
        )
        .ignoresSafeArea()
        .onChange(of: currentScreen) { _, newValue in
            if newValue == .home {
                dragOffset = 0
                lastHapticOffset = 0
                passedThreshold1 = false
                isCommitting = false
                commitDirection = 0
            }
        }
    }
    
    private var homeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(silverGradient)
                Text("menu")
                    .font(.callout)
                    .fontWidth(.expanded)
                    .fontDesign(.monospaced)
                    .tracking(3)
                    .foregroundStyle(.primary)
                
            }.padding(.top, 40)
                   
                    
            Spacer()
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "UP")
                }
                .padding(.leading, 40).padding(.bottom, 30)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    Rectangle()
                        .frame(height: 1.5)
                        .foregroundStyle(.primary.opacity(0.8))
                        .shadow(color: glowColor.opacity(0.75), radius: 4)
                }
                
                Image(systemName: "paperclip")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
                    .shadow(color: glowColor.opacity(0.4), radius: 6)
                    .shadow(color: glowColor.opacity(0.6), radius: 12)
                ForEach(0..<3) { _ in
                    Rectangle()
                        .frame(height: 1.5)
                        .foregroundStyle(.primary.opacity(0.8))
                        .shadow(color: glowColor.opacity(0.75), radius: 4)
                }
            }
            .padding(.horizontal, 16)
            
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "DOWN")
                    
                    
                }.padding(.leading, 40).padding(.top, 30)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            VStack(spacing: 6) {
                Text("create")
                    .font(.callout)
                    .fontWidth(.expanded)
                    .fontDesign(.monospaced)
                    .tracking(3)
                    .foregroundStyle(.primary)
                Image(systemName: "arrow.down")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(silverGradient)
            }.padding(.bottom, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                shimmerOffset = 1
            }
        }
        .onDisappear {
            withAnimation(.linear(duration: 0)) {
                shimmerOffset = -1
            }
        }
        
    }
    
    private func rubberBand(_ value: CGFloat) -> CGFloat {
        value / 2.5
    }
    
    private func dragGesture(threshold1: CGFloat, threshold2: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isCommitting else { return }
                dragOffset = value.translation.height
                if abs(dragOffset - lastHapticOffset) > 30 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
                    lastHapticOffset = dragOffset
                }
                
                let absolute = abs(dragOffset)
                
                if absolute > threshold1 && !passedThreshold1 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    passedThreshold1 = true
                } else if absolute < threshold1 && passedThreshold1 {
                    passedThreshold1 = false
                }
                
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
    private var silverGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.5),
                Color(white: 0.95),
                Color(white: 0.5),
                Color(white: 0.3),
                Color(white: 0.8)
            ],
            startPoint: UnitPoint(x: shimmerOffset, y: 0),
            endPoint: UnitPoint(x: shimmerOffset + 1, y: 1)
        )
    }
    
    private func commit() {
        guard !isCommitting else { return }
        isCommitting = true
        commitDirection = dragOffset
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if commitDirection < 0 {
                currentScreen = .history
            } else if commitDirection > 0 {
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
            .fontWeight(.bold)
            .foregroundStyle(.primary.opacity(0.9))
    }
}

struct DirectionText: View {
    let direction : String
    var body: some View {
        Text(direction)
            .font(.title)
            .fontDesign(.monospaced)
            .fontWeight(.regular)
            .foregroundStyle(.primary.opacity(0.9))
    }
}


#Preview {
    HomeView()
}
