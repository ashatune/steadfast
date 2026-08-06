import SwiftUI
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// The single analytics boundary for the app. Callers pass identifiers and enums only;
/// user-entered or displayed devotional/meditation content must never be passed here.
enum AnalyticsService {
    static let onboardingVersion = "2026_08"

    static func log(_ name: String, parameters: [String: Any] = [:]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #endif
        #if DEBUG
        print("[Analytics] \(name) \(parameters)")
        #endif
    }

    static func screenView(name: String, screenClass: String) {
        log("screen_view", parameters: ["screen_name": name, "screen_class": screenClass])
    }

    static func onboarding(_ event: String, stepIndex: Int? = nil, stepName: String? = nil,
                           totalSteps: Int, completionMethod: String? = nil,
                           reminderSelection: String? = nil) {
        var parameters: [String: Any] = [
            "onboarding_version": onboardingVersion,
            "total_steps": totalSteps
        ]
        if let stepIndex { parameters["step_index"] = stepIndex }
        if let stepName { parameters["step_name"] = stepName }
        if let completionMethod { parameters["completion_method"] = completionMethod }
        if let reminderSelection { parameters["reminder_selection"] = reminderSelection }
        log(event, parameters: parameters)
    }

    static func tutorial(_ event: String, stepIndex: Int? = nil, stepName: String? = nil,
                         totalSteps: Int) {
        var parameters: [String: Any] = ["total_steps": totalSteps]
        if let stepIndex { parameters["step_index"] = stepIndex }
        if let stepName { parameters["step_name"] = stepName }
        log(event, parameters: parameters)
    }

    static func meditation(_ event: String, contentID: String, category: String,
                           durationMinutes: Int? = nil, source: String? = nil,
                           completed: Bool? = nil) {
        var parameters: [String: Any] = ["content_id": contentID, "meditation_category": category]
        if let durationMinutes { parameters["duration_minutes"] = durationMinutes }
        if let source { parameters["source"] = source }
        if let completed { parameters["completed"] = completed }
        log(event, parameters: parameters)
    }
}

private struct AnalyticsScreenModifier: ViewModifier {
    let name: String
    let screenClass: String
    @State private var hasLogged = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasLogged else { return }
            hasLogged = true
            AnalyticsService.screenView(name: name, screenClass: screenClass)
        }
    }
}

extension View {
    func analyticsScreen(_ name: String, screenClass: String? = nil) -> some View {
        modifier(AnalyticsScreenModifier(name: name, screenClass: screenClass ?? name))
    }
}
