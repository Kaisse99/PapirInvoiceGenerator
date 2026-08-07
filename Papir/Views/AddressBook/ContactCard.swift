//
//  ContactCard.swift
//  One contact in the address book. The name leads in the same rounded weight
//  the stock code uses, the phone sits under it in monospaced because it is a
//  number to read digit by digit, and the city and branches run along the
//  bottom as chips the way colors do on a stock card. How many invoices the
//  contact is on sits opposite the name, quietly, since it is the one thing
//  about a customer that is worth seeing without opening anything.
//  Used by: AddressBookView.
//

import SwiftUI

struct ContactCard: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(contact.displayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)

                if contact.invoiceCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 11))
                        Text("\(contact.invoiceCount)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            if !contact.phone.isEmpty {
                Text(contact.phone)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 3)
            }

            if !contact.city.isEmpty || !contact.branches.isEmpty {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.top, 14)

                FlowLayout(spacing: 6) {
                    if !contact.city.isEmpty {
                        chip(contact.city, icon: "mappin")
                    }
                    ForEach(contact.branches, id: \.self) { branch in
                        chip(branch, icon: "shippingbox")
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            } else {
                Spacer(minLength: 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .raisedShadow()
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
        )
    }

    private func chip(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Text(text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.primary.opacity(0.05)))
        .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 0.8))
    }
}
