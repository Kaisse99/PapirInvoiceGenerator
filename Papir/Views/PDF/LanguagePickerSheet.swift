//
//  LanguagePickerSheet.swift
//  The sheet asking which language to render a PDF in, one button per
//  PDFLanguage case. Reports the choice and lets the caller dismiss it.
//  Used by: InvoiceDetailView.
//

import SwiftUI

struct LanguagePickerSheet: View {
    let onSelect: (PDFLanguage) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(L.t(.generatePDFIn))
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.top, 24)
            
            VStack(spacing: 10) {
                ForEach(PDFLanguage.allCases) { language in
                    Button {
                        Haptics.light()
                        onSelect(language)
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.title2)
                            
                            Text(language.displayName)
                                .font(.callout)
                                .fontDesign(.monospaced)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.primary.opacity(0.15), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
