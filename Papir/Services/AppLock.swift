//
//  AppLock.swift
//  Face ID over the whole app, off by default and turned on in settings. The
//  reason it exists: the Documents folder is shared, so every invoice PDF is
//  browsable from Files on an unlocked phone, and a year of those is the
//  customer list.
//  Two states, not one. Locked means she has to authenticate, and is entered
//  when the app is actually sent to the background. Obscured means the screen
//  is covered but nothing is asked, and is entered the moment the app goes
//  inactive, which is when iOS takes the picture it shows in the app switcher;
//  without it the switcher would hold a readable page of customer names.
//  Coming back from a glance at Control Center therefore costs nothing, while
//  coming back from another app asks for a face.
//  Authentication is deviceOwnerAuthentication rather than biometrics alone,
//  so the passcode is always a way in and a failed scan is never a locked
//  door. If the phone has neither biometrics nor a passcode there is nothing
//  to authenticate against, and the app unlocks rather than trapping her
//  behind a prompt that cannot succeed.
//  Used by: PapirApp through LockGate, SettingsSheet for the toggle.
//

import Combine
import LocalAuthentication
import SwiftUI

@MainActor
final class AppLock: ObservableObject {
    @Published private(set) var isLocked: Bool
    @Published private(set) var isObscured = false
    @Published private(set) var didFail = false

    init() {
        isLocked = AppSettings.appLockEnabled
    }

    var isCovered: Bool {
        isLocked || isObscured
    }

    func obscure() {
        guard AppSettings.appLockEnabled else { return }
        isObscured = true
    }

    func lock() {
        guard AppSettings.appLockEnabled else { return }
        isLocked = true
        didFail = false
    }

    func reveal() async {
        isObscured = false
        guard isLocked else { return }
        await authenticate()
    }

    func authenticate() async {
        guard AppSettings.appLockEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            didFail = false
            return
        }

        let granted = await evaluate(context, reason: L.t(.unlockReason))
        if granted {
            isLocked = false
            didFail = false
            Haptics.success()
        } else {
            didFail = true
        }
    }

    private func evaluate(_ context: LAContext, reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
