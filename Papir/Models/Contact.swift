//
//  Contact.swift
//  Someone she ships to: a name, a phone, a city, and the address a parcel
//  goes to. It was two Nova Poshta branch fields; both went, because a second
//  address was a fallback nobody filled in and naming the carrier in the model
//  made the app Ukraine-only for no gain. The stored column is renamed rather
//  than replaced, through originalName, so no existing address is lost.
//  city and address print as one line, "City, Address", because that is how a
//  parcel is addressed; either can be missing and the comma goes with it.
//  Everything is optional text
//  except that a contact needs a name to be worth listing, which the editor
//  enforces rather than the model, since a half-typed contact is a normal
//  state while the sheet is open.
//  identifier is a UUID of the contact's own, copied onto every invoice
//  addressed to it. The relationship alone was not enough: deleting a customer
//  nullifies it, and the invoices then fell back to grouping by typed name, so
//  two different people who happened to share one dropped into a single line
//  in the rankings. The copy survives the deletion and keeps them apart.
//  An invoice points at the contact its receiver was picked from, so counting
//  what someone has bought is a question about a relationship rather than
//  about matching two strings that a typo can pull apart. Only the receiver:
//  the sender is whoever is holding the phone, which is a name set once in
//  settings, not a customer. The link is nullify, never cascade: deleting a
//  customer must not take their invoices with them, and the invoice keeps the
//  name it was written with regardless. Invoices written before the address
//  book existed have no contact.
//  documentLines is what goes under a name on the PDF: where it goes on one
//  line, then the phone.
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
    @Attribute(originalName: "branchOne")
    var shipmentAddress: String = ""
    var createdAt: Date = Date.now
    var identifier: UUID = UUID()

    @Relationship(deleteRule: .nullify, inverse: \Invoice.receiverContact)
    var invoices: [Invoice]? = nil

    init(
        firstName: String = "",
        lastName: String = "",
        phone: String = "",
        city: String = "",
        shipmentAddress: String = ""
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.city = city
        self.shipmentAddress = shipmentAddress
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

    var address: String {
        shipmentAddress.trimmingCharacters(in: .whitespaces)
    }

    var whereTo: String {
        [city.trimmingCharacters(in: .whitespaces), address]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var invoiceCount: Int {
        invoices?.count ?? 0
    }

    var documentLines: [String] {
        var lines: [String] = []
        if !whereTo.isEmpty { lines.append(whereTo) }
        let phone = phone.trimmingCharacters(in: .whitespaces)
        if !phone.isEmpty { lines.append(phone) }
        return lines
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return true }
        return [fullName, phone, city, shipmentAddress]
            .contains { $0.lowercased().contains(needle) }
    }
}
