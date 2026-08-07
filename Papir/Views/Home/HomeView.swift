//
//  HomeView.swift
//  The root screen and the app's only navigation: swipe up for the new-invoice
//  screen, down for the invoice list, left for stock, and all of them come
//  back here. They live in one ZStack driven by HomeViewModel's screen case,
//  so a swipe reads as one sheet of paper sliding rather than a push. Every
//  direction is drawn the same way, its name in one type size above an arrow
//  pointing the way the finger goes, so the four read as one set. The
//  horizontal pair are three stacked chevrons, all the same weight, which say
//  swipe more plainly than the rules that used to run to the edges; they were
//  drawn fading back from the leading one at first, which read as three
//  mismatched arrows rather than as one moving in a direction. The name sits
//  above them rather than beside them because at the same
//  size as menu and create it would not otherwise leave the mark room to stay
//  centred. The whole stack sits slightly
//  above centre, since an optically centred column reads low. The arrows and a
//  glint across the mark share one gradient that animates while this screen is
//  on top, and the gear sits in the corner
//  where it is reachable from anywhere without taking a place in the swipe.
//  Keyed on the settings that every other screen reads as plain statics rather
//  than as bindings, the language, the currency and the low stock number, so
//  changing any of them in settings rebuilds the whole tree underneath in one
//  go instead of waiting for each screen to happen to redraw.
//  Used by: PapirApp.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings = false

    @AppStorage(AppSettings.languageKey)
    private var languageRaw: String = AppLanguage.english.rawValue

    @AppStorage(AppSettings.currencyKey)
    private var currencyRaw: String = AppCurrency.hryvnia.rawValue

    @AppStorage(AppSettings.lowStockKey)
    private var lowStockRaw: Int = AppSettings.fallbackLowStock

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .english
    }

    private var settingsKey: String {
        "\(languageRaw)-\(currencyRaw)-\(lowStockRaw)"
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

                case .statistics:
                    StatisticsView(currentScreen: $viewModel.currentScreen)
                        .transition(.move(edge: .leading))
                }
            }
            .animation(AppAnimation.smooth, value: viewModel.currentScreen)
        }
        .id(settingsKey)
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

                HStack(spacing: 0) {
                    directionArrow(
                        title: L.t(.statistics, language),
                        pointsLeft: false,
                        available: true
                    )
                    .frame(maxWidth: .infinity)

                    centerMark

                    directionArrow(
                        title: L.t(.stock, language),
                        pointsLeft: true,
                        available: true
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)

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
            .offset(y: -55)
            .readableWidth(560)
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

    private var centerMark: some View {
        let mark = Image("smallIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)

        return mark
            .overlay {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.16), .clear],
                    startPoint: UnitPoint(x: viewModel.shimmerOffset, y: 0.3),
                    endPoint: UnitPoint(x: viewModel.shimmerOffset + 0.3, y: 0.7)
                )
                .blendMode(.plusLighter)
                .mask(mark)
            }
            .compositingGroup()
    }

    private func directionArrow(title: String, pointsLeft: Bool, available: Bool) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.callout)
                .fontWidth(.expanded)
                .fontDesign(.monospaced)
                .tracking(3)
                .foregroundStyle(.primary.opacity(available ? 1 : 0.3))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: -7) {
                ForEach(0..<3, id: \.self) { _ in
                    chevron(pointsLeft: pointsLeft, available: available)
                }
            }
        }
        .offset(y: -8)
    }

    private func chevron(pointsLeft: Bool, available: Bool) -> some View {
        let glyph = Image(systemName: pointsLeft ? "chevron.left" : "chevron.right")
            .font(.scaled(size: 28, weight: .light))

        return Group {
            if available {
                glyph.foregroundStyle(silverGradient)
            } else {
                glyph.foregroundStyle(.primary.opacity(0.22))
            }
        }
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
