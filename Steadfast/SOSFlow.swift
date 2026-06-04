import SwiftUI

// MARK: - Feelings & Modes
enum Feeling: String, CaseIterable, Identifiable {
    case stressedWorried = "Stressed / Worried"
    case panic = "Panic"
    case nervous = "Nervous"
    case selfHarm = "Self-harm urges"
    var id: String { rawValue }
}

private enum SOSStage {
    case autoground
    case choice
    case pathQuickMeditation
    case pathQuickCalm
    case pathPrayer
    case pathEncouragement
    case safety
    case finale
    case done
}

// MARK: - Flow
struct SOSFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("ttsGuidanceEnabled") private var ttsEnabled = false

    // ✅ simple gated function
    private func speak(_ text: String) {
        if ttsEnabled { TTSManager.shared.speak(text) }
    }

    // ✅ helper closure so we can pass it as a parameter
    private var speakFn: (String) -> Void { { text in speak(text) } }

    @State private var feeling: Feeling? = nil
    @State private var stage: SOSStage = .autoground

    private let ambientName = "wanderingMeditation.mp3"

    private let cloudPalette: [Color] = [
        Color.blue.opacity(0.34),
        Color.mint.opacity(0.42),
        Color.pink.opacity(0.80)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                CalmCloudsBackground(
                    base: Theme.bg,
                    cloudColors: cloudPalette,
                    count: 10,
                    speed: 0.08
                )

                stageView()
                    .id(stage)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: stage)
                    .padding()
            }
            .navigationTitle("Breathe and Reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss() }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .onDisappear { SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true) }
    }

    // MARK: - Helpers
    private func startAmbient() {
        SoundManager.shared.playAmbient(named: ambientName, startVolume: 0.0, loop: true)
        SoundManager.shared.fade(to: 0.55, duration: 1.2)
    }

    private func finaleMessages() -> [String] {
        [
            "You showed up for yourself.",
            "God is with you in every breath.",
            "Take the next small step with a steady heart."
        ]
    }

    // MARK: - Extracted switch for compile performance
    @ViewBuilder
    private func stageView() -> some View {
        switch stage {
        case .autoground:
            AutoGroundView(speak: speakFn)
                .onAppear { startAmbient() }
                .onComplete {
                    if feeling == .selfHarm {
                        stage = .safety
                    } else {
                        stage = .choice
                    }
                }

        case .choice:
            MinimalChoiceView(
                title: "You did the right thing.",
                subtitle: "Let’s find peace together.",
                options: [
                    .init(id: "quickMeditation", label: "Quick Meditation", icon: "figure.mind.and.body", action: { stage = .pathQuickMeditation }),
                    .init(id: "quick",  label: "Quick Calm",    icon: "wind",                  action: { stage = .pathQuickCalm }),
                    .init(id: "prayer", label: "Talk to God",   icon: "hands.sparkles.fill",   action: { stage = .pathPrayer }),
                    .init(id: "enc",    label: "Encouragement", icon: "heart.text.square.fill", action: { stage = .pathEncouragement })
                ],
                footerNote: "Stay as long as you need.",
                speak: speakFn
            )

        case .pathQuickMeditation:
            QuickStartMeditationFlow(autoPresentDurations: true) {
                stage = .choice
            }

        case .pathQuickCalm:
            QuickCalmFlow(onDone: { stage = .finale }, speak: speakFn)

        case .pathPrayer:
            GuidedPrayerFlow(onDone: { stage = .finale }, speak: speakFn)

        case .pathEncouragement:
            EncouragementFlow(onDone: { stage = .finale }, speak: speakFn)

        case .safety:
            SafetySupportView(
                onContinue: { stage = .pathQuickCalm },
                onClose: { dismiss() }
            )

        case .finale:
            SOSFinalCalmView(totalDuration: 12, messages: finaleMessages())
                .onComplete { stage = .done }

        case .done:
            SOSDone(restart: {
                stage = .autoground
                feeling = nil
            })
        }
    }
}


// MARK: - AutoGroundView (short intro grounding with inhale/exhale + 2s fade)
private struct AutoGroundView: View {
    private let targetCycles: Int = 2
    private let breathPhaseDuration: TimeInterval = 4
    var speak: (String) -> Void = { _ in }
    @Environment(\.onComplete) private var onComplete

