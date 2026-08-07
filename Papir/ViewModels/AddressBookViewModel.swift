//
//  AddressBookViewModel.swift
//  Everything the address book does to the store: search across name, phone,
//  city and both branches, then write a contact or delete one. Editing runs
//  through ContactDraft, a plain-string copy of a contact that the sheet owns
//  while it is open, so a half-typed phone number is never a half-written
//  model; committing a draft either updates the contact it came from or
//  inserts a new one.
//  A contact needs a first or last name and nothing else, since she often has
//  a name and a branch long before she has a phone number.
//  Holds no contacts of its own, the view owns the @Query and hands them in.
//  Used by: AddressBookView, ContactEditorSheet.
//

import SwiftUI
import os
import SwiftData
import Combine

struct ContactDraft: Identifiable {
    let id = UUID()
    var contact: Contact? = nil
    var firstName: String = ""
    var lastName: String = ""
    var phone: String = ""
    var city: String = ""
    var branchOne: String = ""
    var branchTwo: String = ""

    var isEditing: Bool { contact != nil }

    var hasName: Bool {
        !(firstName + lastName).trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(contact: Contact? = nil) {
        self.contact = contact
        guard let contact else { return }
        firstName = contact.firstName
        lastName = contact.lastName
        phone = contact.phone
        city = contact.city
        branchOne = contact.branchOne
        branchTwo = contact.branchTwo
    }
}

@MainActor
final class AddressBookViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var editing: ContactDraft? = nil
    @Published var contactToDelete: Contact? = nil
    @Published var saveError: String? = nil

    func filtered(_ contacts: [Contact]) -> [Contact] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.matches(query) }
    }

    func addContact() {
        Haptics.light()
        editing = ContactDraft()
    }

    func edit(_ contact: Contact) {
        Haptics.light()
        editing = ContactDraft(contact: contact)
    }

    func save(_ draft: ContactDraft, context: ModelContext) {
        guard draft.hasName else { return }

        let target = draft.contact ?? Contact()
        target.firstName = draft.firstName.trimmingCharacters(in: .whitespaces)
        target.lastName = draft.lastName.trimmingCharacters(in: .whitespaces)
        target.phone = draft.phone.trimmingCharacters(in: .whitespaces)
        target.city = draft.city.trimmingCharacters(in: .whitespaces)
        target.branchOne = draft.branchOne.trimmingCharacters(in: .whitespaces)
        target.branchTwo = draft.branchTwo.trimmingCharacters(in: .whitespaces)

        if draft.contact == nil {
            context.insert(target)
        }

        save(context)
        editing = nil
    }

    func delete(_ contact: Contact, context: ModelContext) {
        Haptics.warning()
        withAnimation(AppAnimation.list) {
            context.delete(contact)
            save(context)
        }
        contactToDelete = nil
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
            Haptics.success()
        } catch {
            Haptics.error()
            AppLog.data.error("Contact save failed: \(error.localizedDescription, privacy: .public)")
            saveError = error.localizedDescription
        }
    }
}
