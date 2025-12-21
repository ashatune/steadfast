import SwiftUI
import AVKit

struct AnchorBreathView: View {
    let verse: Verse
    var totalDuration: Int = 90
    var inhaleSecs: Int = 4
    var holdSecs: Int = 4
    var exhaleSecs: Int = 6
    var bgm: MediaSource? = nil
    
    var showBibleLink: Bool = true                 // hide in onboarding
    var onCompleted: (() -> Void)? = nil           // advance onboarding when finished
    
    var showInlineMuteButton: Bool = false    // NEW
    var startMuted: Bool = false              // NEW


    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .inhale
    @State private var countdown: Int = 90
    @State private var phaseRemaining: Int = 0
    @State private var scale: CGFloat = 0.95

    @State private var phaseTimer: Timer?
    @State private var countdownTimer: Timer?

    // Music
    @State private var musicQueue: AVQueuePlayer?
    @State private var musicLooper: AVPlayerLooper?
    @State private var isMusicMuted: Bool = false
    @State private var musicBaseVolume: Float = 0.28

    // NEW: completion overlay state
    @State private var showCompletion: Bool = false

    enum Phase { case inhale, hold, exhale }
    private var resolvedBgm: MediaSource? {
        bgm ?? VerseAudioResolver.track(for: verse)
    }

