//
//  Verse+Preview.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/6/25.
//

import Foundation

extension Verse {
    var previewLine: String {
            // cues first
            if let i = inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines),
               let e = exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines),
               !i.isEmpty, !e.isEmpty {
                return "\(i) / \(e)"
            }
            // full text next
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }

            // durations
            if let bi = breathIn, let bo = breathOut {
                return "Inhale \(bi)s • Exhale \(bo)s"
            }
            // fallback
            return ref
        }
    /// Prefer cues; else split text; else show durations; else empty.
    var inhalePreview: String {
        if let i = inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !i.isEmpty {
            return i
        }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return splitText(t).0 }
        if let bi = breathIn { return "Inhale \(bi)s" }
        return ""
    }

    var exhalePreview: String {
        if let e = exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty {
            return e
        }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return splitText(t).1 }
        if let bo = breathOut { return "Exhale \(bo)s" }
        return ""
    }

    /// Split roughly in half by words.
    private func splitText(_ t: String) -> (String, String) {
        let words = t.split(separator: " ")
        guard !words.isEmpty else { return (ref, "") }
        let mid = max(1, words.count / 2)
        let first  = words[..<mid].joined(separator: " ")
        let second = words[mid...].joined(separator: " ")
        return (first, second.isEmpty ? first : second)
    }
}


