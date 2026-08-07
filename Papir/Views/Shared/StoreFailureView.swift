//
//  StoreFailureView.swift
//  What stands where the app would be if the database refuses to open. It says
//  what happened in her language, shows the underlying error small for
//  whoever she hands the phone to, and offers exactly two ways forward: try
//  again, which fixes the transient cases, and start empty, which is the last
//  resort and sits behind a confirmation that says plainly it deletes
//  everything on this phone.
//  Used by: PapirApp.
//

import SwiftUI

struct StoreFailureView: View {
    let message: String
    let onRetry: () -> Void
    let onReset: () -> Void

    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            Text(L.t(.storeFailedTitle))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(L.t(.storeFailedHint))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer()

            Button {
                Haptics.medium()
                onRetry()
            } label: {
                Text(L.t(.tryAgain))
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(Color(.systemBackground))
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.9)))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.warning()
                confirmReset = true
            } label: {
                Text(L.t(.startEmpty))
                    .fontDesign(.monospaced)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .background(AppBackground())
        .confirmationDialog(
            L.t(.startEmptyWarning),
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button(L.t(.startEmpty), role: .destructive) { onReset() }
            Button(L.t(.cancel), role: .cancel) {}
        } message: {
            Text(L.t(.cannotBeUndone))
        }
    }
}
