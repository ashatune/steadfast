import Foundation

extension Verse {
    var inhaleLabel: String {
        if let cue = inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        if let secs = breathIn { return "Breathe In \(secs)s" }
        return "Be still"
    }

    var exhaleLabel: String {
        if let cue = exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        if let secs = breathOut { return "Breathe Out \(secs)s" }
        return "And know"
    }
}
