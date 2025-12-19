//
//  SharedStore.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/9/25.
//shared anchor store


import Foundation

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
            anchorDate: .now,
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

