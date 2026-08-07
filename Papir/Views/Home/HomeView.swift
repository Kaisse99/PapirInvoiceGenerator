//
//  HomeView.swift
//  The root screen and the app's only navigation: swipe up for the new-invoice
//  screen, down for the invoice list, sideways for stock, and all of them come
//  back here. They live in one ZStack driven by HomeViewModel's screen case,
//  so a swipe reads as one sheet of paper sliding rather than a push. The
//  arrows shimmer through a gradient that animates while this screen is on
//  top, and the gear sits in the corner where it is reachable from anywhere
//  without taking a place in the swipe. Keyed on the stored language, so
//  switching it in settings rebuilds every screen underneath in one go.
//  Used by: PapirApp.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings = false

    @AppStorage(AppSettings.languageKey)
    private var languageRaw: String = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .english
    }

    private var glowColor: Color {
        colorScheme == .dark ? .white : .gray
    }

    var body: some View {
        GeometryReader { geo in
            let limits = HomeViewModel.DragLimits(
                verticalCommit: geo.size.height * 0.20,
                verticalInstant: geo.size.height * 0.40,
                horizontalCommit: geo.size.width * 0.28
            )

            ZStack {
                switch viewModel.currentScreen {
                case .home:
                    homeContent
                        .offset(x: viewModel.displayOffset.width, y: viewModel.displayOffset.height)
                        .gesture(dragGesture(limits: limits))
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

                case .stock:
                    StockView(currentScreen: $viewModel.currentScreen)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(AppAnimation.smooth, value: viewModel.currentScreen)
        }
        .id(languageRaw)
        .background(AppBackground())
        .ignoresSafeArea()
        .onChange(of: viewModel.currentScreen) { _, newValue in
            if newValue == .home {
                viewModel.resetOnReturnHome()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private var homeContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 6) {
                    Text(L.t(.menu, language))
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

                stockHint
                    .padding(.top, 14)

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
                    Text(L.t(.create, language))
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
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .toolbarIcon()
                            .foregroundStyle(Color.primary)
                    }
                    .accessibilityLabel(L.t(.settings, language))
                }
            }
        }
        .tint(Color.primary)
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

    private var stockHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left")
                .font(.system(size: 11, weight: .regular))
            Text(L.t(.stock, language))
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(3)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .regular))
        }
        .foregroundStyle(.primary.opacity(0.55))
        .frame(maxWidth: .infinity)
    }

    private func dragGesture(limits: HomeViewModel.DragLimits) -> some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.handleDragChange(value.translation, limits: limits)
            }
            .onEnded { value in
                viewModel.handleDragEnd(value.translation, limits: limits)
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
