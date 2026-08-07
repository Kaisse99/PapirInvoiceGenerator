//
//  ShareSheet.swift
//  UIActivityViewController as a SwiftUI view, so a PDF can be handed to the
//  system share sheet.
//  Used by: MyInvoicesView, PDFPreviewView.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
