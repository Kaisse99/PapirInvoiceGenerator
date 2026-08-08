//
//  WelcomeSheet.swift
//  The one screen that explains the other four. Papir is navigated entirely by
//  dragging, which is fast once you know it and invisible until you do: a
//  stranger opening the app sees a mark, four arrows and no words telling them
//  what to do. That reads as an unfinished app rather than a quiet one, to a
//  new user and to an App Store reviewer alike.
//  So it is shown once, on the very first launch, and never again. There is no
//  way back to it on purpose: an onboarding screen that can be summoned is a
//  screen that has to be maintained as a feature, and this exists only to get
//  someone over the first ten seconds.
//  The four rows are in the order the hand learns them rather than the order
//  the code lists them: up to write, down to read back, then the two sideways.
//  Used by: HomeView, on first launch only.
//

import SwiftUI

struct WelcomeSheet: View {
    let language: AppLanguage
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppMark(size: 56)
                .padding(.top, 44)

            Text(L.t(.welcomeTitle, language))
                .font(.scaled(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(.top, 18)

            Text(L.t(.welcomeSubtitle, language))
                .font(.scaled(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            VStack(spacing: 14) {
                row("arrow.up", L.t(.create, language), L.t(.welcomeCreate, language))
                row("arrow.down", L.t(.menu, language), L.t(.welcomeInvoices, language))
                row("arrow.left", L.t(.stock, language), L.t(.welcomeStock, language))
                row("arrow.right", L.t(.statistics, language), L.t(.welcomeStats, language))
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Spacer(minLength: 20)

            Button {
                Haptics.medium()
                onDone()
            } label: {
                Text(L.t(.welcomeStart, language))
                    .font(.scaled(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .interactiveDismissDisabled()
    }

    private func row(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.scaled(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.primary.opacity(0.07)))
                .overlay(Circle().stroke(Color.primary.opacity(0.14), lineWidth: 0.8))

            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.scaled(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.scaled(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
