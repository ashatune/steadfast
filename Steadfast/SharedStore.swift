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

enum SharedStore {
    static let groupID = "group.ashatune.Steadfast"
    static let key = "widget_payload"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }

    static func save(_ payload: AnchorPayload) {
        guard let d = defaults else { return }
        let data = try? JSONEncoder().encode(payload)
        d.set(data, forKey: key)
        d.synchronize()
    }

    static func load() -> AnchorPayload? {
        guard let d = defaults, let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AnchorPayload.self, from: data)
    }

    static func nuke() {
        guard let d = defaults else { return }
        d.removeObject(forKey: key)
        d.synchronize()
    }
}


