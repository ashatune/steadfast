// PrayerPlanDetail.swift
import SwiftUI

struct PrayerPlanDetail: View {
    let plan: PrayerPlan
    var body: some View {
        PrayerPlanFlowView(plan: plan)
    }
}




struct PrayerPlanFlowView: View {
    let plan: PrayerPlan

    // Intro frames
    struct IntroFrame: Identifiable { let id = UUID(); let text: String; let seconds: TimeInterval }
    private let fadeDur: TimeInterval = 0.6
    private let pauseGap: TimeInterval = 1.0
    private var introFrames: [IntroFrame] { introsForPlan(plan) }

    // State
    private enum Mode { case intro, steps, done }
    @State private var mode: Mode = .intro
    @State private var introIndex = 0
    @State private var showIntro = false

    @State private var stepIndex = 0
    private var totalSteps: Int { plan.steps.count }
    private var stepText: String { plan.steps[stepIndex] }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "hands.sparkles.fill").foregroundStyle(Theme.accent)
                Text(plan.title).font(.title3).bold()
                Spacer()
                if mode == .steps {
                    Text("\(stepIndex + 1)/\(totalSteps)")
                        .font(.footnote).monospacedDigit()
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .padding(.top, 6)

            // Centered stage area
            CenterStage {
                switch mode {
                case .intro:
                    if introFrames.indices.contains(introIndex), showIntro {
                        Text(introFrames[introIndex].text)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                    }
                case .steps:
                    stepView(for: stepText)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                case .done:
                    doneView.transition(.opacity)
                }
            }

            // Icon-only controls during steps
            if mode == .steps {
                HStack {
                    Button {
                        if stepIndex > 0 { stepIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .opacity(stepIndex == 0 ? 0.35 : 1)
                    .disabled(stepIndex == 0)
                    .accessibilityLabel("Back")

                    Spacer()

                    Button {
                        if stepIndex < totalSteps - 1 {
                            stepIndex += 1
                        } else {
                            withAnimation(.easeInOut(duration: fadeDur)) { mode = .done }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel(stepIndex == totalSteps - 1 ? "Finish" : "Next")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { start() }
    }

    // Intro sequencing
    private func start() {
        if introFrames.isEmpty {
            mode = .steps
        } else {
            mode = .intro
            introIndex = 0
            showIntro = false
            playIntroFrame()
        }
    }

    private func playIntroFrame() {
        guard introFrames.indices.contains(introIndex) else {
            withAnimation(.easeInOut(duration: fadeDur)) { mode = .steps }
            return
        }
        withAnimation(.easeInOut(duration: fadeDur)) { showIntro = true }
        let hold = introFrames[introIndex].seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            withAnimation(.easeInOut(duration: fadeDur)) { showIntro = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseGap) {
                introIndex += 1
                if introIndex < introFrames.count {
                    playIntroFrame()
                } else {
                    withAnimation(.easeInOut(duration: fadeDur)) { mode = .steps }
                }
            }
        }
    }

    // Step rendering
    private enum StepKind {
        case breath(pattern: BreathingView.Pattern, seconds: Int)
        case read(title: String, ref: BibleStore.ParsedRef?, text: String?)
        case pray(text: String)
        case generic(text: String)
    }

    @ViewBuilder
    private func stepView(for text: String) -> some View {
        let kind = parseKind(from: text)
        switch kind {
        case .breath(let pattern, let seconds):
            VStack(spacing: 12) {
                // ▼ no "4–7–8 / Box" title here
                BreathingView(pattern: pattern, totalDuration: seconds, verses: [], showTitle: false)
                Text("Breathe at a gentle pace.")
                    .font(.footnote).foregroundStyle(Theme.inkSecondary)
            }

        case .read(let title, let ref, let verseText):
            VStack(spacing: 12) {
                Text(title).font(.headline).multilineTextAlignment(.center)
                if let verseText, !verseText.isEmpty {
                    Text(verseText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Open your Bible to this passage.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }
                if let parsed = ref {
                    NavigationLink("Open in Bible") {
                        PassageView(book: parsed.book, chapter: parsed.chapter,
                                    verseStart: parsed.verseStart, verseEnd: parsed.verseEnd)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 2)
                }
            }

        case .pray(let prayer):
            VStack(spacing: 12) {
                Text("Pray").font(.headline)
                Text(prayer)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

        case .generic(let body):
            VStack(spacing: 12) {
                Text(body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.accent)
            Text("Amen.").font(.title3).bold()
            Text("Stay here as long as you need.")
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 16)
    }

    // Parsing helpers
    private func parseKind(from raw: String) -> StepKind {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if s.localizedCaseInsensitiveContains("4–7–8") || s.localizedCaseInsensitiveContains("4-7-8")
            || s.localizedCaseInsensitiveContains("settle your breath") {
            return .breath(pattern: .fourSevenEight, seconds: 45)
        }
        if s.localizedCaseInsensitiveContains("box") || s.localizedCaseInsensitiveContains("4–4–4–4")
            || s.localizedCaseInsensitiveContains("4-4-4-4") {
            return .breath(pattern: .box, seconds: 45)
        }

        if s.lowercased().hasPrefix("pray:") {
            let text = s.dropFirst("pray:".count).trimmingCharacters(in: .whitespaces)
            return .pray(text: text.isEmpty ? s : String(text))
        }

        if s.lowercased().hasPrefix("read ") {
            let afterRead = String(s.dropFirst(5))
            let firstCandidate = afterRead.components(separatedBy: " or ").first ?? afterRead
            let ref = BibleStore.shared.parseReference(firstCandidate)
            let verseText = ref.flatMap { fetchVerseText(for: $0) }
            return .read(title: s, ref: ref, text: verseText)
        }

        if s.lowercased() == "amen" {
            return .pray(text: "Amen.")
        }

        return .generic(text: s)
    }

    private func fetchVerseText(for parsed: BibleStore.ParsedRef) -> String? {
        let verses = BibleStore.shared.passage(book: parsed.book,
                                               chapter: parsed.chapter,
                                               verseStart: parsed.verseStart,
                                               verseEnd: parsed.verseEnd)
        guard !verses.isEmpty else { return nil }
        return verses.map { $0.text }.joined(separator: " ")
    }

    private func introsForPlan(_ plan: PrayerPlan) -> [IntroFrame] {
        switch plan.id {
        case "night-peace":
            return [
                .init(text: "Let’s wind down for the evening and spend some time with your Heavenly Father.", seconds: 2.8),
                .init(text: "He wants to hear from you.", seconds: 2.4)
            ]
        case "illness":
            return [.init(text: "You are not alone in this. Let’s bring your body and fears before God.", seconds: 2.8)]
        case "worry":
            return [.init(text: "Set down what you can’t control. God cares for you.", seconds: 2.6)]
        case "daily":
            return [.init(text: "Before your day begins, let’s steady your heart in God’s presence.", seconds: 2.6)]
        case "lords-prayer":
            return [.init(text: "Join Christians across time in the prayer Jesus taught.", seconds: 2.6)]
        default:
            return []
        }
    }
}

