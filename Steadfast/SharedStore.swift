//
//  SharedStore.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/9/25.
//shared anchor store


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
    static func save(verse: Verse, anchorDate: Date, lastUpdated: Date = Date()) -> AnchorOfDayPayload {
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

    static func fallbackPayload(anchorDate: Date = Date()) -> AnchorOfDayPayload {
        AnchorOfDayPayload(
            id: "Psalm 46:10",
            ref: "Psalm 46:10",
            text: "Be still, and know that I am God.",
            inhale: "Be still",
            exhale: "Know that I am God",
            anchorDate: anchorDate,
            lastUpdated: Date()
        )
    }

    static func makePayload(from verse: Verse, anchorDate: Date, lastUpdated: Date = Date()) -> AnchorOfDayPayload {
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

struct AnchorPayload: Codable, Equatable {
    let ref: String            // e.g., "Isaiah 41:10"
    let inhale: String         // e.g., "Inhale 4s" or "Cast all your care"
    let exhale: String         // e.g., "Exhale 6s" or "for He cares for you"
    let lastUpdated: Date
}

/// Legacy compatibility shim. Delegates to AnchorOfDayStore so app + widget stay in sync.
enum SharedStore {
    static func save(_ payload: AnchorPayload) {
        let bridged = AnchorOfDayPayload(
            id: payload.ref,
            ref: payload.ref,
            text: "",
            inhale: payload.inhale,
            exhale: payload.exhale,
            anchorDate: Date(),
            lastUpdated: payload.lastUpdated
        )
        AnchorOfDayStore.save(bridged)
    }

    static func load() -> AnchorPayload? {
        guard let payload = AnchorOfDayStore.load() else { return nil }
        return AnchorPayload(ref: payload.ref, inhale: payload.inhale, exhale: payload.exhale, lastUpdated: payload.lastUpdated)
    }

    static func nuke() {
        AnchorOfDayStore.clear()
    }
}
