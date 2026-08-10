import Foundation
import StoreKit
import UIKit

/// Tracks successful exercise sessions and owns the app's single automatic review milestone.
@MainActor
final class AppReviewManager {
    static let shared = AppReviewManager()

    /// This is the existing meaningful-event key, retained so existing completion history is preserved.
    static let qualifyingCompletionCountKey = "steadfast.review.meaningfulEvents"
    static let automaticAttemptedKey = "steadfast.review.automaticAttempted"

    private let defaults = UserDefaults.standard
    private let legacyPromptAttemptsKey = "steadfast.review.promptAttempts"
    private let legacyDidReviewKey = "steadfast.review.didReview"
    private let legacyPendingRequestKeys = [
        "steadfast.review.requestOnNextLaunch",
        "steadfast.review.pendingRequest"
    ]
    private let requiredCompletionCount = 2
    private var acceptedSessionIDs = Set<UUID>()
    private var requestScheduled = false

    private init() {
        migrateLegacyState()
    }

    /// Records one genuinely completed exercise session. Reusing a session ID is intentionally ignored.
    func registerQualifyingCompletion(sessionID: UUID) {
        guard acceptedSessionIDs.insert(sessionID).inserted else {
            log("ignored duplicate completion for session \(sessionID)")
            return
        }

        let newCount = defaults.integer(forKey: Self.qualifyingCompletionCountKey) + 1
        defaults.set(newCount, forKey: Self.qualifyingCompletionCountKey)
        log("accepted completion; persisted count is \(newCount)")

        guard newCount >= requiredCompletionCount,
              !defaults.bool(forKey: Self.automaticAttemptedKey),
              !requestScheduled else {
            log("automatic request already attempted or milestone not reached")
            return
        }

        // Let completion state, animations, navigation, streaks, and audio cleanup settle first.
        requestScheduled = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            requestScheduled = false
            requestAutomaticReviewIfPossible()
        }
    }

    private func requestAutomaticReviewIfPossible() {
        guard !defaults.bool(forKey: Self.automaticAttemptedKey),
              let scene = UIApplication.shared.connectedScenes.first(where: {
                  $0.activationState == .foregroundActive && $0 is UIWindowScene
              }) as? UIWindowScene else {
            log("review request skipped because there is no active foreground UIWindowScene")
            return
        }

        // StoreKit may choose not to display a sheet. Consuming the attempt here prevents retries.
        defaults.set(true, forKey: Self.automaticAttemptedKey)
        log("invoking StoreKit automatic review request")
        AppStore.requestReview(in: scene)
    }

    private func migrateLegacyState() {
        if defaults.integer(forKey: legacyPromptAttemptsKey) > 0 || defaults.bool(forKey: legacyDidReviewKey) {
            defaults.set(true, forKey: Self.automaticAttemptedKey)
        }
        // Historical pending flags must never result in a launch-time request.
        legacyPendingRequestKeys.forEach { defaults.removeObject(forKey: $0) }
        log("persisted qualifying count: \(defaults.integer(forKey: Self.qualifyingCompletionCountKey)); attempted: \(defaults.bool(forKey: Self.automaticAttemptedKey))")
    }

    private func log(_ message: String) {
        #if DEBUG
        print("AppReviewManager: \(message)")
        #endif
    }
}
