//
//  StockView.swift
//  The stock list: every model she holds, searchable by code or by any color
//  under it, with a card each. Adding a model asks for the code and, if it is
//  already agreed, the price per piece; a model with no colors and no price is
//  a normal state, the box exists before anything is counted into it or sold
//  out of it. Owns the @Query and the navigation stack; tapping a
//  card opens StockModelDetailView. Rows animate on the identity of what is
//  showing, the same way the invoice list does.
//  Used by: HomeView.
//

import SwiftUI
import SwiftData

struct StockView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = StockViewModel()
    @Binding var currentScreen: HomeViewModel.Screen
    @State private var showHistory = false

    @Query(sort: \StockModel.code)
    private var allModels: [StockModel]

    private var models: [StockModel] {
        viewModel.filtered(allModels)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allModels.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        searchBar

                        if models.isEmpty {
                            noResultsState
                                .transition(.opacity)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(models) { model in
                                    NavigationLink(value: model) {
                                        StockModelCard(model: model)
                                    }
                                    .buttonStyle(PressableStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.modelToDelete = model
                                        } label: {
                                            Label(L.t(.deleteModel), systemImage: "trash")
                                        }
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                    .padding(.top, 12)
                    .readableWidth()
                    .animation(AppAnimation.list, value: models.map(\.code))
                }
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(for: StockModel.self) { model in
                StockModelDetailView(model: model, viewModel: viewModel)
            }
            .tint(Color.primary)
            .fullScreenCover(isPresented: $showHistory) {
                MovementLogView()
            }
            .sheet(isPresented: $viewModel.showAddModel) {
                addModelSheet
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
            }
            .alert(
                L.t(.deleteModelTitle),
                isPresented: Binding(
                    get: { viewModel.modelToDelete != nil },
                    set: { if !$0 { viewModel.modelToDelete = nil } }
                ),
                presenting: viewModel.modelToDelete
            ) { model in
                Button(L.t(.delete), role: .destructive) {
                    viewModel.delete(model, context: modelContext)
                }
                Button(L.t(.cancel), role: .cancel) {
                    viewModel.modelToDelete = nil
                }
            } message: { model in
                Text("\(model.code). \(L.t(.deleteModelMessage))")
            }
        }
        .alert(
            viewModel.notice?.title ?? "",
            isPresented: Binding(
                get: { viewModel.notice != nil },
                set: { if !$0 { viewModel.notice = nil } }
            )
        ) {
            Button(L.t(.ok), role: .cancel) { viewModel.notice = nil }
        } message: {
            Text(viewModel.notice?.message ?? "")
        }
    }


    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Haptics.light()
                withAnimation(AppAnimation.smooth) {
                    currentScreen = .home
                }
            } label: {
                Image(systemName: "house")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.home))
        }

        ToolbarItem(placement: .principal) {
            Text(L.t(.stockTitle))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                Haptics.light()
                showHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.history))

            Button {
                Haptics.light()
                viewModel.newModelCode = ""
                viewModel.newModelPrice = ""
                viewModel.addModelError = nil
                viewModel.showAddModel = true
            } label: {
                Image(systemName: "plus")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.addModel))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(L.t(.searchStock), text: $viewModel.searchText)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(AppAnimation.list) { viewModel.searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.primary.opacity(0.40), lineWidth: 1)
        )
        .animation(AppAnimation.list, value: viewModel.searchText.isEmpty)
        .raisedShadow()
        .padding(.horizontal, 20)
    }

    private var addModelSheet: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(L.t(.newModel))
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                Text(L.t(.modelCodeHint))
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            TextField(L.t(.modelCode), text: $viewModel.newModelCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .limitInput($viewModel.newModelCode, to: 30)
                .frame(height: 64)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.addModelError == nil ? Color.primary.opacity(0.3) : Color.red, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .onChange(of: viewModel.newModelCode) { _, _ in
                    viewModel.addModelError = nil
                }

            HStack(spacing: 10) {
                TextField(L.t(.pricePerPiece), text: $viewModel.newModelPrice)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .keyboardType(.decimalPad)
                    .decimalOnly($viewModel.newModelPrice)
                    .limitInput($viewModel.newModelPrice, to: 7)

                Text(AppSettings.currencySymbol)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary.opacity(0.25), lineWidth: 1))
            .padding(.horizontal, 20)

            if let error = viewModel.addModelError {
                Text(error)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                viewModel.addModel(existing: allModels, context: modelContext)
            } label: {
                Text(L.t(.add))
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color(.systemBackground))
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .dismissKeyboardOnTap()
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L.t(.noModels))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)

            Text(L.t(.noModelsHint))
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L.t(.noMatches))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StockView(currentScreen: .constant(.stock))
        .modelContainer(for: [StockModel.self, StockLine.self], inMemory: true)
}
