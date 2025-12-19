import Foundation

/// Shared persistence for the daily Anchor verse used by both the app and the widget.
/// Make sure the app target and the widget target are both configured with the same
/// App Group identifier (e.g., `group.ashatune.Steadfast`) in Signing & Capabilities.
struct AnchorOfDayPayload: Codable, Equatable {
    let id: String
    let ref: String
    let text: String
    let inhale: String
    let exhale: String
    let anchorDate: Date
    let lastUpdated: Date
}

enum AnchorOfDayStore {
    /// Update this if you rename the App Group. Keep it in sync for both app + widget targets.
    static var appGroupID: String = "group.ashatune.Steadfast"
    private static let key = "anchor_of_day_payload"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func save(_ payload: AnchorOfDayPayload) {
        guard let d = defaults else { return }
        let data = try? JSONEncoder().encode(payload)
        d.set(data, forKey: key)
        d.synchronize()
    }

    @discardableResult
    static func save(verse: Verse, anchorDate: Date, lastUpdated: Date = .now) -> AnchorOfDayPayload {
        let payload = makePayload(from: verse, anchorDate: anchorDate, lastUpdated: lastUpdated)
        save(payload)
        return payload
    }

    static func load() -> AnchorOfDayPayload? {
        guard let d = defaults, let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AnchorOfDayPayload.self, from: data)
    }

    static func clear() {
        guard let d = defaults else { return }
        d.removeObject(forKey: key)
        d.synchronize()
    }

    static func fallbackPayload(anchorDate: Date = .now) -> AnchorOfDayPayload {
        AnchorOfDayPayload(
            id: "Psalm 46:10",
            ref: "Psalm 46:10",
            text: "Be still, and know that I am God.",
            inhale: "Be still",
            exhale: "Know that I am God",
            anchorDate: anchorDate,
            lastUpdated: .now
        )
    }

    static func makePayload(from verse: Verse, anchorDate: Date, lastUpdated: Date = .now) -> AnchorOfDayPayload {
        let ref = verse.ref.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = verse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let textWords = text
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        let inhale = inhaleString(from: verse, textWords: textWords)
        let exhale = exhaleString(from: verse, textWords: textWords)

        return AnchorOfDayPayload(
            id: ref.isEmpty ? UUID().uuidString : ref,
            ref: ref.isEmpty ? "Psalm 46:10" : ref,
            text: text,
            inhale: inhale,
            exhale: exhale,
            anchorDate: anchorDate,
            lastUpdated: lastUpdated
        )
    }

    private static func inhaleString(from verse: Verse, textWords: [String]) -> String {
        if let cue = verse.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathIn { return "Inhale \(secs)s" }
        return textWords.prefix(4).joined(separator: " ")
    }

    private static func exhaleString(from verse: Verse, textWords: [String]) -> String {
        if let cue = verse.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathOut { return "Exhale \(secs)s" }
        return textWords.dropFirst(4).joined(separator: " ")
    }
}

