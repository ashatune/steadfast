import Foundation
import StoreKit
import UIKit

/// Central place to track launches & "meaningful" usage and decide when to ask for a review.
final class AppReviewManager {
    static let shared = AppReviewManager()

    private let defaults = UserDefaults.standard

    private let launchesKey      = "steadfast.review.launches"
    private let eventsKey        = "steadfast.review.meaningfulEvents"
    private let didReviewKey     = "steadfast.review.didReview"
    private let lastPromptKey    = "steadfast.review.lastPromptDate"
    private let firstLaunchKey   = "steadfast.review.firstLaunch"
    private let promptAttemptsKey = "steadfast.review.promptAttempts"

    // DEBUG override to force attempts during development
    #if DEBUG
    var debugAlwaysPrompt: Bool = false
    #endif

    private init() {}

    // MARK: - Tracking

    /// Call once per app launch or per "session".
    func registerLaunch() {
        let newCount = defaults.integer(forKey: launchesKey) + 1
        defaults.set(newCount, forKey: launchesKey)
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date(), forKey: firstLaunchKey)
        }
    }

    /// Call when the user completes a grounding / daily rhythm / SOS success.
    func registerMeaningfulEvent() {
        let newCount = defaults.integer(forKey: eventsKey) + 1
        defaults.set(newCount, forKey: eventsKey)
    }

    func attemptPromptIfEligible() {
        let hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        guard shouldPrompt(hasCompletedOnboarding: hasCompletedOnboarding) else { return }
        requestInAppReviewIfAvailable()
    }

    // MARK: - Decision logic

    /// Returns true if we *should* show our custom review prompt right now.
    private func shouldPrompt(hasCompletedOnboarding: Bool) -> Bool {
        #if DEBUG
        if debugAlwaysPrompt { return true }
        #endif
        // Don’t ask people who haven't finished onboarding
        guard hasCompletedOnboarding else { return false }

        // Don’t bug people who already chose to review / opted out
        if defaults.bool(forKey: didReviewKey) { return false }

        let launches  = defaults.integer(forKey: launchesKey)
        let events    = defaults.integer(forKey: eventsKey)

        // Wait until they've used the app a bit
        guard launches >= 5 else { return false }

        // Require multiple "happy path" events (finished flows, etc.)
        guard events >= 3 else { return false }

        // Require a few days since first launch
        if let first = defaults.object(forKey: firstLaunchKey) as? Date {
            if let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day,
               days < 3 {
                return false
            }
        }

        // Optional: don't show more than once every 30 days
        if let last = defaults.object(forKey: lastPromptKey) as? Date {
            if let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day,
               days < 30 {
                return false
            }
        }

        // Cap attempts to avoid spamming
        let attempts = defaults.integer(forKey: promptAttemptsKey)
        guard attempts < 3 else { return false }

        return true
    }

    func markPromptShown() {
        defaults.set(Date(), forKey: lastPromptKey)
        let attempts = defaults.integer(forKey: promptAttemptsKey) + 1
        defaults.set(attempts, forKey: promptAttemptsKey)
    }

    /// Mark that the user either *left* a review or chose "No thanks".
    func markDidReview() {
        defaults.set(true, forKey: didReviewKey)
    }

    // MARK: - Actions

    /// Open the App Store page directly on the write-a-review screen.
    @MainActor
    func openAppStoreReviewPage() {
        // Steadfast App Store ID
        let appID = "6751298616"

        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        markDidReview()
    }

    /// If you ever want the native in-app popup instead.
    @MainActor
    func requestInAppReviewIfAvailable() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
        markDidReview()
    }
}