    @State private var remaining: Int = 16
    @State private var breathTimer: Timer?
    @State private var isInhale: Bool = true
    @State private var completedCycles: Int = 0
    @State private var started = false
    @State private var isFadingOut = false
    init(speak: @escaping (String) -> Void = { _ in }) {
        self.speak = speak
    }


    var body: some View {
        VStack(spacing: 18) {
            Text("Let’s start by breathing…")
                .font(.title3).bold()
                .foregroundStyle(Theme.cardTitle)
                .multilineTextAlignment(.center)

            Text("You’re safe. Breathe with me.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                BreathingDot(isInhale: isInhale)
                    .frame(width: 160, height: 160)
                    .accessibilityLabel(isInhale ? "Breathe In" : "Breathe Out")
                Text(isInhale ? "Breathe In…" : "Breathe Out…")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .animation(nil, value: isInhale)
            }

            Spacer()

            Text(timeString(remaining))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(Theme.inkSecondary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isFadingOut ? 0 : 1)
        .animation(.easeInOut(duration: 2), value: isFadingOut)
        .onAppear {
            guard !started else { return }
            started = true
            remaining = targetCycles * 2 * Int(breathPhaseDuration)
            completedCycles = 0
            startBreathCycle()
            speak("Let’s start by breathing.")
        }
        .onDisappear { stopAll() }
    }

    private func startBreathCycle() {
        breathTimer?.invalidate()
        breathTimer = Timer.scheduledTimer(withTimeInterval: breathPhaseDuration, repeats: true) { _ in
            // A full cycle is inhale -> exhale. Count completion only when exhale ends.
            if isInhale {
                // Inhale finished; begin exhale.
                isInhale = false
                remaining = max(remaining - Int(breathPhaseDuration), 0)
                return
            }

            // Exhale finished; cycle is complete.
            completedCycles += 1
            remaining = max(remaining - Int(breathPhaseDuration), 0)

            if completedCycles >= targetCycles {
                // End cleanly at second exhale completion; do not start a third inhale.
                SoundManager.shared.fade(to: 0.35, duration: 2.0)
                stopAll()
                isFadingOut = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete?()
                }
                return
            }

            // Begin next inhale if more cycles are needed.
            isInhale = true
        }
    }

    private func stopAll() {
        breathTimer?.invalidate(); breathTimer = nil
    }

    private func timeString(_ t: Int) -> String {
        let s = max(t, 0)
        return String(format: "00:%02d", s)
    }
}

// Pulser tied to inhale/exhale
private struct BreathingDot: View {
    var isInhale: Bool
    var body: some View {
        Circle()
            .fill(Theme.surface)
            .overlay(Circle().stroke(Theme.accent.opacity(0.25), lineWidth: 10))
            .scaleEffect(isInhale ? 1.08 : 0.82)
            .animation(.easeInOut(duration: 4), value: isInhale)
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}

// MARK: - MinimalChoiceView (with fade-out + speak injection)
private struct MinimalChoiceView: View {
    struct Option: Identifiable {
        let id: String
        let label: String
        let icon: String
        let action: () -> Void
    }

    let title: String
    let subtitle: String
    let options: [Option]
    let footerNote: String
    let speak: (String) -> Void   // ← no default here

    @State private var isFadingOut = false
    
    init(
        title: String,
        subtitle: String,
        options: [Option],
        footerNote: String,
        speak: @escaping (String) -> Void = { _ in }   // ← keep default here
    ) {
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.footerNote = footerNote
        self.speak = speak
    }


    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.title3).bold()
                .foregroundStyle(Theme.cardTitle)
                .multilineTextAlignment(.center)
                .opacity(isFadingOut ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isFadingOut)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .opacity(isFadingOut ? 0 : 1)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isFadingOut)

            VStack(spacing: 10) {
                ForEach(options) { opt in
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) { isFadingOut = true }
                        SoundManager.shared.fade(to: 0.35, duration: 0.5)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            speak(opt.label)
                            opt.action()
                        }
                    } label: {
                        HStack {
                            Label(opt.label, systemImage: opt.icon)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
                        .opacity(isFadingOut ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isFadingOut)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(footerNote)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 6)
                .opacity(isFadingOut ? 0 : 1)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: isFadingOut)
        }
        .opacity(isFadingOut ? 0 : 1)
        .animation(.easeInOut(duration: 0.5), value: isFadingOut)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - QuickCalmFlow (intro → 5-4-3-2-1 → pre-breath → breath)
