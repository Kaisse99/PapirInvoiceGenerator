//
//  Contact.swift
//  Someone she ships to: a name, a phone, a city, and the two Nova Poshta
//  branches an order can go to, because a customer usually has a regular
//  branch and a second one they fall back to. Everything is optional text
//  except that a contact needs a name to be worth listing, which the editor
//  enforces rather than the model, since a half-typed contact is a normal
//  state while the sheet is open.
//  An invoice points at the contact its receiver was picked from, so counting
//  what someone has bought is a question about a relationship rather than
//  about matching two strings that a typo can pull apart. The link is nullify,
//  never cascade: deleting a customer must not take their invoices with them,
//  and the invoice keeps the receiver name it was written with regardless.
//  Rows written before the address book existed simply have no contact.
//  Used by: AddressBookView, ContactEditorSheet, AddressBookViewModel,
//  NewInvoiceView, NewInvoiceViewModel, Invoice.
//

import Foundation
import SwiftData

@Model
final class Contact {
    var firstName: String = ""
    var lastName: String = ""
    var phone: String = ""
    var city: String = ""
    var branchOne: String = ""
    var branchTwo: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Invoice.receiverContact)
    var invoices: [Invoice]? = nil

    init(
        firstName: String = "",
        lastName: String = "",
        phone: String = "",
        city: String = "",
        branchOne: String = "",
        branchTwo: String = ""
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.city = city
        self.branchOne = branchOne
        self.branchTwo = branchTwo
        self.createdAt = .now
    }

    var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var displayName: String {
        fullName.isEmpty ? phone : fullName
    }

    var branches: [String] {
        [branchOne, branchTwo]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var whereTo: String {
        let city = city.trimmingCharacters(in: .whitespaces)
        let branch = branches.first ?? ""
        return [city, branch].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var invoiceCount: Int {
        invoices?.count ?? 0
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return true }
        return [fullName, phone, city, branchOne, branchTwo]
            .contains { $0.lowercased().contains(needle) }
    }
}
