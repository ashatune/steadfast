import SwiftUI

// MARK: - Data Model

struct ReframeEntry: Identifiable, Hashable, Codable {
    var id: UUID = .init()
    var date: Date = .init()
    var title: String = ""
    var thought: String = ""      // Step 1
    var pattern: String = ""      // <- AI-detected pattern (e.g., Catastrophizing)
    var challenge: String = ""    // Step 4
    var reframe: String = ""      // Step 5
    var anchor: String = ""       // Optional
    var verseRef: String = ""     // <- Step 3
    var verseText: String = ""    // <-

    // Back-compat fields (optional if you already removed)
    var distortion: String = ""   // kept to avoid breaking older code; not used

    var preview: String {
        if !reframe.isEmpty { return reframe }
        if !thought.isEmpty { return thought }
        return "No preview"
    }
}

// MARK: - AI-ish service (swap with a real LLM later)

enum ThoughtPattern: String, CaseIterable {
    case catastrophizing = "Catastrophizing"
    case allOrNothing    = "All-or-nothing"
    case overgeneral     = "Overgeneralization"
    case mindReading     = "Mind-reading"
    case fortuneTelling  = "Fortune-telling"
    case shoulds         = "Should statements"
    case labeling        = "Labeling"
    case discountingPos  = "Discounting the positive"
    case none            = "Unclear"
}

// Renamed to avoid collision with your global Verse model
struct ScriptureSnippet {
    let ref: String
    let text: String // KJV excerpts to avoid licensing issues
}

final class ReframeAIService {
    // Simple keyword heuristics (works offline). Replace with LLM call later.
    func analyze(thought: String) async -> (pattern: ThoughtPattern, empathy: String, suggestion: String) {
        let t = thought.lowercased()

        let pattern: ThoughtPattern = {
            if t.contains("always") || t.contains("never") { return .allOrNothing }
            if t.contains("everyone") || t.contains("no one") { return .overgeneral }
            if t.contains("they think") || t.contains("they'll think") || t.contains("probably think") { return .mindReading }
            if t.contains("what if") || t.contains("going to happen") || t.contains("will happen") { return .fortuneTelling }
            if t.contains("should") || t.contains("must") || t.contains("supposed to") { return .shoulds }
            if t.contains("i'm a") || t.contains("i am a") || t.contains("i’m a") { return .labeling }
            if t.contains("not good enough") || t.contains("doesn't count") || t.contains("doesnt count") { return .discountingPos }
            if t.contains("worst") || t.contains("ruined") || t.contains("disaster") { return .catastrophizing }
            return .none
        }()

        let empathy = "Your feelings are valid — thank you for sharing. Let’s look at this together."
        let suggestion = pattern == .none
            ? "I’m not fully sure of the pattern yet, but we can still find a steadier perspective."
            : "It sounds like this may involve \(pattern.rawValue.lowercased())."

        return (pattern, empathy, suggestion)
    }

    // Pattern → verse (KJV excerpts)
    func verse(for pattern: ThoughtPattern) -> ScriptureSnippet {
        switch pattern {
        case .catastrophizing:
            return ScriptureSnippet(ref: "Matthew 6:34", text: "Take therefore no thought for the morrow… sufficient unto the day is the evil thereof.")
        case .allOrNothing:
            return ScriptureSnippet(ref: "Romans 8:1", text: "There is therefore now no condemnation to them which are in Christ Jesus…")
        case .overgeneral:
            return ScriptureSnippet(ref: "Lamentations 3:22–23", text: "It is of the LORD’s mercies that we are not consumed… They are new every morning.")
        case .mindReading:
            return ScriptureSnippet(ref: "Proverbs 3:5", text: "Trust in the LORD with all thine heart; and lean not unto thine own understanding.")
        case .fortuneTelling:
            return ScriptureSnippet(ref: "Matthew 6:27", text: "Which of you by taking thought can add one cubit unto his stature?")
        case .shoulds:
            return ScriptureSnippet(ref: "Micah 6:8", text: "…what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly…")
        case .labeling:
            return ScriptureSnippet(ref: "Psalm 139:14", text: "I will praise thee; for I am fearfully and wonderfully made…")
        case .discountingPos:
            return ScriptureSnippet(ref: "Philippians 4:8", text: "…whatsoever things are lovely… of good report… think on these things.")
        case .none:
            return ScriptureSnippet(ref: "Isaiah 41:10", text: "Fear thou not; for I am with thee… I will strengthen thee…")
        }
    }
}

// MARK: - Landing (Start Card + History)

struct ReframeLandingView: View {
    @Binding var reframes: [ReframeEntry]
    var onStart: () -> Void