private struct QuickCalmFlow: View {
    enum Phase { case intro, grounding, preBreath, breath }
    @State private var phase: Phase = .intro

    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    // Ambient config
    private let natureTrack = "oceanWaves.mp3"
    @State private var isMuted = false
    @State private var targetVolume: Double = 0.5
    
    init(onDone: @escaping () -> Void, speak: @escaping (String) -> Void = { _ in }) {
        self.onDone = onDone
        self.speak = speak
    }


    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch phase {
                case .intro:
                    VStack {
                        Spacer()
                        Text("We’re going to ground ourselves by first noticing our surroundings.")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.horizontal)
                        Text("Let’s begin…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                    .onAppear {
                        speak("We’re going to ground ourselves by first noticing our surroundings. Let’s begin.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation { phase = .grounding }
                        }
                    }

                case .grounding:
                    // NOTE: assumes you have Grounding54321View elsewhere in your project
                    Grounding54321View(
                        totalDuration: 55,
                        perStepDurations: [12, 11, 11, 11, 10],
                        verses: [
                            "Psalm 46:1 — God is our refuge.",
                            "Isaiah 41:10 — I am with you.",
                            "2 Tim 1:7 — Power, love, self-control.",
                            "Phil 4:7 — Peace of God will guard you."
                        ],
                        showTitle: false
                    )
                    .onComplete { withAnimation { phase = .preBreath } }

                case .preBreath:
                    VStack {
                        Spacer()
                        Text("Let’s breathe together.")
                            .font(.title3).bold()
                            .foregroundStyle(Theme.cardTitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("Breathe In… Breathe Out… you’re doing great.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                    .onAppear {
                        speak("Let’s breathe together.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { phase = .breath }
                        }
                    }

                case .breath:
                    // NOTE: assumes you have AnchorBreathView elsewhere in your project
                    StageTimer(seconds: 60, onDone: onDone) {
                        AnchorBreathView(
                            verse: Verse(
                                ref: "1 Peter 5:7",
                                breathIn:  "Cast all your care",
                                breathOut: "for He cares for you"
                            ),
                            totalDuration: 60,
                            inhaleSecs: 4,
                            exhaleSecs: 6
                        )
                    }
                }
            }

            // 🔇🔊 Mute toggle for ambience
            Button {
                isMuted.toggle()
                SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.3)
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            }
            .padding([.top, .trailing], 8)
        }
        .onAppear {
            SoundManager.shared.playAmbient(named: natureTrack, startVolume: 0.0, loop: true)
            SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.8)
            speak("You’re doing great. Keep going.")
        }
        .onDisappear {
            SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
        }
    }
}

// MARK: - GuidedPrayerFlow (instruction → prayer script → pre-breath → breath)
private struct GuidedPrayerFlow: View {
    enum Phase { case instruction, prayer, preBreath, breath }
    @State private var phase: Phase = .instruction

    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    private let prayerTrack = "softPad.mp3"
    @State private var isMuted = false
    @State private var targetVolume: Double = 0.5
    
    init(onDone: @escaping () -> Void, speak: @escaping (String) -> Void = { _ in }) {
        self.onDone = onDone
        self.speak = speak
    }


    private let script: [(text: String, duration: TimeInterval)] = [
        ("Lord, still my racing thoughts and calm my body.", 4),
        ("You are near to the brokenhearted and You hold me fast.", 4),
        ("Be my refuge and my peace right now.", 4),
        ("Thank you for your love and for being my guide.", 4),
        ("Your Word says: “Fear not, for I am with you; be not dismayed, for I am your God. I will strengthen you, I will help you, I will uphold you with my righteous right hand.”  Isaiah 41:10", 7),
        ("Thank you for being my rock.", 3),
        ("Amen.", 3)
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch phase {
                case .instruction:
                    VStack(spacing: 16) {
                        ScriptureHeader(ref: "Psalm 46:10", text: "Be still, and know that I am God.")
                        Text("Say these words out loud or to yourself…")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.horizontal)
                        Text("When you’re ready, we’ll pray together.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .onAppear {
                        speak("Say these words out loud or to yourself.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation { phase = .prayer }
                        }
                    }

                case .prayer:
                    TimedScriptView(
                        linesWithDurations: script,
                        onDone: { withAnimation { phase = .preBreath } },
                        speak: speak
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { speak("Let’s talk to God together.") }

                case .preBreath:
                    VStack {
                        Spacer()
                        Text("Let’s breathe…")
                            .font(.title3).bold()
                            .foregroundStyle(Theme.cardTitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("Breathe In… Breathe Out… you’re doing well.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.top, 4)
                        Spacer()
                    }
                    .onAppear {
                        speak("Let’s breathe.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { phase = .breath }
                        }
                    }

                case .breath:
                    StageTimer(seconds: 60, onDone: onDone) {
                        AnchorBreathView(
                            verse: Verse(
                                ref: "Philippians 4:7",
                                breathIn:  "Your peace guards my heart",
                                breathOut: "and my mind in Christ"
                            ),
                            totalDuration: 60,
                            inhaleSecs: 4,
                            exhaleSecs: 6
                        )
                    }
                }
            }

            // 🔇🔊 ambient toggle
            Button {
                isMuted.toggle()
                SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.3)
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            }
            .padding([.top, .trailing], 8)
        }
        .onAppear {
            SoundManager.shared.playAmbient(named: prayerTrack, startVolume: 0.0, loop: true)
            SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.8)
        }
        .onDisappear {
            SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
        }
    }
}

