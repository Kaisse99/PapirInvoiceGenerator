//
//  FlowLayout.swift
//  Lays subviews left to right and wraps to a new line when the next one won't
//  fit, growing as tall as it needs to. Exists because the color badges are a
//  list of unknown length that HStack would push off the edge. Reports the
//  width it actually used rather than the width it was offered, so it still
//  measures correctly when the proposal is unspecified and a subview wider than
//  the whole line takes that line alone instead of opening an empty one.
//  Used by: InvoiceRowCard, InvoiceDetailView.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0 && lineWidth + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                widestLine = max(widestLine, lineWidth - spacing)
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        widestLine = max(widestLine, lineWidth - spacing)

        return CGSize(width: min(maxWidth, max(widestLine, 0)), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