    // Feature flag: flip to false when you launch Reframe
    private let comingSoon = true

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Start card with image background
                    Button(action: onStart) {
                        ZStack(alignment: .bottomLeading) {
                            Image("Journal") // add this image to Assets
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipped()

                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.45), Color.black.opacity(0.1)]),
                                startPoint: .bottom, endPoint: .top
                            )
                            .frame(height: 220)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start a new reframe")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("A 2–3 minute guided journaling exercise to shift anxious thoughts.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(2)
                            }
                            .padding(16)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // History header
                    Text("Previous reframes")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)

                    if reframes.isEmpty {
                        Text("Your saved reframes will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(reframes) { entry in
                                NavigationLink {
                                    ReframeDetailView(entry: entry)
                                } label: {
                                    ReframeRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .blur(radius: comingSoon ? 1.5 : 0)
            .allowsHitTesting(!comingSoon)

            if comingSoon {
                ComingSoonOverlay(
                    title: "Reframe is Coming Soon",
                    message: "We’re nearly ready to help you gently reframe anxious thoughts."
                )
                .transition(.opacity)
            }
        }
    }
}

private struct ReframeRow: View {
    let entry: ReframeEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .frame(width: 3)
                .foregroundStyle(Theme.accent)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.isEmpty ? "Reframe" : entry.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)

                Text(entry.preview)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(2)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 2)
        }
        .padding(12)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - Detail