// Shows each line for its own duration with fades and optional TTS
private struct TimedScriptView: View {
    let linesWithDurations: [(text: String, duration: TimeInterval)]
    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    @State private var index = 0
    @State private var visible = false
    @State private var started = false
    @State private var cancelled = false
    
    init(
        linesWithDurations: [(text: String, duration: TimeInterval)],
        onDone: @escaping () -> Void,
        speak: @escaping (String) -> Void = { _ in }
    ) {
        self.linesWithDurations = linesWithDurations
        self.onDone = onDone
        self.speak = speak
    }


    var body: some View {
        VStack(spacing: 12) {
            if let line = current?.text {
                Text(line)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6), value: visible)
            }
        }
        .onAppear { guard !started else { return }; started = true; cancelled = false; step() }
        .onDisappear { cancelled = true; TTSManager.shared.stop() }
    }

    private var current: (text: String, duration: TimeInterval)? {
        linesWithDurations.indices.contains(index) ? linesWithDurations[index] : nil
    }

    private func step() {
        guard !cancelled else { return }
        guard let item = current else { onDone(); return }
        withAnimation { visible = true }
        speak(item.text)
        DispatchQueue.main.asyncAfter(deadline: .now() + item.duration) {
            guard !cancelled else { return }
            withAnimation { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard !cancelled else { return }
                if linesWithDurations.indices.contains(index + 1) { index += 1; step() }
                else { onDone() }
            }
        }
    }
}

// MARK: - EncouragementFlow (instruction → verses → pre-prayer → prayer → pre-breath → breath → closing)
private struct EncouragementFlow: View {
    enum Phase { case instruction, verses, prePrayer1, prePrayer2, prayer, preBreath, breath, closing }
    @State private var phase: Phase = .instruction

    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    private let encouragementTrack = "oceanWaves.mp3"
    @State private var isMuted = false
    @State private var targetVolume: Double = 0.5
    
    init(onDone: @escaping () -> Void, speak: @escaping (String) -> Void = { _ in }) {
        self.onDone = onDone
        self.speak = speak
    }


    private let verses: [String] = [
        "Psalm 46:1 — God is our refuge and strength, an ever-present help in trouble.",
        "Psalm 34:4 — I sought the Lord; He answered me.",
        "Psalm 56:3 — When I am afraid, I trust You.",
        "John 14:27 — My peace I give to you."
    ]

