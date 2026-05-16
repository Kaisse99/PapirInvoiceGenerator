//
//  NewInvoiceView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-13.
//

import SwiftUI

struct InvoiceRowDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var unitCount: String = ""
    var itemsPerUnit: String = ""
    var price: String = ""
    var colors: [String] = []
}

struct NewInvoiceView: View {
    @Binding var currentScreen: HomeView.Screen
    
    @State private var showHeader = false
    @State private var sender: String = ""
    @State private var receiver: String = ""
    
    @State private var rows: [InvoiceRowDraft] = [InvoiceRowDraft()]
    
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showHeader.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: showHeader ? "chevron.down" : "chevron.right")
                                    .font(.callout)
                                Text("Sender & Receiver")
                                    .font(.callout)
                                    .fontDesign(.monospaced)
                                Spacer()
                            }
                            .foregroundStyle(.primary.opacity(0.9))
                        }
                        
                        if showHeader {
                            VStack(spacing: 14) {
                                HStack {
                                    TextField("Sender", text: $sender)
                                        .fontDesign(.monospaced)
                                        .limitInput($sender, to: 40)
                                    
                                    if !sender.isEmpty {
                                        Button {
                                            sender = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGroupedBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.primary.opacity(0.2), lineWidth: 0.5)
                                )
                                
                                HStack {
                                    TextField("Receiver", text: $receiver)
                                        .fontDesign(.monospaced)
                                        .limitInput($receiver, to: 40)
                                    
                                    if !receiver.isEmpty {
                                        Button {
                                            receiver = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGroupedBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.primary.opacity(0.2), lineWidth: 0.5)
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding([.horizontal, .top], 20)
                    
                    
                    VStack(spacing: 16) {
                        ForEach($rows) { $row in
                            InvoiceRowCard(
                                rowNumber: (rows.firstIndex(where: { $0.id == row.id }) ?? 0) + 1,
                                name: $row.name,
                                unitCount: $row.unitCount,
                                itemsPerUnit: $row.itemsPerUnit,
                                price: $row.price,
                                colors: $row.colors,
                                onDelete: {
                                    withAnimation {
                                        rows.removeAll { $0.id == row.id }
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Button {
                        withAnimation {
                            rows.append(InvoiceRowDraft())
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                            Text("Add new row")
                                .fontDesign(.monospaced)
                        }
                        .foregroundStyle(.primary)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentScreen = .home
                        }
                    } label: {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.primary.opacity(0.9))
                    } .padding(.horizontal, 10)
                }
                ToolbarItem(placement: .title) {
                    Text("Invoice +")
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.black)
                        .padding(.horizontal, 4)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Text(Date.now, style: .date)
                        .font(.callout)
                        .fontDesign(.monospaced)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                }
            }
        }
    }
}

#Preview {
    NewInvoiceView(currentScreen: .constant(.newInvoice))
}
