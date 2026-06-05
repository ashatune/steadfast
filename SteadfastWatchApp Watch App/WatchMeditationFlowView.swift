import Foundation
import SwiftUI

enum WatchMeditationKind: String, Identifiable, Hashable {
    case quickStart
    case anchorOfTheDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickStart: return "Quick Start Meditation"
        case .anchorOfTheDay: return "Anchor of the Day"
        }
    }

    var subtitle: String {
        switch self {
        case .quickStart: return "God is near"
        case .anchorOfTheDay: return "Pray today’s anchor"
        }
    }
}

struct WatchMeditationDuration: Identifiable, Hashable {
    let seconds: Int
    let title: String

    var id: Int { seconds }

    static let options: [WatchMeditationDuration] = [
        .init(seconds: 30, title: "30 seconds"),
        .init(seconds: 90, title: "90 seconds"),
        .init(seconds: 180, title: "3 minutes"),
        .init(seconds: 300, title: "5 minutes"),
        .init(seconds: 600, title: "10 minutes"),
        .init(seconds: 1_200, title: "20 minutes")
    ]
}

struct WatchMeditationFlowView: View {
    @StateObject private var anchorStore = WatchAnchorStore.shared

    var body: some View {
        NavigationStack {
            List {
                meditationLink(for: .quickStart)
                meditationLink(for: .anchorOfTheDay)
            }
            .listStyle(.carousel)
            .navigationTitle("Meditate")
        }
    }

    private func meditationLink(for kind: WatchMeditationKind) -> some View {
        NavigationLink {
            DurationSelectionView(kind: kind)
                .environmentObject(anchorStore)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                Text(kind.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct DurationSelectionView: View {
    let kind: WatchMeditationKind
    @EnvironmentObject private var anchorStore: WatchAnchorStore

    var body: some View {
        List {
            ForEach(WatchMeditationDuration.options) { duration in
                NavigationLink {
                    BreathingSessionView(
                        title: kind.title,
                        duration: duration,
                        prompts: prompts(for: kind),
                        reference: reference(for: kind)
                    )
                } label: {
                    HStack {
                        Text(duration.title)
                            .font(.headline.weight(.semibold))
                        Spacer()
                        if duration.seconds == 90 {
                            Text("Classic")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle(kind.title)
    }

    private func prompts(for kind: WatchMeditationKind) -> WatchBreathingPrompts {
        switch kind {
        case .quickStart:
            return WatchBreathingPrompts(
                inhale: "GOD is near",
                hold: "GOD is near",
                exhale: "I am not alone"
            )
        case .anchorOfTheDay:
            return AnchorBreathingTextHelper.prompts(for: anchorStore.todaysAnchor)
        }
    }

    private func reference(for kind: WatchMeditationKind) -> String? {
        guard kind == .anchorOfTheDay else { return nil }
        let anchor = anchorStore.todaysAnchor
        let text = anchor.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return anchor.ref }
        return "\(anchor.ref) — \(text)"
    }
}

enum AnchorBreathingTextHelper {
    private static let maxWordsPerSegment = 7

    static func prompts(for anchor: WatchAnchorPayload) -> WatchBreathingPrompts {
        let verseText = preferredVerseText(from: anchor)
        let split = splitVerseText(verseText)

        return WatchBreathingPrompts(
            inhale: displaySegment(split.inhale, fallback: anchor.inhale),
            hold: "Hold",
            exhale: displaySegment(split.exhale, fallback: anchor.exhale)
        )
    }

    private static func preferredVerseText(from anchor: WatchAnchorPayload) -> String {
        let text = normalized(anchor.text)
        if !text.isEmpty { return text }

        let combined = [anchor.inhale, anchor.exhale]
            .map(normalized)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return combined.isEmpty ? "Be still and know that I am God" : combined
    }

    private static func splitVerseText(_ text: String) -> (inhale: String, exhale: String) {
        let cleaned = normalized(text)
        guard !cleaned.isEmpty else { return ("Be still", "Know that I am God") }

        if let punctuationSplit = splitAtPunctuation(cleaned) {
            return punctuationSplit
        }

        let words = words(in: cleaned)
        guard words.count > 1 else { return (cleaned, cleaned) }

        let midpoint = max(1, words.count / 2)
        return (
            words.prefix(midpoint).joined(separator: " "),
            words.dropFirst(midpoint).joined(separator: " ")
        )
    }

    private static func splitAtPunctuation(_ text: String) -> (inhale: String, exhale: String)? {
        let chars = Array(text)
        guard chars.count > 12 else { return nil }

        let midpoint = chars.count / 2
        let punctuation = CharacterSet(charactersIn: ",;:.!?—–-")
        let candidates = chars.indices.compactMap { index -> (offset: Int, distance: Int)? in
            guard let scalar = String(chars[index]).unicodeScalars.first,
                  punctuation.contains(scalar) else { return nil }
            let before = normalized(String(chars[..<index]))
            let afterStart = chars.index(after: index)
            let after = normalized(String(chars[afterStart...]))
            guard words(in: before).count >= 2, words(in: after).count >= 2 else { return nil }
            return (index, abs(index - midpoint))
        }

        guard let best = candidates.min(by: { $0.distance < $1.distance }) else { return nil }
        let afterStart = chars.index(after: best.offset)
        return (
            normalized(String(chars[..<best.offset])),
            normalized(String(chars[afterStart...]))
        )
    }

    private static func displaySegment(_ segment: String, fallback: String) -> String {
        let cleaned = normalized(segment)
        let fallbackText = normalized(fallback)
        let source = cleaned.isEmpty ? fallbackText : cleaned
        let sourceWords = words(in: source)

        guard sourceWords.count > maxWordsPerSegment else { return source }
        return sourceWords.prefix(maxWordsPerSegment).joined(separator: " ")
    }

    private static func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func words(in text: String) -> [String] {
        normalized(text)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
}
