import SwiftUI

struct TodayAnchorCard: View {
    @StateObject private var vm = AnchorViewModel()
    private var v: Verse { vm.todaysAnchor }
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s Anchor")
                .font(.headline)

            // Ref (single, adaptive color)
            Text(v.ref)
                .font(.title3).bold()
                .foregroundColor(colorScheme == .dark ? .white : .black)

            // Subtitle: show Inhale/Exhale if available, else nothing
            if !inhaleLine.isEmpty || !exhaleLine.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    if !inhaleLine.isEmpty { Text("Breathe In: \(inhaleLine)") }
                    if !exhaleLine.isEmpty { Text("Breathe Out: \(exhaleLine)") }
                }
                .font(.callout)
                .foregroundStyle(.secondary)     // ← adaptive: dark=light text, light=dark text
                .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .onAppear { vm.refreshNow() }
    }

    // MARK: - Local subtitle helpers (never return the ref)
    private var inhaleLine: String {
        if let cue = v.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        let text = v.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { return split(text).0 }
        if let secs = v.breathIn { return "Breathe In \(secs)s" }
        return ""
    }

    private var exhaleLine: String {
        if let cue = v.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
        let text = v.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { return split(text).1 }
        if let secs = v.breathOut { return "Breathe Out \(secs)s" }
        return ""
    }

    private func split(_ t: String) -> (String, String) {
        let words = t.split(separator: " ")
        guard !words.isEmpty else { return ("", "") }
        let mid = max(1, words.count / 2)
        let first  = words[..<mid].joined(separator: " ")
        let second = words[mid...].joined(separator: " ")
        return (first, second.isEmpty ? first : second)
    }
}
