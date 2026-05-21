//
//  InvoiceDetailView.swift
//  Papir
//
//  Created by Mykyta Kaisenberg on 2026-05-19.
//

import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let invoice: Invoice
    
    @StateObject private var viewModel = InvoiceDetailViewModel()
    @State private var showEditSheet = false
    
    private static let totalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()
    
    private func formatted(_ value: Double) -> String {
        Self.totalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                actionButtons
                receiptHeader
                PaperclipDivider(iconSize: 36)
                rowsSection
                PaperclipDivider(iconSize: 36)
                totalSection
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(invoice.receiver.isEmpty ? "Invoice" : invoice.receiver)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.black)
                    .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $viewModel.showLanguagePicker) {
            LanguagePickerSheet { language in
                viewModel.showLanguagePicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.generatePDF(for: invoice, language: language, context: modelContext)
                }
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            EditInvoiceSheet(invoice: invoice)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { viewModel.pdfPreviewURL != nil },
                set: { if !$0 { viewModel.pdfPreviewURL = nil } }
            )
        ) {
            if let url = viewModel.pdfPreviewURL {
                PDFPreviewView(url: url, title: viewModel.pdfPreviewTitle)
            }
        }
        .alert(
            "Couldn't generate PDF",
            isPresented: Binding(
                get: { viewModel.generationError != nil },
                set: { if !$0 { viewModel.generationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.generationError = nil
            }
        } message: {
            Text(viewModel.generationError ?? "")
        }
    }
    
    private var backgroundGradient: some View {
        RadialGradient(
            colors: [
                Color(.systemBackground),
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.gray.opacity(0.25)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 500
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Haptics.medium()
                    viewModel.viewExistingPDF(for: invoice)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.callout)
                        Text("View PDF")
                            .fontDesign(.monospaced)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(Color(.systemBackground))
                    .background(RoundedRectangle(cornerRadius: 12).fill(.primary))
                }
                .buttonStyle(.plain)
                .disabled(invoice.pdfFileName == nil)
                .opacity(invoice.pdfFileName == nil ? 0.4 : 1)
                
                Button {
                    Haptics.medium()
                    viewModel.showLanguagePicker = true
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isGeneratingPDF {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.callout)
                        }
                        Text(viewModel.isGeneratingPDF ? "..." : "Re-generate")
                            .fontDesign(.monospaced)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isGeneratingPDF)
            }
            
            Button {
                Haptics.medium()
                showEditSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.callout)
                    Text("Make Changes")
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(.primary)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    private var receiptHeader: some View {
        VStack(spacing: 8) {
            if !invoice.sender.isEmpty {
                receiptRow(label: "From", value: invoice.sender)
            }
            if !invoice.receiver.isEmpty {
                receiptRow(label: "To", value: invoice.receiver)
            }
            receiptRow(label: "Date", value: Self.dateFormatter.string(from: invoice.date))
            receiptRow(label: "Items", value: "\(invoice.items.count)")
        }
        .padding(.horizontal, 24)
    }
    
    private func receiptRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .fontDesign(.monospaced)
                .foregroundStyle(.primary)
        }
    }
    
    private var rowsSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(invoice.items.enumerated()), id: \.element.id) { index, item in
                rowEntry(index: index + 1, item: item)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func rowEntry(index: Int, item: ItemRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Entry #\(index):")
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(item.name)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(item.unitCount)")
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text("×")
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Text("\(item.itemsPerUnit)")
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text("×")
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                Text(formatted(item.price))
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.primary.opacity(0.85))
                Text("₴")
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatted(item.totalForItem))
                    .font(.footnote)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("₴")
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }
            
            if !item.colors.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(item.colors, id: \.self) { color in
                        Text(color)
                            .font(.caption2)
                            .fontDesign(.monospaced)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(.systemBackground)))
                            .overlay(Capsule().stroke(.primary.opacity(0.35), lineWidth: 0.5))
                            .foregroundStyle(.primary.opacity(0.85))
                    }
                }
            }
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [3]))
                .frame(height: 1)
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 6)
        }
    }
    
    private var totalSection: some View {
        VStack(spacing: 6) {
            Text("TOTAL")
                .font(.caption)
                .fontDesign(.monospaced)
                .tracking(6)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formatted(invoice.totalInvoicePrice))
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                
                Text("₴")
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct EditInvoiceSheet: View {
    let invoice: Invoice
    @Environment(\.dismiss) var dismiss
    @State private var screen: HomeViewModel.Screen = .create
    @State private var deepLink: Invoice? = nil
    
    var body: some View {
        NewInvoiceView(
            viewModel: NewInvoiceViewModel(editingInvoice: invoice),
            currentScreen: $screen,
            deepLinkInvoice: $deepLink
        )
        .onChange(of: screen) { _, newScreen in
            if newScreen != .create {
                dismiss()
            }
        }
        .onChange(of: deepLink) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceDetailView(
            invoice: Invoice(
                items: [
                    ItemRow(name: "2337", unitCount: 6, itemsPerUnit: 1, price: 119, colors: ["чор", "біл"]),
                    ItemRow(name: "9813", unitCount: 3, itemsPerUnit: 1, price: 99, colors: ["кава"])
                ],
                date: .now,
                sender: "Anna",
                receiver: "Mom"
            )
        )
    }
    .modelContainer(for: [Invoice.self, ItemRow.self], inMemory: true)
}