    private let prayerLines: [String] = [
        "Father, I ask for encouragement right now.",
        "Lift my spirit and remind me You are near.",
        "Fill my mind with Your truth and my heart with Your courage.",
        "I praise You for being my help and my song.",
        "Amen."
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch phase {
                case .instruction:
                    PromptView(
                        title: "Say these verses out loud or to yourself…",
                        subtitle: "Let them settle in your heart."
                    )
                    .onAppear {
                        speak("Say these verses out loud or to yourself.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation { phase = .verses }
                        }
                    }

                case .verses:
                    VStack(spacing: 16) {
                        VerseCarousel(
                            verses: verses,
                            perStep: 5.0,
                            fade: 0.6,
                            onDone: { withAnimation { phase = .prePrayer1 } },
                            speak: speak
                        )
                        Text("God is restoring your courage.")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { speak("Receive His word.") }

                case .prePrayer1:
                    PromptView(
                        title: "Let us pray for encouragement…",
                        subtitle: "Open your heart to His comfort."
                    )
                    .onAppear {
                        speak("Let us pray for encouragement.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { phase = .prePrayer2 }
                        }
                    }

                case .prePrayer2:
                    PromptView(
                        title: "Your Heavenly Father wants to hear you",
                        subtitle: "and provide you with confidence..."
                    )
                    .onAppear {
                        speak("Your Heavenly Father wants to hear you and provide you with confidence.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation { phase = .prayer }
                        }
                    }

                case .prayer:
                    TimedLinesView(
                        lines: prayerLines,
                        perStep: 4.0,
                        fade: 0.6,
                        onDone: { withAnimation { phase = .preBreath } },
                        speak: speak
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { speak("Let’s pray together.") }

                case .preBreath:
                    PromptView(
                        title: "Let’s breathe in mindfulness…",
                        subtitle: "Breathe In His peace, Breathe Out your burden..."
                    )
                    .onAppear {
                        speak("Let’s breathe in mindfulness.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { phase = .breath }
                        }
                    }

                case .breath:
                    StageTimer(seconds: 60, onDone: {
                        withAnimation { phase = .closing }
                    }) {
                        AnchorBreathView(
                            verse: Verse(
                                ref: "Joshua 1:9",
                                breathIn:  "Be strong and courageous",
                                breathOut: "for the Lord is with you"
                            ),
                            totalDuration: 60,
                            inhaleSecs: 4,
                            exhaleSecs: 6
                        )
                        .environment(\.onComplete, nil as (() -> Void)?)
                    }

                case .closing:
                    VStack(spacing: 12) {
                        Text("Well done. God is with you.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("You are safe and loved.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .onAppear {
                        speak("Well done. God is with you.")
                        SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.6)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { onDone() }
                    }
                }
            }

            // 🔇🔊 ambience toggle
            Button {
                isMuted.toggle()
                SoundManager.shared.fade(to: Float(isMuted ? 0.0 : targetVolume), duration: 0.3)
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
            }
            .padding([.top, .trailing], 8)
        }
        .onAppear {
            SoundManager.shared.playAmbient(named: encouragementTrack, startVolume: 0.0, loop: true)
            SoundManager.shared.fade(to: Float(targetVolume), duration: 0.8)
            speak("You are not alone. Be encouraged.")
        }
        .onDisappear {
            SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
        }
    }
}

// Simple centered prompt with optional subtitle
private struct PromptView: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.title3).bold()
                .foregroundStyle(Theme.cardTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Small header used in GuidedPrayerFlow
private struct ScriptureHeader: View {
    let ref: String
    let text: String
    var body: some View {
        VStack(spacing: 6) {
            Text(text).font(.title3).foregroundStyle(Theme.cardTitle).multilineTextAlignment(.center)
            Text(ref).font(.footnote).foregroundStyle(Theme.inkSecondary)
        }
        .padding(.bottom, 6)
    }
}

// Timed lines with fades + optional TTS
private struct TimedLinesView: View {
    let lines: [String]
    var perStep: TimeInterval
    var fade: TimeInterval
    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    @State private var index = 0
    @State private var visible = false
    @State private var started = false
    @State private var cancelled = false
    
    init(
        lines: [String],
        perStep: TimeInterval,
        fade: TimeInterval,
        onDone: @escaping () -> Void,
        speak: @escaping (String) -> Void = { _ in }
    ) {
        self.lines = lines
        self.perStep = perStep
        self.fade = fade
        self.onDone = onDone
        self.speak = speak
    }


    var body: some View {
        VStack(spacing: 12) {
            if let line = current {
                Text(line)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: fade), value: visible)
            }
        }
        .onAppear { guard !started else { return }; started = true; cancelled = false; step() }
        .onDisappear { cancelled = true; TTSManager.shared.stop() }
    }

    private var current: String? { lines.indices.contains(index) ? lines[index] : nil }

    private func step() {
        guard !cancelled else { return }
        guard let line = current else { onDone(); return }
        withAnimation(.easeInOut(duration: fade)) { visible = true }
        speak(line)
        DispatchQueue.main.asyncAfter(deadline: .now() + perStep) {
            guard !cancelled else { return }
            withAnimation(.easeInOut(duration: fade)) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                guard !cancelled else { return }
                if lines.indices.contains(index + 1) { index += 1; step() }
                else { onDone() }
            }
        }
    }
}

