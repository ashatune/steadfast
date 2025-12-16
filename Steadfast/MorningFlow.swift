import SwiftUI

struct MorningFlowView: View {
    let verse: Verse
    private let ambientTrack = "wanderingMeditation.mp3"


    // Total flow config (3 minutes)
    var totalSeconds: Int = 180
    var inhaleSecs: Int = 4
    var holdSecs:   Int = 4          // NEW: hold between inhale/exhale
    var exhaleSecs: Int = 6

    // Stage timings
    private let greetingSeconds: TimeInterval      = 3.0    // “Good morning”
    private let prepSeconds: TimeInterval          = 4.0    // “Let’s ground…”
    private let comfortSeconds: TimeInterval       = 4.0    // “HE cares…”
    private let prayIntroSeconds: TimeInterval     = 2.5    // NEW: “Let us pray”
    private let breatheIntroSeconds: TimeInterval  = 2.5    // NEW: “Let’s breathe”
    private let prayerPerLineSeconds: TimeInterval = 4.5
    private let verseSeconds: TimeInterval         = 12.0
    private let promptOverlaySeconds: TimeInterval = 12.0

    // NOTE: added prayIntro & breatheIntro; circle now has hold
    private enum Stage { case greeting, prep, comfort, prayIntro, prayer, verse, promptOverlay, breatheIntro, circle, done }
    private enum BreathPhase { case inhale, hold, exhale }

    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.colorScheme) private var colorScheme

    // Flow state
    @State private var stage: Stage = .greeting
    @State private var remaining: Int = 180
    @State private var startTime: Date?

    // Consistent bright text color
    /*private let ink = Color.white
    private let inkSecondary = Color.white.opacity(0.9)*/
    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }
    private var inkSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8)
    }

    // UI flags
    @State private var showGreeting = false
    @State private var showPrep = false
    @State private var showComfort = false
    @State private var showPrayIntro = false
    @State private var showVerse = false
    @State private var showPrompt = false
    @State private var pulsePrompt = false
    @State private var showBreatheIntro = false

    // Prayer sequence
    @State private var prayerIndex = 0
    @State private var prayerVisible = false
    @State private var prayerTask: Task<Void, Never>?

    // Circle state
    @State private var showCircle = false
    @State private var phase: BreathPhase = .inhale
    @State private var phaseRemaining: Int = 0
    @State private var scale: CGFloat = 0.95

    // Music toggle
    @State private var musicMuted = false

    // Timers
    @State private var globalTimer: Timer?
    @State private var phaseTimer: Timer?
    @State private var scheduled: [DispatchWorkItem] = []

    var body: some View {
        ZStack {
            // Calm clouds
            CalmCloudsBackground(
                base: Theme.bg,
                cloudColors: [
                    Color.blue.opacity(0.74),
                    Color.mint.opacity(0.52),
                    Color.purple.opacity(0.80)
                ],
                count: 10,
                speed: 0.08
            )

            // CONTENT
            Group {
                switch stage {
                case .greeting:
                    CenterStage {
                        if showGreeting {
                            Text("Good morning")
                                .font(.title).bold()
                                .foregroundColor(ink)
                                .transition(.opacity)
                        }
                    }

                case .prep:
                    CenterStage {
                        if showPrep {
                            Text("Let’s ground ourselves for the day,\nand spend a few minutes with your Creator.")
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundColor(inkSecondary)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .comfort:
                    CenterStage {
                        if showComfort {
                            Text("HE cares about you.")
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundColor(ink)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .prayIntro: // NEW
                    CenterStage {
                        if showPrayIntro {
                            Text("Let us pray")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .prayer:
                    CenterStage {
                        if let line = currentPrayerLine {
                            Text(line)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundColor(ink)
                                .padding(.horizontal, 20)
                                .opacity(prayerVisible ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6), value: prayerVisible)
                                .transition(.opacity)
                        }
                    }

                case .verse:
                    CenterStage {
                        if showVerse {
                            VStack(spacing: 10) {
                                Text(verse.ref).font(.headline).foregroundColor(inkSecondary)
                                Text(verseTextOrFetch())
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(ink)
                                    .padding(.horizontal)
                            }
                            .transition(.opacity)
                        }
                    }

                case .promptOverlay:
                    CenterStage {
                        VStack(spacing: 18) {
                            Text("What does this verse mean to you as you prepare for today?")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(inkSecondary)
                                .padding(.horizontal)
                                .scaleEffect(pulsePrompt ? 1.04 : 0.96)
                                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsePrompt)
                                .opacity(showPrompt ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6), value: showPrompt)

                            VStack(spacing: 8) {
                                Text(verse.ref).font(.headline).foregroundColor(inkSecondary)
                                Text(verseTextOrFetch())
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(ink)
                                    .padding(.horizontal)
                            }
                            .opacity(showVerse ? 1 : 0)
                            .animation(.easeInOut(duration: 0.6), value: showVerse)
                        }
                    }

                case .breatheIntro: // NEW
                    CenterStage {
                        if showBreatheIntro {
                            Text("Let’s breathe")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .circle:
                    CenterStage {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(.thinMaterial, lineWidth: 8)
                                    .frame(width: 220, height: 220)
                                    .scaleEffect(scale)
                                    .opacity(showCircle ? 1 : 0)
                                VStack(spacing: 6) {
                                    Text(titleForPhase(phase))
                                        .font(.headline)
                                        .foregroundColor(ink)
                                    Text("\(phaseRemaining)s")
                                        .font(.footnote)
                                        .foregroundColor(inkSecondary)
                                        .monospacedDigit()
                                }
                                .opacity(showCircle ? 1 : 0)
                            }
                            Text("“This is the day the Lord has made; I will rejoice and be glad in it.”")
                                .multilineTextAlignment(.center)
                                .font(.callout)
                                .foregroundColor(inkSecondary)
                                .padding(.horizontal)
                        }
                    }

                case .done:
                    CenterStage {
                        VStack(spacing: 14) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.accent)
                            Text("Well done.")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                            Text("Take this steady heart into your day.")
                                .foregroundColor(inkSecondary)
                            Button("Close") {
                                AppReviewManager.shared.registerMeaningfulEvent()
                                dismissAndStop() }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 6)
                        }
                    }
                }
            }
            .padding()

            // Bottom countdown
            VStack {
                Spacer()
                Text(timeString(remaining))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundColor(inkSecondary)
                    .padding(.vertical, 8)
            }
            .padding(.bottom, 28)
        }
        .navigationTitle("Morning")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismissAndStop() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            // Music toggle (default ON)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    musicMuted.toggle()
                    if musicMuted {
                        SoundManager.shared.fade(to: 0.0, duration: 0.3, stopAfter: true)
                    } else {
                        SoundManager.shared.playAmbient(named: ambientTrack, startVolume: 0.0, loop: true)
                        SoundManager.shared.fade(to: 0.6, duration: 0.6)
                    }
                } label: {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.headline)
                }
                .accessibilityLabel(musicMuted ? "Unmute music" : "Mute music")
            }
        }
        .onAppear { start() }
        .onDisappear { stopAll() }
    }

    // MARK: - Flow
    private func start() {
        stopAll()
        remaining = totalSeconds
        startTime = Date()
        stage = .greeting

        // Ambient pad on (default on)
        SoundManager.shared.playAmbient(named: ambientTrack, startVolume: 0.0, loop: true)
        if !musicMuted { SoundManager.shared.fade(to: 0.6, duration: 1.0) }


        withAnimation(.easeInOut(duration: 0.6)) { showGreeting = true }
        schedule(after: greetingSeconds) {
            withAnimation(.easeInOut(duration: 0.6)) { showGreeting = false }
            stage = .prep
            withAnimation(.easeInOut(duration: 0.6)) { showPrep = true }
            schedule(after: prepSeconds) {
                withAnimation(.easeInOut(duration: 0.6)) { showPrep = false }
                stage = .comfort
                withAnimation(.easeInOut(duration: 0.6)) { showComfort = true }
                schedule(after: comfortSeconds) {
                    withAnimation(.easeInOut(duration: 0.6)) { showComfort = false }

                    // NEW: brief “Let us pray”
                    stage = .prayIntro
                    withAnimation(.easeInOut(duration: 0.6)) { showPrayIntro = true }
                    schedule(after: prayIntroSeconds) {
                        withAnimation(.easeInOut(duration: 0.6)) { showPrayIntro = false }

                        // Prayer sequence (multi-prompt)
                        stage = .prayer
                        startPrayerSequence()
                    }
                }
            }
        }

        // Global countdown
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            remaining -= 1
            if remaining <= 0 {
                t.invalidate()
                stopBreathTimer()
                SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
                stage = .done
            }
        }
    }

    private func startPrayerSequence() {
        prayerTask?.cancel()
        prayerIndex = 0
        prayerVisible = false

        prayerTask = Task {
            for i in prayerLines.indices {
                await MainActor.run {
                    prayerIndex = i
                    withAnimation(.easeInOut(duration: 0.6)) { prayerVisible = true }
                }
                try? await Task.sleep(nanoseconds: UInt64(prayerPerLineSeconds * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) { prayerVisible = false }
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                if Task.isCancelled { return }
            }

            // After prayer → verse
            await MainActor.run {
                stage = .verse
                withAnimation(.easeInOut(duration: 0.6)) { showVerse = true }
            }
            try? await Task.sleep(nanoseconds: UInt64(verseSeconds * 1_000_000_000))

            // → pulsing prompt overlay (keep verse visible)
            await MainActor.run {
                stage = .promptOverlay
                showPrompt = true
                pulsePrompt = true
            }
            try? await Task.sleep(nanoseconds: UInt64(promptOverlaySeconds * 1_000_000_000))

            // fade out prompt + verse, then “Let’s breathe”, then circle
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showPrompt = false
                    pulsePrompt = false
                    showVerse = false
                }
            }
            try? await Task.sleep(nanoseconds: 600_000_000)

            await MainActor.run {
                stage = .breatheIntro
                withAnimation(.easeInOut(duration: 0.6)) { showBreatheIntro = true }
            }
            try? await Task.sleep(nanoseconds: UInt64(breatheIntroSeconds * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) { showBreatheIntro = false }
                startCircleForRemaining()
            }
        }
    }

    private var currentPrayerLine: String? {
        guard prayerLines.indices.contains(prayerIndex) else { return nil }
        return prayerLines[prayerIndex]
    }

    private func startCircleForRemaining() {
        let elapsed = Int(Date().timeIntervalSince(startTime ?? Date()))
        let remainingForCircle = max(20, totalSeconds - elapsed)
        startCircle(seconds: remainingForCircle)
    }

    private func startCircle(seconds: Int) {
        stage = .circle
        showCircle = true
        phase = .inhale
        phaseRemaining = inhaleSecs
        animateScale(to: 1.12, seconds: inhaleSecs)
        hapticSoft()

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                switch phase {
                case .inhale:
                    phase = .hold
                    phaseRemaining = holdSecs
                    // keep at full size during hold (small settle)
                    animateScale(to: 1.12, seconds: 0)
                    hapticSoft()
                case .hold:
                    phase = .exhale
                    phaseRemaining = exhaleSecs
                    animateScale(to: 0.85, seconds: exhaleSecs)
                    hapticSoft()
                case .exhale:
                    phase = .inhale
                    phaseRemaining = inhaleSecs
                    animateScale(to: 1.12, seconds: inhaleSecs)
                    hapticSoft()
                }
            }
        }
    }

    
    // MARK: - Phase Label Helper
    private func titleForPhase(_ phase: BreathPhase) -> String {
        switch phase {
        case .inhale: return "Inhale"
        case .hold:   return "Hold"
        case .exhale: return "Exhale"
        }
    }

    
    // MARK: - Scheduling / teardown
    private func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        let w = DispatchWorkItem(block: block)
        scheduled.append(w)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: w)
    }

    private func stopBreathTimer() { phaseTimer?.invalidate(); phaseTimer = nil }

    private func stopAll() {
        globalTimer?.invalidate(); globalTimer = nil
        stopBreathTimer()
        scheduled.forEach { $0.cancel() }
        scheduled.removeAll()
        prayerTask?.cancel(); prayerTask = nil
        SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
    }

    private func dismissAndStop() { stopAll(); dismiss() }
    
    private let verseOverrides: [String: String] = [
        "Isaiah 41:10": "Do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand."
    ]

    // MARK: - Helpers
    private func verseTextOrFetch() -> String {
        if let manual = verseOverrides[verse.ref] { return manual }
        if !verse.text.isEmpty { return verse.text }
        if let parsed = BibleStore.shared.parseReference(verse.ref) {
            let vs = BibleStore.shared.passage(book: parsed.book,
                                               chapter: parsed.chapter,
                                               verseStart: parsed.verseStart,
                                               verseEnd: parsed.verseEnd)
            return vs.map { $0.text }.joined(separator: " ")
        }
        return verse.ref
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0)/60, s = max(t,0)%60
        return String(format: "%01d:%02d", m, s)
    }

    private func animateScale(to target: CGFloat, seconds: Int) {
        withAnimation(.easeInOut(duration: Double(seconds))) { scale = target }
    }

    private func hapticSoft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private var prayerLines: [String] {
        [
            "Heavenly Father, thank You for the gift of this new day.",
            "Fill my heart with Your peace and my mind with Your wisdom.",
            "Guide my steps, my words, and my thoughts so that they honor You.",
            "Give me strength for what lies ahead and remind me that I am never alone.",
            "May Your light shine through me today.",
            "Amen."
        ]
    }
}

