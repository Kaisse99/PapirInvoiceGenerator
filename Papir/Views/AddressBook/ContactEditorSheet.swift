//
//  ContactEditorSheet.swift
//  Adds a contact and edits one, since the fields are the same either way and
//  only the title and the button change. The sheet owns a draft for as long as
//  it is open and hands it back on save, so backing out leaves the stored
//  contact untouched. Fields are grouped the way she says them out loud: who,
//  then how to reach them, then where the parcel goes. Save is disabled until
//  there is a first or last name, because a contact with only a branch number
//  cannot be found again by anyone.
//  Used by: AddressBookView.
//

import SwiftUI

struct ContactEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (ContactDraft) -> Void

    @State private var form: ContactDraft
    @FocusState private var focused: Field?

    private enum Field: Hashable, CaseIterable {
        case firstName, lastName, phone, city, branchOne, branchTwo
    }

    private var canGoBack: Bool {
        guard let focused, let index = Field.allCases.firstIndex(of: focused) else { return false }
        return index > 0
    }

    private var canGoForward: Bool {
        guard let focused, let index = Field.allCases.firstIndex(of: focused) else { return false }
        return index < Field.allCases.count - 1
    }

    private func step(_ offset: Int) {
        guard let focused, let index = Field.allCases.firstIndex(of: focused) else { return }
        let next = index + offset
        guard Field.allCases.indices.contains(next) else { return }
        self.focused = Field.allCases[next]
    }

    init(draft: ContactDraft, onSave: @escaping (ContactDraft) -> Void) {
        self._form = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    section(L.t(.whoCaps)) {
                        field(L.t(.firstName), text: $form.firstName, focus: .firstName, limit: 24)
                        field(L.t(.lastName), text: $form.lastName, focus: .lastName, limit: 24)
                    }

                    section(L.t(.reachThemCaps)) {
                        field(
                            L.t(.phone),
                            text: $form.phone,
                            focus: .phone,
                            limit: 20,
                            keyboard: .phonePad
                        )
                    }

                    section(L.t(.whereToCaps)) {
                        field(L.t(.city), text: $form.city, focus: .city, limit: 30)
                        field(L.t(.novaPoshtaOne), text: $form.branchOne, focus: .branchOne, limit: 40)
                        field(L.t(.novaPoshtaTwo), text: $form.branchTwo, focus: .branchTwo, limit: 40)
                    }

                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .readableWidth()
            }
            .dismissKeyboardOnTap()
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .toolbarIcon()
                            .foregroundStyle(Color.primary)
                    }
                    .accessibilityLabel(L.t(.cancel))
                }

                ToolbarItem(placement: .principal) {
                    Text(L.t(form.isEditing ? .editContact : .newContact))
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.black)
                        .padding(.horizontal, 4)
                }

                KeyboardStepBar(
                    canGoBack: canGoBack,
                    canGoForward: canGoForward,
                    onBack: { step(-1) },
                    onForward: { step(1) },
                    onDone: { focused = nil }
                )
            }
            .tint(Color.primary)
        }
    }

    private var cardBackground: Color {
        Color(.systemGray6)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.caption2)
                .fontDesign(.monospaced)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBackground)
                .stroke(.primary.opacity(0.30), lineWidth: 0.8)
        )
        .raisedShadow()
    }

    private func field(
        _ label: String,
        text: Binding<String>,
        focus: Field,
        limit: Int,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        LabeledField(
            label: label,
            text: text,
            showClearButton: true,
            keyboardType: keyboard,
            backgroundFill: cardBackground,
            focusBinding: $focused,
            focusValue: focus
        )
        .limitInput(text, to: limit)
    }

    private var saveButton: some View {
        Button {
            Haptics.medium()
            onSave(form)
            dismiss()
        } label: {
            Text(L.t(form.isEditing ? .update : .add))
                .fontDesign(.monospaced)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(Color(.systemBackground))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primary.opacity(form.hasName ? 0.9 : 0.3))
                )
        }
        .buttonStyle(.plain)
        .disabled(!form.hasName)
        .padding(.top, 6)
    }
}
