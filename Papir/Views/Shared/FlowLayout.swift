//
//  FlowLayout.swift
//  Lays subviews left to right and wraps to a new line when the next one will
//  not fit, growing as tall as it needs to. Exists because the colour badges
//  are a list of unknown length that an HStack would push off the edge.
//
//  Both halves of the layout ask one function where the lines break, and both
//  ask it about the same width. That is the whole of the design, and it is a
//  correction. Measuring used the width it was offered while placing used
//  bounds.width, which is the narrower width the measurement had just
//  reported, and the two could disagree in two ways. A line that exactly
//  filled the reported width could tip past it by one floating-point ulp on
//  the second pass and wrap once more, and an unspecified proposal measured as
//  a single line and then placed as several. Either way the height reserved
//  came up a line short of the height drawn, and the last row of badges landed
//  on top of whatever followed. Statistics showed it plainly: a model with
//  four colours inside a single month overlapped the model listed beneath it,
//  while the same card over all time happened to break where it had measured
//  and looked fine.
//
//  Widths are compared with a hair of tolerance for the same reason: 261.666…
//  is not reliably equal to itself once it has been through a layout pass.
//  Used by: InvoiceRowCard, InvoiceDetailView, StatisticsView.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    /// Where every subview sits when laid into `width`, and how big the whole
    /// becomes. One answer, so measuring and placing cannot disagree.
    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, offsets: [CGPoint]) {
        let tolerance: CGFloat = 0.001
        var offsets: [CGPoint] = []
        offsets.reserveCapacity(subviews.count)

        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width + tolerance {
                widest = max(widest, x - spacing)
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        widest = max(widest, x - spacing)
        return (CGSize(width: max(0, min(widest, width)), height: y + lineHeight), offsets)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // The proposal is the width this was measured against; bounds.width is
        // whatever it was handed afterwards. Wrapping on the proposal keeps the
        // breaks identical to the ones the reported height was counted from.
        let width = proposal.width ?? bounds.width
        let offsets = arrange(subviews, width: width).offsets

        for (subview, offset) in zip(subviews, offsets) {
            subview.place(
                at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y),
                proposal: .unspecified
            )
        }
    }
}
