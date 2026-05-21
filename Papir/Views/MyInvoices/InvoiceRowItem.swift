//
//  InvoiceRowItem.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct InvoiceRowItem: View {
    @Environment(\.colorScheme) var colorScheme
    let invoice: Invoice
    
    private static let totalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    
    private var formattedTotal: String {
        Self.totalFormatter.string(from: NSNumber(value: invoice.totalInvoicePrice))
            ?? "\(Int(invoice.totalInvoicePrice))"
    }
    
    private var receiverName: String {
        invoice.receiver.isEmpty ? "No receiver" : invoice.receiver
    }
    
    private var hasPDF: Bool {
        invoice.pdfFileName != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(receiverName)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 11))
                    Text("\(invoice.items.count)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(.primary.opacity(0.06)))
                .overlay(Capsule().stroke(.primary.opacity(0.12), lineWidth: 0.8))
            }
            
            Spacer(minLength: 18)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedTotal)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("₴")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Spacer(minLength: 10)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(hasPDF ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(hasPDF ? "PDF ready" : "No PDF")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(Self.dateFormatter.string(from: invoice.date))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.primary.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: .primary.opacity(0.08), radius: 8, y: 3)
    }
}
