import SwiftUI

struct EveningFlowView: View {
    // Timer starts ONLY at circle stage
    var circleTotalSeconds: Int = 60
    var inhaleSecs: Int = 3
    var holdSecs:   Int = 3      // NEW: hold between inhale & exhale
    var exhaleSecs: Int = 6

    private let ambientTrack = "wanderingMeditation.mp3"

    // Pre-circle timings (not part of the 60s)
    private let greetingSeconds: TimeInterval = 2.0
    private let windSeconds: TimeInterval     = 3.0
    private let laydownDisplay: TimeInterval  = 2.5
    private let giveDisplay: TimeInterval     = 8.0
    private let fadeDur: TimeInterval         = 0.6
    private let pauseGap: TimeInterval        = 1.0

    // Holds for “Let’s pray.” and “Let’s breathe.”
    private let prayHold: TimeInterval        = 2.5
    private let breatheHold: TimeInterval     = 4.0

    // Stages (added prayPrompt)
    private enum Stage { case greeting, wind, journal, laydown, give, prayPrompt, prayer, breathePrompt, circle, done }
    private enum Phase { case inhale, hold, exhale }  // NEW: hold

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .greeting

    @Environment(\.colorScheme) private var colorScheme

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }
    private var inkSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8)
    }

    // Visibility flags
    @State private var showGreeting = false
    @State private var showWind = false
    @State private var showJournal = false
    @State private var showLaydown = false
    @State private var showGive = false
    @State private var showPray = false
    @State private var showBreathe = false
    @State private var showCircle = false
    @State private var showDone = false

    // Journal input
    @State private var journal: String = ""

    // Circle + countdown
    @State private var remaining: Int = 60
    @State private var phase: Phase = .inhale
    @State private var phaseRemaining: Int = 0
    @State private var scale: CGFloat = 0.95

    // Timers / scheduling
    @State private var globalTimer: Timer?
    @State private var phaseTimer: Timer?
    @State private var scheduled: [DispatchWorkItem] = []

    // Music toggle (default ON)
    @State private var musicMuted = false

    // Convenience init (kept for your calls)
    init(totalSeconds: Int = 60, inhaleSecs: Int = 3, exhaleSecs: Int = 6) {
        self.circleTotalSeconds = totalSeconds
        self.inhaleSecs = inhaleSecs
        self.exhaleSecs = exhaleSecs
    }

    var body: some View {
        ZStack {
            // Calm clouds
            CalmCloudsBackground(
                base: Theme.bg,
                cloudColors: [Color.purple.opacity(0.74), Color.black.opacity(0.72), Color.blue.opacity(0.60)],
                count: 10, speed: 0.08
            )

            // CONTENT
            Group {
                switch stage {
                case .greeting:
                    centerColumn {
                        if showGreeting {
                            Text("Good evening")
                                .font(.title)
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }

                case .wind:
                    centerColumn {
                        if showWind {
                            Text("Let’s wind down and release the day.")
                                .font(.title3)
                                .foregroundColor(inkSecondary) // consistent, not .secondary
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .journal:
                    centerColumn {
                        if showJournal {
                            VStack(spacing: 16) {
                                Text("What can you lay down for the day?")
                                    .font(.title3)
                                    .foregroundColor(ink)
                                    .multilineTextAlignment(.center)

                                TextField("Write a few words…", text: $journal)
                                    .multilineTextAlignment(.center)
                                    .textInputAutocapitalization(.sentences)
                                    .disableAutocorrection(false)
                                    .padding(.vertical, 10)
                                    .frame(width: 300)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.25))) // subtle, visible
                                    .transition(.opacity)

                                HStack(spacing: 10) {
                                    Button("Skip") { skipJournal() } // NEW
                                        .buttonStyle(.bordered)

                                    Button("Submit") { goToLaydown() }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(journal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            .transition(.opacity)
                        }
                    }

                case .laydown:
                    centerColumn {
                        if showLaydown {
                            Text("Let us lay down:")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .transition(.opacity)
                            Text("“\(journal)”")
                                .font(.title3)
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .give:
                    centerColumn {
                        if showGive {
                            VStack(spacing: 8) {
                                Text("Give it to God.")
                                    .font(.title3).bold()
                                    .foregroundColor(ink)
                                Text("1 Peter 5:7 \n“Casting all your care upon Him; \nfor He cares for you.”")
                                    .font(.title3)
                                    .foregroundColor(inkSecondary)
                            }
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                        }
                    }

                case .prayPrompt:
                    centerColumn {
                        if showPray {
                            Text("Let’s pray.")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }

                case .prayer:
                    centerColumn {
                        EveningPrayerSequence(
                            lines: [
                                "Heavenly Father, thank You for this day.",
                                "I lay down what I cannot carry at Your feet.",
                                "Please watch over my rest tonight.",
                                "Calm my mind and my body.",
                                "I trust You. Amen."
                            ],
                            perLine: 3.5,
                            fade: fadeDur
                        ) {
                            stage = .breathePrompt
                            withAnimation(.easeInOut(duration: fadeDur)) { showBreathe = true }
                            schedule(after: breatheHold) {
                                withAnimation(.easeInOut(duration: fadeDur)) { showBreathe = false }
                                schedule(after: fadeDur) { startCircle() }
                            }
                        }
                    }

                case .breathePrompt:
                    centerColumn {
                        if showBreathe {
                            Text("Let’s breathe.")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }

                case .circle:
                    VStack(spacing: 16) {
                        Spacer()
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

                        Text("Breathe out & surrender what you cannot carry to Him.")
                            .multilineTextAlignment(.center)
                            .font(.callout)
                            .foregroundColor(inkSecondary)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .padding()

                case .done:
                    centerColumn {
                        if showDone {
                            Image(systemName: "moon.stars.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.accent)
                                .transition(.opacity)
                            Text("Peace to you tonight.")
                                .font(.title3).bold()
                                .foregroundColor(ink)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                            Text("God watches over your rest.")
                                .foregroundColor(inkSecondary)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                            Button("Close") { AppReviewManager.shared.registerMeaningfulEvent(); stopAll(); dismiss() }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 6)
                                .transition(.opacity)
                        }
                    }
                }
            }

            // Countdown — ONLY during circle
            if stage == .circle {
                VStack {
                    Spacer()
                    Text(timeString(remaining))
                        .font(.callout).monospacedDigit()
                        .foregroundColor(inkSecondary)
                        .padding(.vertical, 8)
                }
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Evening")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    stopAll()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Back")
            }
            // NEW: Audio toggle (default ON)
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
        .onAppear { startPrelude() }
        .onDisappear { stopAll() }
    }

    // MARK: - Flow
    private func startPrelude() {
        stopAll()

        // Ambient ON (default)
        SoundManager.shared.playAmbient(named: ambientTrack, startVolume: 0.0, loop: true)
        if !musicMuted { SoundManager.shared.fade(to: 0.6, duration: 0.8) }

        // Greeting → Wind → Journal
        stage = .greeting
        withAnimation(.easeInOut(duration: fadeDur)) { showGreeting = true }
        schedule(after: greetingSeconds) {
            withAnimation(.easeInOut(duration: fadeDur)) { showGreeting = false }
            schedule(after: fadeDur + pauseGap) {
                stage = .wind
                withAnimation(.easeInOut(duration: fadeDur)) { showWind = true }
                schedule(after: windSeconds) {
                    withAnimation(.easeInOut(duration: fadeDur)) { showWind = false }
                    schedule(after: fadeDur + pauseGap) {
                        stage = .journal
                        withAnimation(.easeInOut(duration: fadeDur)) { showJournal = true }
                    }
                }
            }
        }
    }

    private func skipJournal() {
        journal = "Tonight’s burdens" // placeholder so laydown step has something gentle
        goToLaydown()
    }

    private func goToLaydown() {
        // Journal → Laydown → Give → PrayPrompt → Prayer → BreathePrompt → Circle
        withAnimation(.easeInOut(duration: fadeDur)) { showJournal = false }
        schedule(after: fadeDur + pauseGap) {
            stage = .laydown
            withAnimation(.easeInOut(duration: fadeDur)) { showLaydown = true }
            schedule(after: laydownDisplay) {
                withAnimation(.easeInOut(duration: fadeDur)) { showLaydown = false }
                schedule(after: fadeDur + pauseGap) {
                    stage = .give
                    withAnimation(.easeInOut(duration: fadeDur)) { showGive = true }
                    schedule(after: giveDisplay) {
                        withAnimation(.easeInOut(duration: fadeDur)) { showGive = false }
                        schedule(after: fadeDur + pauseGap) {
                            stage = .prayPrompt
                            withAnimation(.easeInOut(duration: fadeDur)) { showPray = true }
                            schedule(after: prayHold) {
                                withAnimation(.easeInOut(duration: fadeDur)) { showPray = false }
                                schedule(after: fadeDur) {
                                    stage = .prayer
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func startCircle() {
        stage = .circle
        showCircle = true
        remaining = circleTotalSeconds

        // Global countdown
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            remaining -= 1
            if remaining <= 0 {
                t.invalidate()
                stopPhaseTimer()
                withAnimation(.easeInOut(duration: fadeDur)) { showCircle = false }
                // Ambient OFF
                SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
                schedule(after: 1.0) {
                    stage = .done
                    withAnimation(.easeInOut(duration: fadeDur)) { showDone = true }
                }
            }
        }

        // Breath loop WITH HOLD
        phase = .inhale
        phaseRemaining = inhaleSecs
        animateScale(to: 1.12, seconds: inhaleSecs)
        Haptics.bump()

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                switch phase {
                case .inhale:
                    phase = .hold
                    phaseRemaining = holdSecs
                    // stay at peak size during hold (tiny settle)
                    animateScale(to: 1.12, seconds: 0)
                    Haptics.bump()
                case .hold:
                    phase = .exhale
                    phaseRemaining = exhaleSecs
                    animateScale(to: 0.85, seconds: exhaleSecs)
                    Haptics.bump()
                case .exhale:
                    phase = .inhale
                    phaseRemaining = inhaleSecs
                    animateScale(to: 1.12, seconds: inhaleSecs)
                    Haptics.bump()
                }
            }
        }
    }

    // MARK: - Helpers
    private func animateScale(to target: CGFloat, seconds: Int) {
        withAnimation(.easeInOut(duration: Double(seconds))) { scale = target }
    }

    private func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        let w = DispatchWorkItem(block: block)
        scheduled.append(w)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: w)
    }

    private func stopPhaseTimer() { phaseTimer?.invalidate(); phaseTimer = nil }

    private func stopAll() {
        globalTimer?.invalidate(); globalTimer = nil
        stopPhaseTimer()
        scheduled.forEach { $0.cancel() }
        scheduled.removeAll()
        // Ambient off
        SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
        // reset flags
        showGreeting = false; showWind = false; showJournal = false
        showLaydown = false; showGive = false; showPray = false
        showBreathe = false; showCircle = false; showDone = false
    }

    private func centerColumn<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 16) { Spacer(minLength: 0); content(); Spacer(minLength: 0) }.padding()
    }

    private func titleForPhase(_ p: Phase) -> String {
        switch p {
        case .inhale: return "Inhale"
        case .hold:   return "Hold"
        case .exhale: return "Exhale"
        }
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0)/60, s = max(t,0)%60
        return String(format: "%01d:%02d", m, s)
    }
}

// Sequence view kept as-is (uses your fade timings)
private struct EveningPrayerSequence: View {
    let lines: [String]
    var perLine: TimeInterval = 3.5
    var fade: TimeInterval = 0.6
    var onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    
    @State private var i = 0
    @State private var visible = false
    @State private var started = false
    @State private var cancelled = false

    var body: some View {
        VStack(spacing: 16) {
            if let line = currentLine {
                Text(line)
                    .font(.title3)
                    .foregroundColor(colorScheme == .dark ? .white : .black) 
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: fade), value: visible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { guard !started else { return }; started = true; cancelled = false; play() }
        .onDisappear { cancelled = true }
    }

    private var currentLine: String? {
        guard lines.indices.contains(i) else { return nil }
        return lines[i]
    }

    private func play() {
        guard !cancelled else { return }
        guard lines.indices.contains(i) else { onDone(); return }
        withAnimation(.easeInOut(duration: fade)) { visible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + perLine) {
            guard !cancelled else { return }
            withAnimation(.easeInOut(duration: fade)) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                guard !cancelled else { return }
                i += 1
                play()
            }
        }
    }
}