    var body: some View {
        ZStack {
            // Main breathing UI
            VStack(spacing: 20) {
                Text(verse.ref).font(.headline)

                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(colors: [Theme.accent2, Theme.accent, Theme.accent2],
                                            center: .center),
                            lineWidth: 8
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(scale)

                    VStack(spacing: 8) {
                        Text(mainPrompt)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.horizontal)
                        Text(phaseLabel + " • \(phaseRemaining)s")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(timeString(countdown))
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                // Replace this block in the body where the link appears:
                if showBibleLink, let parsed = BibleStore.shared.parseReference(verse.ref) {
                    NavigationLink("Open in Bible") {
                        PassageView(book: parsed.book,
                                    chapter: parsed.chapter,
                                    verseStart: parsed.verseStart,
                                    verseEnd: parsed.verseEnd)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .opacity(showCompletion ? 0 : 1) // fade out behind overlay

            // COMPLETION OVERLAY
            if showCompletion {
                Color.black.opacity(0.35).ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    Text("Session Complete")
                        .font(.title2).bold()
                        .foregroundColor(.white) // 👈 bright white headline

                    Text("Thank yourself for being mindful in this moment.\nCarry this calm with you.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9)) // 👈 brighter secondary

                    Button {
                        endSession()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("End Session")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.accent.opacity(0.25), in: Capsule()) // slightly stronger
                        .foregroundColor(.white) // 👈 make button text/icons white
                    }
                    .padding(.top, 6)
                }
                .padding(24)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.55)) // 👈 darker backdrop for more contrast
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.2))
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                .transition(.scale.combined(with: .opacity))

            }
        }
        // Inline mute button overlay (only when requested)
        .overlay(alignment: .topTrailing) {
            if showInlineMuteButton {
                Button {
                    toggleMusicMute()
                } label: {
                    Image(systemName: isMusicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.trailing, 8)
                .accessibilityLabel(isMusicMuted ? "Unmute music" : "Mute music")
            }
        }
        .navigationTitle("Breathe with Scripture")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    teardown() // stop timers + audio session, fade music handled below if you want
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { toggleMusicMute() } label: {
                    Image(systemName: isMusicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.headline)
                }
                .accessibilityLabel(isMusicMuted ? "Unmute music" : "Mute music")
            }
        }
        .onAppear {
            isMusicMuted = startMuted
            start() }
        .onDisappear { teardown() }
        .animation(.easeInOut(duration: 0.25), value: showCompletion)
    }

    // MARK: - Prompts

    private var mainPrompt: String {
        switch phase {
        case .inhale: return inhaleText
        case .hold:   return "Hold"
        case .exhale: return exhaleText
        }
    }
    private var phaseLabel: String {
        switch phase {
        case .inhale: return "Inhale"
        case .hold:   return "Hold"
        case .exhale: return "Exhale"
        }
    }
    private var inhaleText: String {
        if let cue = verse.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathIn {
            return "Inhale \(secs)s"
        }
        return splitVerse().0
    }

    private var exhaleText: String {
        if let cue = verse.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathOut {
            return "Exhale \(secs)s"
        }
        return splitVerse().1
    }

    private func splitVerse() -> (String, String) {
        let t = verse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return (verse.ref, "Be still.") }
        let words = t.split(separator: " ")
        let mid = max(1, words.count / 2)
        let first = words[..<mid].joined(separator: " ")
        let second = words[mid...].joined(separator: " ")
        return (first, second.isEmpty ? first : second)
    }


    // MARK: - Flow / Animation

    private func start() {
        teardown() // clear old timers/players
        countdown = totalDuration

        setupAudioSession()
        configureMusicIfNeeded()

        // breathing loop
        phase = .inhale
        phaseRemaining = inhaleSecs
        animateScale(to: 1.15, duration: Double(inhaleSecs))
        Haptics.bump()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                // Stop the phase timer and SHOW completion (do NOT stop music)
                phaseTimer?.invalidate(); phaseTimer = nil
                showCompletion = true
                Haptics.success()
            }
        }

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !showCompletion else { return } // stop phase changes if completed
            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                switch phase {
                case .inhale:
                    phase = .hold
                    phaseRemaining = holdSecs
                    animateScale(to: 1.15, duration: 0.2)
                case .hold:
                    phase = .exhale
                    phaseRemaining = exhaleSecs
                    animateScale(to: 0.85, duration: Double(exhaleSecs))
                case .exhale:
                    phase = .inhale
                    phaseRemaining = inhaleSecs
                    animateScale(to: 1.15, duration: Double(inhaleSecs))
                }
                Haptics.bump()
            }
        }

        if !isMusicMuted, musicQueue?.timeControlStatus != .playing {
            musicQueue?.play()
        }
    }

    private func animateScale(to target: CGFloat, duration: Double) {
        withAnimation(.easeInOut(duration: duration)) {
            scale = target
        }
    }

    // MARK: - Music

    private func configureMusicIfNeeded() {
        guard let bgm = resolvedBgm, let url = url(for: bgm) else { return }
        if musicQueue == nil || musicLooper == nil {
            let item = AVPlayerItem(url: url)
            let q = AVQueuePlayer(items: [])
            let looper = AVPlayerLooper(player: q, templateItem: item)
            musicQueue = q
            musicLooper = looper
        }
        musicQueue?.volume = isMusicMuted ? 0.0 : musicBaseVolume
    }

    private func toggleMusicMute() {
        isMusicMuted.toggle()
        let target: Float = isMusicMuted ? 0.0 : musicBaseVolume
        fadeMusicVolume(to: target, over: 0.25)
        if isMusicMuted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { musicQueue?.pause() }
        } else {
            musicQueue?.play()
        }
    }

    private func fadeMusicVolume(to target: Float, over duration: TimeInterval) {
        guard let q = musicQueue else { return }
        let steps = 10
        let stepDur = duration / Double(steps)
        let start = q.volume
        let delta = (target - start) / Float(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDur * Double(i)) {
                q.volume = start + delta * Float(i)
            }
        }
    }

    private func url(for source: MediaSource) -> URL? {
        switch source {
        case .local(let name, let ext):
            return Bundle.main.url(forResource: name, withExtension: ext)
        case .remote(let url):
            return url
        }
    }

    // MARK: - Cleanup / End

    private func endSession() {
        // Fade out music then complete
        fadeMusicVolume(to: 0.0, over: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            teardown()
            AppReviewManager.shared.registerMeaningfulEvent()
            AppReviewManager.shared.attemptPromptIfEligible()
            if let onCompleted = onCompleted {
                onCompleted()        // <-- advance onboarding if provided
            } else {
                dismiss()            // fallback to dismiss when used outside onboarding
            }
        }
    }

    private func teardown() {
        phaseTimer?.invalidate(); phaseTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        musicQueue?.pause(); musicQueue = nil
        musicLooper = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio session error: \(error)") }
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0) / 60, s = max(t,0) % 60
        return String(format: "%01d:%02d", m, s)
    }
}
