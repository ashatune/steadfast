import SwiftUI

struct MiddayFlowView: View {
    // Total flow length
    var totalSeconds: Int = 90
    var boxCount: Int = 4     // 4–4–4–4 box breathing

    private let ambientTrack = "wanderingMeditation.mp3"

    // Timings
    private let welcomeHold: TimeInterval   = 3.0
    private let heHold: TimeInterval        = 3.0
    private let beginHold: TimeInterval     = 2.5   // “Let’s begin…”
    private let gratitudeHold: TimeInterval = 18.0
    private let thankHold: TimeInterval     = 6.0
    private let breatheHold: TimeInterval   = 3.0
    private let outroHold: TimeInterval     = 3.5   // outro message
    private let fade: TimeInterval          = 0.6

    @Environment(\.dismiss) private var dismiss

    // Stages
    enum Stage { case welcome, he, beginIntro, gratitude, thankGod, breathePrompt, circle, outro, done }
    enum Phase { case inhale, hold1, exhale, hold2 }

    @State private var stage: Stage = .welcome
    @State private var remaining: Int = 90

    @Environment(\.colorScheme) private var colorScheme

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }
    private var inkSecondary: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8)
    }

    // UI flags
    @State private var showWelcome = false
    @State private var showHe = false
    @State private var showBegin = false
    @State private var showPrompt = false
    @State private var pulsePrompt = false
    @State private var showThank = false
    @State private var showBreathe = false
    @State private var showCircle = false
    @State private var showOutro = false

    // Circle
    @State private var phase: Phase = .inhale
    @State private var phaseRemaining: Int = 0
    @State private var scale: CGFloat = 0.95

    // Music
    @State private var musicMuted = false

    // Timers
    @State private var globalTimer: Timer?
    @State private var phaseTimer: Timer?
    @State private var scheduled: [DispatchWorkItem] = []

    var body: some View {
        ZStack {
            // Background
            CalmCloudsBackground(
                base: Theme.bg,
                cloudColors: [
                    Color.purple.opacity(0.54),
                    Color.mint.opacity(0.52),
                    Color.blue.opacity(0.60)
                ],
                count: 10,
                speed: 0.08
            )

            // Content
            Group {
                switch stage {
                case .welcome:
                    CenterStage { if showWelcome { Text("Welcome to your midday reset").font(.title3).bold().foregroundColor(ink).multilineTextAlignment(.center) } }

                case .he:
                    CenterStage { if showHe { Text("He is with you.").font(.title3).foregroundColor(ink).multilineTextAlignment(.center) } }

                case .beginIntro:
                    CenterStage { if showBegin { Text("Let’s begin…").font(.title3).bold().foregroundColor(ink).multilineTextAlignment(.center) } }

                case .gratitude:
                    CenterStage {
                        if showPrompt {
                            Text("Name one thing you’re grateful for in this moment.")
                                .font(.title3)
                                .foregroundColor(inkSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .scaleEffect(pulsePrompt ? 1.04 : 0.96)
                                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsePrompt)
                        }
                    }

                case .thankGod:
                    CenterStage { if showThank { Text("Use this time to thank God.").font(.title3).foregroundColor(ink).multilineTextAlignment(.center) } }

                case .breathePrompt:
                    CenterStage { if showBreathe { Text("Let’s breathe.").font(.title3).bold().foregroundColor(ink).multilineTextAlignment(.center) } }

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
                                    Text(titleForPhase(phase)).font(.headline).foregroundColor(ink)
                                    Text("\(phaseRemaining)s").font(.footnote).monospacedDigit().foregroundColor(inkSecondary)
                                }
                            }
                            Text(scriptureLine(for: phase))
                                .multilineTextAlignment(.center)
                                .font(.title3)
                                .foregroundColor(ink)
                                .padding(.horizontal)
                        }
                    }

                case .outro:
                    CenterStage {
                        if showOutro {
                            Text("Thank yourself for taking this moment to reset with GOD.\nCome back to this whenever you need it.")
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundColor(inkSecondary)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                case .done:
                    CenterStage {
                        VStack(spacing: 14) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.accent)
                            Text("Nice reset.").font(.title3).bold().foregroundColor(ink)
                            Text("Carry this steadiness into your next step.")
                                .foregroundColor(inkSecondary)
                            Button("Close") { AppReviewManager.shared.registerMeaningfulEvent(); stopAll(); dismiss() }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 6)
                        }
                    }
                }
            }

            // Countdown
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
        .navigationTitle("Midday")
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

    // MARK: - Flow logic
    private func start() {
        stopAll()
        remaining = totalSeconds
        stage = .welcome

        // Ambient pad on (default on)
        SoundManager.shared.playAmbient(named: ambientTrack, startVolume: 0.0, loop: true)
        if !musicMuted { SoundManager.shared.fade(to: 0.6, duration: 1.0) }

        // welcome → he → begin → gratitude → thank → breathe → circle
        withAnimation(.easeInOut(duration: fade)) { showWelcome = true }
        schedule(after: welcomeHold) {
            withAnimation(.easeInOut(duration: fade)) { showWelcome = false }
            schedule(after: fade) {
                stage = .he
                withAnimation(.easeInOut(duration: fade)) { showHe = true }
                schedule(after: heHold) {
                    withAnimation(.easeInOut(duration: fade)) { showHe = false }
                    schedule(after: fade) {
                        stage = .beginIntro
                        withAnimation(.easeInOut(duration: fade)) { showBegin = true }
                        schedule(after: beginHold) {
                            withAnimation(.easeInOut(duration: fade)) { showBegin = false }
                            schedule(after: fade) {
                                stage = .gratitude
                                withAnimation(.easeInOut(duration: 0.6)) { showPrompt = true; pulsePrompt = true }
                                schedule(after: gratitudeHold) {
                                    withAnimation(.easeInOut(duration: 0.6)) { showPrompt = false; pulsePrompt = false }
                                    schedule(after: fade) {
                                        stage = .thankGod
                                        withAnimation(.easeInOut(duration: fade)) { showThank = true }
                                        schedule(after: thankHold) {
                                            withAnimation(.easeInOut(duration: fade)) { showThank = false }
                                            schedule(after: fade) {
                                                stage = .breathePrompt
                                                withAnimation(.easeInOut(duration: fade)) { showBreathe = true }
                                                schedule(after: breatheHold) {
                                                    withAnimation(.easeInOut(duration: fade)) { showBreathe = false }
                                                    schedule(after: fade) {
                                                        stage = .circle
                                                        startCircle()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Global timer → outro → done
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            remaining -= 1
            if remaining <= 0 {
                t.invalidate()
                stopPhaseTimer()
                withAnimation(.easeInOut(duration: 0.5)) { showCircle = false }
                // Outro message
                schedule(after: 0.8) {
                    stage = .outro
                    withAnimation(.easeInOut(duration: 0.6)) { showOutro = true }
                    schedule(after: outroHold) {
                        SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
                        withAnimation(.easeInOut(duration: 0.6)) { showOutro = false }
                        schedule(after: 0.6) { stage = .done }
                    }
                }
            }
        }
    }

    // MARK: - Circle
    private func startCircle() {
        showCircle = true
        phase = .inhale
        phaseRemaining = boxCount
        animateScale(to: 1.12, seconds: boxCount)
        haptic(for: .inhale)

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                switch phase {
                case .inhale: phase = .hold1; phaseRemaining = boxCount
                case .hold1:  phase = .exhale; phaseRemaining = boxCount
                              animateScale(to: 0.85, seconds: boxCount)
                              haptic(for: .exhale)
                case .exhale: phase = .hold2; phaseRemaining = boxCount
                case .hold2:  phase = .inhale; phaseRemaining = boxCount
                              animateScale(to: 1.12, seconds: boxCount)
                              haptic(for: .inhale)
                }
            }
        }
    }

    // MARK: - Utilities
    private func haptic(for phase: Phase) {
        switch phase {
        case .inhale: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .exhale: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        default: break
        }
    }

    private func scriptureLine(for p: Phase) -> String {
        switch p {
        case .inhale, .hold1:  return "“Trust in the Lord with all your heart.”"
        case .exhale, .hold2:  return "“He will make straight your paths.”"
        }
    }

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
        SoundManager.shared.fade(to: 0.0, duration: 0.6, stopAfter: true)
    }

    private func titleForPhase(_ p: Phase) -> String {
        switch p {
        case .inhale: "Inhale"
        case .hold1:  "Hold"
        case .exhale: "Exhale"
        case .hold2:  "Hold"
        }
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0)/60, s = max(t,0)%60
        return String(format: "%01d:%02d", m, s)
    }
}
