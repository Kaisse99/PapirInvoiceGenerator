//
//  AppMark.swift
//  The app's own icon, wherever the app draws itself: the middle of the home
//  screen and the paperclip divider between sections.
//  One view rather than a bare Image at every call site, because the mark is
//  now the icon artwork rather than a line drawing, and artwork needs a shape
//  to sit in. It is clipped to the same continuous squircle iOS clips an app
//  icon to and nothing else: the artwork already carries its own edge, so a
//  border drawn around it only fenced the icon in.
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
    }
}
