import Foundation

extension Verse {
    var inhaleLabel: String {
        if let cue = inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        if let secs = breathIn { return "Inhale \(secs)s" }
        return "Be still"
    }

    var exhaleLabel: String {
        if let cue = exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        if let secs = breathOut { return "Exhale \(secs)s" }
        return "And know"
    }
}
