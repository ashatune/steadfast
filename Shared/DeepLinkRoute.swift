import Foundation

enum DeepLinkRoute {
    static let scheme = "steadfast"
    static let pendingRouteDefaultsKey = "steadfast.pendingRoute"
    static let dailyDevotionalRouteToken = "devotional/today"
    static let streakProtectionRouteToken = "streakProtection"
    static let quickStartMeditationRouteToken = "quickStartMeditation"

    static func dailyDevotionalURL() -> URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = "devotional"
        comps.path = "/today"
        return comps.url
    }

    static func quickStartMeditationURL() -> URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = "quick-start-meditation"
        return comps.url
    }

    static func streakProtectionURL() -> URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = "streak-protection"
        return comps.url
    }

    static func anchorExerciseURL(anchorID: String? = nil) -> URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = "anchor"
        comps.path = "/exercise"

        if let anchorID, !anchorID.isEmpty {
            comps.queryItems = [URLQueryItem(name: "id", value: anchorID)]
        }

        return comps.url
    }

    static func isAnchorExercise(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        let path = url.path.lowercased()

        if host == "anchor" && (path.isEmpty || path == "/" || path == "/exercise") {
            return true
        }

        return host == "anchor-of-day"
        || path.contains("/anchor-of-day")
        || path.contains("/anchor/exercise")
        || path.contains("/anchor")
    }

    static func anchorIdentifier(from url: URL) -> String? {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return comps?.queryItems?.first(where: {
            let name = $0.name.lowercased()
            return name == "id" || name == "ref" || name == "anchorid"
        })?.value
    }

    static func isSteadfastURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == scheme
    }
}

extension Notification.Name {
    static let steadfastPendingRoute = Notification.Name("steadfast.pendingRoute")
}
