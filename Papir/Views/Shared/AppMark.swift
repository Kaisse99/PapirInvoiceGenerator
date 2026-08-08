//
//  AppMark.swift
//  The app's own icon, wherever the app draws itself: the middle of the home
//  screen and the paperclip divider between sections.
//  One view rather than a bare Image at every call site, because the mark is
//  now the icon artwork rather than a line drawing, and artwork needs a shape
//  to sit in. It is clipped to the same continuous squircle iOS clips an app
//  icon to and given a hairline border, so it reads as an icon on both the
//  black home screen and the white sheets instead of bleeding into whichever
//  it happens to be on.
//  The radius is 22.37% of the side, which is the ratio iOS uses for its own
//  icon mask, so the corners match the icon on the user's home screen.
//  Used by: HomeView, PaperclipDivider.
//

import SwiftUI

struct AppMark: View {
    var size: CGFloat = 42

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
    }

    var body: some View {
        Image("smallIcon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay(shape.stroke(Color.primary.opacity(0.28), lineWidth: 1))
    }
}
