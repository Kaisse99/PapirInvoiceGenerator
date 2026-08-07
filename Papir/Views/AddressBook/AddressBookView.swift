//
//  AddressBookView.swift
//  Everyone she ships to, one card each, searchable by name, phone, city or
//  branch, because she looks people up by whichever of those she remembers
//  first. Reached from the invoice list rather than from the home swipe: it is
//  a thing you consult while writing an invoice, not a fifth destination.
//  Tapping a card opens the same editor that adds one, since with six fields a
//  separate read-only screen would only be a slower way to the same sheet.
//  Sorted by last name so the list reads like a book rather than by when each
//  contact happened to be typed in.
//  Used by: MyInvoicesView.
//

import SwiftUI
import SwiftData

struct AddressBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = AddressBookViewModel()

    @Query(sort: [SortDescriptor(\Contact.lastName), SortDescriptor(\Contact.firstName)])
    private var allContacts: [Contact]

    private var contacts: [Contact] {
        viewModel.filtered(allContacts)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allContacts.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        searchBar

                        if contacts.isEmpty {
                            noResultsState
                                .transition(.opacity)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(contacts) { contact in
                                    Button {
                                        viewModel.edit(contact)
                                    } label: {
                                        ContactCard(contact: contact)
                                    }
                                    .buttonStyle(PressableStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.contactToDelete = contact
                                        } label: {
                                            Label(L.t(.deleteContact), systemImage: "trash")
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
                    .animation(AppAnimation.list, value: contacts.map(\.persistentModelID))
                }
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .tint(Color.primary)
            .sheet(item: $viewModel.editing) { draft in
                ContactEditorSheet(draft: draft) { edited in
                    viewModel.save(edited, context: modelContext)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert(
                L.t(.deleteContactTitle),
                isPresented: Binding(
                    get: { viewModel.contactToDelete != nil },
                    set: { if !$0 { viewModel.contactToDelete = nil } }
                ),
                presenting: viewModel.contactToDelete
            ) { contact in
                Button(L.t(.delete), role: .destructive) {
                    viewModel.delete(contact, context: modelContext)
                }
                Button(L.t(.cancel), role: .cancel) {
                    viewModel.contactToDelete = nil
                }
            } message: { _ in
                Text(L.t(.deleteContactMessage))
            }
            .alert(
                L.t(.couldNotSave),
                isPresented: Binding(
                    get: { viewModel.saveError != nil },
                    set: { if !$0 { viewModel.saveError = nil } }
                )
            ) {
                Button(L.t(.ok), role: .cancel) { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.done))
        }

        ToolbarItem(placement: .principal) {
            Text(L.t(.addressBook))
                .font(.callout)
                .fontDesign(.monospaced)
                .fontWeight(.black)
                .padding(.horizontal, 4)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.addContact()
            } label: {
                Image(systemName: "plus")
                    .toolbarIcon()
                    .foregroundStyle(Color.primary)
            }
            .accessibilityLabel(L.t(.newContact))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(L.t(.searchContacts), text: $viewModel.searchText)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .autocorrectionDisabled()

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
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)).raisedShadow())
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.primary.opacity(0.40), lineWidth: 1)
        )
        .animation(AppAnimation.list, value: viewModel.searchText.isEmpty)
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(L.t(.noContacts))
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)

            Text(L.t(.noContactsHint))
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                viewModel.addContact()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                    Text(L.t(.newContact))
                        .fontDesign(.monospaced)
                }
                .foregroundStyle(Color.primary)
                .padding(.top, 8)
            }
        }
        .padding(.top, 100)
        .padding(.horizontal, 40)
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