struct ReframeDetailView: View {
    let entry: ReframeEntry
    private let comingSoon = true

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text.isEmpty ? "—" : text)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(entry.title.isEmpty ? "Reframe" : entry.title)
                        .font(.title3.bold())

                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()

                    section("Pattern", entry.pattern.isEmpty ? "—" : entry.pattern)
                    if !entry.verseText.isEmpty {
                        section("Verse", "\"\(entry.verseText)\"  — \(entry.verseRef)")
                    }

                    section("Thought", entry.thought)
                    section("Distortion", entry.distortion)
                    section("Challenge", entry.challenge)
                    section("Reframe", entry.reframe)
                    if !entry.anchor.isEmpty {
                        section("Anchor", entry.anchor)
                    }
                }
                .padding(16)
            }
            .blur(radius: comingSoon ? 1.5 : 0)
            .allowsHitTesting(!comingSoon)

            if comingSoon { ComingSoonOverlay() }
        }
        .navigationTitle("Reframe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guided Flow (renamed to avoid conflicts)

struct ReframeGuidedFlow: View {
    var onFinish: (ReframeEntry) -> Void
    private let comingSoon = true

    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 1
    @State private var thought: String = ""
    @State private var pattern: ThoughtPattern = .none
    @State private var empathy: String = ""
    @State private var patternLine: String = ""
    @State private var verseRef: String = ""
    @State private var verseText: String = ""
    @State private var challenge: String = ""
    @State private var reframe: String = ""

    @State private var isAnalyzing = false
    private let totalSteps = 5
    private let ai = ReframeAIService()

    var body: some View {
        ZStack {
            VStack {
                ProgressView(value: Double(step), total: Double(totalSteps))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer()

                Group {
                    switch step {
                    case 1: stepThought
                    case 2: stepAIInsight
                    case 3: stepVerse
                    case 4: stepChallenge
                    case 5: stepReframe
                    default: EmptyView()
                    }
                }
                .padding(16)

                Spacer()

                HStack {
                    if step > 1 {
                        Button("Back") { withAnimation { step -= 1 } }
                    }
                    Spacer()
                    if step < totalSteps {
                        Button(nextLabel) { withAnimation { goNext() } }
                            .buttonStyle(.borderedProminent)
                            .disabled(nextDisabled)
                    } else {
                        Button("Finish") {
                            let entry = ReframeEntry(
                                date: Date(),
                                title: reframe.isEmpty
                                    ? (thought.isEmpty ? "Reframe" : String(thought.prefix(40)))
                                    : String(reframe.prefix(40)),
                                thought: thought.trimmingCharacters(in: .whitespacesAndNewlines),
                                pattern: pattern.rawValue,
                                challenge: challenge.trimmingCharacters(in: .whitespacesAndNewlines),
                                reframe: reframe.trimmingCharacters(in: .whitespacesAndNewlines),
                                anchor: "",
                                verseRef: verseRef,
                                verseText: verseText
                            )
                            onFinish(entry)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding([.horizontal, .bottom], 16)
            }
            .animation(.easeInOut, value: step)
            .blur(radius: comingSoon ? 1.5 : 0)
            .allowsHitTesting(!comingSoon)

            if comingSoon { ComingSoonOverlay() }
        }
    }

    // MARK: - Steps

    private var stepThought: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What’s on your mind?")
                .font(.headline)
            TextEditor(text: $thought)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
                .textInputAutocapitalization(.sentences)
                .overlay(
                    Group {
                        if thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Jot your feelings at this time…")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                )
            Text("You can write freely. We’ll look for patterns together.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var stepAIInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Analyzing with AI…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(empathy.isEmpty ? "Your feelings are valid — thank you for sharing." : empathy)
                    .font(.subheadline)
                Text(patternLine.isEmpty ? "It sounds like this may involve \(pattern.rawValue.lowercased())." : patternLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Thinking pattern", selection: $pattern) {
                    ForEach(ThoughtPattern.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .task(id: step) {
            guard step == 2, !isAnalyzing else { return }
            isAnalyzing = true
            let result = await ai.analyze(thought: thought)
            pattern = result.pattern
            empathy = result.empathy
            patternLine = result.suggestion
            isAnalyzing = false
        }
    }

    private var stepVerse: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A verse for this moment")
                .font(.headline)
            Group {
                if verseRef.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Finding a verse…")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(verseText)
                        .font(.body)
                    Text(verseRef)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button("Pick a different verse") {
                let v = ai.verse(for: pattern)
                verseRef = v.ref
                verseText = v.text
            }
            .buttonStyle(.bordered)
            .padding(.top, 6)
        }
        .task(id: pattern) {
            let v = ai.verse(for: pattern)
            verseRef = v.ref
            verseText = v.text
        }
    }

    private var stepChallenge: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gently challenge it")
                .font(.headline)
            TextEditor(text: $challenge)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
            Text("What evidence supports this thought? What evidence goes against it? What would you tell a friend?")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var stepReframe: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A kinder, truer thought")
                .font(.headline)
            TextEditor(text: $reframe)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
            Text("Try to keep it compassionate and specific. You can lean on the verse above.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Nav helpers
    private var nextLabel: String { step == 2 && isAnalyzing ? "Please wait…" : "Next" }
    private var nextDisabled: Bool {
        if step == 1 { return thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if step == 2 { return isAnalyzing }
        return false
    }

    private func goNext() {
        if step == 1 {
            step = 2
        } else if step == 2 {
            step = 3
        } else if step == 3 {
            step = 4
        } else {
            step += 1
        }
    }
}

// MARK: - Step Views (prefixed to avoid any type name clashes)

private struct RGF_CaptureThoughtStep: View {
    @Binding var thought: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 1: What’s the thought on your mind?")
                .font(.headline)
            TextEditor(text: $thought)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
                .textInputAutocapitalization(.sentences)
        }
    }
}

private struct RGF_DistortionStep: View {
    @Binding var distortion: String
    private let common = [
        "Catastrophizing", "All-or-nothing", "Overgeneralization",
        "Mind-reading", "Fortune-telling", "Should statements",
        "Labeling", "Discounting the positive"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 2: Recognize the pattern")
                .font(.headline)
            TextField("e.g., Catastrophizing, All-or-nothing…", text: $distortion)
                .textFieldStyle(.roundedBorder)

            RGF_WrapChips(items: common) { item in
                Button {
                    distortion = item
                } label: {
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
}

private struct RGF_ChallengeStep: View {
    @Binding var challenge: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 3: Gently challenge it")
                .font(.headline)
            TextEditor(text: $challenge)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
            Text("Consider: What evidence supports this thought? What evidence goes against it? What would you tell a friend?")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct RGF_ReframeStep: View {
    @Binding var reframe: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 4: A kinder, truer thought")
                .font(.headline)
            TextEditor(text: $reframe)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
        }
    }
}

private struct RGF_AnchorStep: View {
    @Binding var anchor: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 5: Anchor")
                .font(.headline)
            TextField("Optional: verse, affirmation, or next small step", text: $anchor)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Layout helper for chips (prefixed)

private struct RGF_WrapChips<Item: Hashable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat = 8
    @ViewBuilder var content: (Item) -> Content

    var body: some View {
        GeometryReader { geo in
            var width: CGFloat = 0
            var height: CGFloat = 0

            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding(.vertical, 4)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geo.size.width) {
                                width = 0
                                height -= d.height + spacing
                            }
                            let result = width
                            if item == items.last { width = 0 } else { width -= d.width + spacing }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(height: intrinsicHeight(for: items.count))
    }

    private func intrinsicHeight(for count: Int) -> CGFloat {
        // Approx layout height for 2–3 rows of chips; keeps it simple.
        min(CGFloat(max(1, (count + 3) / 4)) * 34 + 8, 120)
    }
}
