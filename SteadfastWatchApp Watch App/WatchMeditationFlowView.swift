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
                        verseLines: verseLines(for: kind),
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

    private func verseLines(for kind: WatchMeditationKind) -> [String] {
        switch kind {
        case .quickStart:
            return ["GOD is near", "GOD is near", "I am not alone"]
        case .anchorOfTheDay:
            let anchor = anchorStore.todaysAnchor
            return [anchor.inhale, anchor.exhale, anchor.ref]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
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
