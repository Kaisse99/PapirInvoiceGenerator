//
//  PDFPreviewView.swift
//  Full-screen viewer for a rendered invoice, wrapping PDFKit's PDFView with a
//  Done button and a share button. Swipe-to-dismiss is off so the only way out
//  is Done, since the gesture fights the PDF's own scrolling.
//  Used by: InvoiceDetailView, MyInvoicesView.
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let url: URL
    let title: String
    
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            PDFKitContainer(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Haptics.light()
                            dismiss()
                        } label: {
                            Text(L.t(.done))
                                .fontDesign(.monospaced)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.callout)
                            .fontDesign(.monospaced)
                            .fontWeight(.black)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.light()
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(items: [url])
                }
        }
        .interactiveDismissDisabled()
    }
}

private struct PDFKitContainer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument(url: url)
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemBackground
        return view
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}