// Verse carousel with fades + optional TTS
private struct VerseCarousel: View {
    let verses: [String]
    var perStep: TimeInterval
    var fade: TimeInterval
    var onDone: () -> Void
    var speak: (String) -> Void = { _ in }

    @State private var idx = 0
    @State private var visible = false
    @State private var started = false
    @State private var cancelled = false
    
    init(
        verses: [String],
        perStep: TimeInterval,
        fade: TimeInterval,
        onDone: @escaping () -> Void,
        speak: @escaping (String) -> Void = { _ in }
    ) {
        self.verses = verses
        self.perStep = perStep
        self.fade = fade
        self.onDone = onDone
        self.speak = speak
    }


    var body: some View {
        VStack {
            if let v = current {
                Text(v)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: fade), value: visible)
            }
        }
        .onAppear { guard !started else { return }; started = true; cancelled = false; play() }
        .onDisappear { cancelled = true; TTSManager.shared.stop() }
    }

    private var current: String? { verses.indices.contains(idx) ? verses[idx] : nil }

    private func play() {
        guard !cancelled else { return }
        guard let v = current else { onDone(); return }
        withAnimation(.easeInOut(duration: fade)) { visible = true }
        speak(v)
        DispatchQueue.main.asyncAfter(deadline: .now() + perStep) {
            guard !cancelled else { return }
            withAnimation(.easeInOut(duration: fade)) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                guard !cancelled else { return }
                if verses.indices.contains(idx + 1) { idx += 1; play() } else { onDone() }
            }
        }
    }
}

// MARK: - Safety screen
private struct SafetySupportView: View {
    @Environment(\.openURL) private var openURL
    var onContinue: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("You’re not alone.").font(.title3).bold().foregroundStyle(Theme.cardTitle)
            Text("If you feel at risk of harming yourself, please seek immediate help.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.horizontal)

            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: "tel://988") { openURL(url) }
                } label: {
                    Label("Call 988 (US)", systemImage: "phone.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    if let url = URL(string: "sms://741741") { openURL(url) }
                } label: {
                    Label("Text 741741 (US)", systemImage: "message.fill")
                }
                .buttonStyle(.bordered)

                Text("If you’re outside the US, contact your local emergency number or visit the nearest ER.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 4)

            Divider().padding(.vertical, 8)

            Button("I’m safe — continue to a calm exercise") { onContinue() }
                .buttonStyle(.bordered)

            Button("Close") { onClose() }
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - StageTimer
private struct StageTimer<Content: View>: View {
    let seconds: Int
    let onDone: () -> Void
    @ViewBuilder var content: () -> Content
    @State private var fired = false

    var body: some View {
        content()
            .onAppear {
                guard !fired else { return }
                fired = true
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
                    onDone()
                }
            }
    }
}

// MARK: - FinalCalmView (compact, cycles messages then completes)
private struct SOSFinalCalmView: View {
    let totalDuration: Int
    let messages: [String]
    @Environment(\.onComplete) private var onComplete
    @State private var elapsed = 0
    @State private var msgIndex = 0
    @State private var visible = true
    private let tick: TimeInterval = 1

    var body: some View {
        VStack(spacing: 12) {
            if messages.indices.contains(msgIndex) {
                Text(messages[msgIndex])
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: visible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { run() }
    }

    private func run() {
        let changeEvery = 4
        func scheduleTick() {
            DispatchQueue.main.asyncAfter(deadline: .now() + tick) {
                elapsed += 1
                if elapsed % changeEvery == 0 {
                    withAnimation { visible = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        msgIndex = (msgIndex + 1) % max(messages.count, 1)
                        withAnimation { visible = true }
                    }
                }
                if elapsed >= totalDuration { onComplete?() }
                else { scheduleTick() }
            }
        }
        scheduleTick()
    }
}

// MARK: - Done screen
private struct SOSDone: View {
    @Environment(\.dismiss) private var dismiss
    var restart: (() -> Void)? = nil
    var extraLine: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.accent)

            Text("Nice—one small step taken.")
                .font(.title3).bold()
                .foregroundStyle(Theme.cardTitle)

            if let extraLine {
                Text(extraLine)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkSecondary)
            } else {
                Text("Consider a sip of water or sit by a window for a minute.")
                    .foregroundStyle(Theme.inkSecondary)
            }

            HStack(spacing: 12) {
                if let restart {
                    Button { restart() } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                Button("Done") { AppReviewManager.shared.registerMeaningfulEvent();
                    dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
