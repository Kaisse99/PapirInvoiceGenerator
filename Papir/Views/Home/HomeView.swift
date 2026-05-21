//
//  HomeView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HomeViewModel()
    
    private var glowColor: Color {
        colorScheme == .dark ? .white : .gray
    }
    
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let threshold1 = screenHeight * 0.20
            let threshold2 = screenHeight * 0.40
            
            ZStack {
                switch viewModel.currentScreen {
                case .home:
                    homeContent
                        .offset(y: viewModel.rubberBand(viewModel.dragOffset))
                        .gesture(dragGesture(threshold1: threshold1, threshold2: threshold2))
                        .transition(.opacity)
                    
                case .create:
                    NewInvoiceView(
                        viewModel: NewInvoiceViewModel(),
                        currentScreen: $viewModel.currentScreen,
                        deepLinkInvoice: $viewModel.deepLinkInvoice
                    )
                    .transition(.move(edge: .bottom))
                    
                case .menu:
                    MyInvoicesView(
                        currentScreen: $viewModel.currentScreen,
                        deepLinkInvoice: $viewModel.deepLinkInvoice
                    )
                    .transition(.move(edge: .top))
                }
            }
            .animation(AppAnimation.smooth, value: viewModel.currentScreen)
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
        .onChange(of: viewModel.currentScreen) { _, newValue in
            if newValue == .home {
                viewModel.resetOnReturnHome()
            }
        }
    }
    
    private var homeContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 6) {
                Text("menu")
                    .font(.callout)
                    .fontWidth(.expanded)
                    .fontDesign(.monospaced)
                    .tracking(3)
                    .foregroundStyle(.primary)
                Image(systemName: "hand.draw")
                    .font(.title)
                    .fontWeight(.light)
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(140))
                    .padding(.trailing, 10)
                Image(systemName: "arrow.down")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(silverGradient)
            }
            .padding(.top, 40)
            
            Spacer()
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "DOWN")
                }
                .padding(.leading, 40)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundStyle(.primary.opacity(0.8))
                    .shadow(color: glowColor.opacity(0.75), radius: 4)
                
                Image("smallIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.primary)
                
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundStyle(.primary.opacity(0.8))
                    .shadow(color: glowColor.opacity(0.75), radius: 4)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    ScrollText()
                    DirectionText(direction: "UP")
                }
                .padding(.leading, 40)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            VStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(silverGradient)
                Image(systemName: "hand.draw")
                    .font(.title)
                    .fontWeight(.light)
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(-40))
                    .padding(.leading, 10)
                Text("create")
                    .font(.callout)
                    .fontWidth(.expanded)
                    .fontDesign(.monospaced)
                    .tracking(3)
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                viewModel.shimmerOffset = 1
            }
        }
        .onDisappear {
            viewModel.shimmerOffset = -1
        }
    }
    
    private func dragGesture(threshold1: CGFloat, threshold2: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.handleDragChange(
                    value.translation.height,
                    threshold1: threshold1,
                    threshold2: threshold2
                )
            }
            .onEnded { value in
                viewModel.handleDragEnd(value.translation.height, threshold1: threshold1)
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
            startPoint: UnitPoint(x: viewModel.shimmerOffset, y: 0),
            endPoint: UnitPoint(x: viewModel.shimmerOffset + 1, y: 1)
        )
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
    let direction: String
    
    var body: some View {
        Text(direction)
            .font(.title)
            .fontDesign(.monospaced)
            .fontWeight(.regular)
            .foregroundStyle(.primary.opacity(0.9))
    }
}

