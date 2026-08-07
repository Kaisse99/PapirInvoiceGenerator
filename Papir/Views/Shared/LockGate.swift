//
//  LockGate.swift
//  Wraps the whole app in the lock. The cover is opaque and carries the mark,
//  so the app switcher shows the same face a locked phone does rather than a
//  page of customer names, and it is the same wash every other screen sits on
//  so unlocking reads as a curtain lifting rather than as a different app
//  handing over.
//  The unlock button only appears once a scan has actually been refused;
//  arriving at the lock puts the system prompt up on its own, and offering a
//  button before it has been dismissed would just be a second thing to tap.
//  Used by: PapirApp.
//

import SwiftUI

struct LockGate<Content: View>: View {
    @StateObject private var lock = AppLock()
    @Environment(\.scenePhase) private var scenePhase

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()

            if lock.isCovered {
                cover
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.smooth, value: lock.isCovered)
        .task {
            await lock.authenticate()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive:
                lock.obscure()
            case .background:
                lock.lock()
            case .active:
                Task { await lock.reveal() }
            @unknown default:
                break
            }
        }
    }

    private var cover: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 26) {
                Image("smallIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)

                if lock.didFail {
                    Button {
                        Haptics.light()
                        Task { await lock.authenticate() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.system(size: 15, weight: .medium))
                            Text(L.t(.unlock))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .foregroundStyle(Color(.systemBackground))
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(AppAnimation.smooth, value: lock.didFail)
        }
        .ignoresSafeArea()
    }
}
