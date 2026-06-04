import SwiftUI
import AVKit

struct AnchorBreathView: View {
    enum LaunchSource {
        case standard
        case onboarding
    }

    let verse: Verse
    var totalDuration: Int = 90
    var inhaleSecs: Int = 4
    var holdSecs: Int = 4
    var exhaleSecs: Int = 6
    var bgm: MediaSource? = nil
    
    var showBibleLink: Bool = true                 // hide in onboarding
    var launchSource: LaunchSource = .standard
    var shouldSkipOnAppear: Bool = false
    var onSkip: (() -> Void)? = nil
    var onCompleted: (() -> Void)? = nil           // advance onboarding when finished
    
    var showInlineMuteButton: Bool = false    // NEW
    var startMuted: Bool = false              // NEW
    var recordsAnchorCompletion: Bool = true
    var introPrompts: [String] = []
    var introPromptDuration: TimeInterval = 2.75


    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var streakManager: StreakManager
    @State private var phase: Phase = .intro
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
    @StateObject private var breathingAudio = BreathingAudioManager()
    @State private var isVoiceGuidanceEnabled: Bool = true
    @State private var showCenterPlaybackOverlay = false
    @State private var isPaused = false
    @State private var overlayHideTask: DispatchWorkItem?

    // NEW: completion overlay state
    @State private var showCompletion: Bool = false
    @State private var isEndingSession: Bool = false
    @State private var hasRecordedCompletion = false
    @State private var pendingCompletion = false
    @State private var isShowingIntroPrompts = false
    @State private var currentIntroPromptIndex = 0
    @State private var introPromptTask: DispatchWorkItem?

    enum Phase { case intro, inhale, hold, exhale }
    private var resolvedBgm: MediaSource? {
        bgm ?? VerseAudioResolver.track(for: verse)
    }

    var body: some View {
        ZStack {
            if isShowingIntroPrompts {
                introPromptView
                    .transition(.opacity)
            } else {
                // Main breathing UI
                VStack(spacing: 20) {
                    Text(verse.ref).font(.headline)

                Spacer(minLength: 0)

                VStack(spacing: 20) {
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
                            if phase != .intro {
                                Text(phaseLabel + " • \(phaseRemaining)s")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if showCenterPlaybackOverlay {
                            Button {
                                togglePauseResume()
                            } label: {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .padding(20)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }

                    Text(timeString(countdown))
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    if showBibleLink, let parsed = BibleStore.shared.parseReference(verse.ref) {
                        NavigationLink("Open in Bible") {
                            PassageView(book: parsed.book,
                                        chapter: parsed.chapter,
                                        verseStart: parsed.verseStart,
                                        verseEnd: parsed.verseEnd)
                        }
                        .buttonStyle(.bordered)
                        .simultaneousGesture(TapGesture().onEnded {
                            print("ANCHOR_OPEN_BIBLE rawRef=\(verse.ref) parsedBook=\(parsed.book.name) chapter=\(parsed.chapter) verseStart=\(String(describing: parsed.verseStart)) verseEnd=\(String(describing: parsed.verseEnd)) destination=PassageView")
                        })
                    }
                }
                Spacer(minLength: 0)
            }
                .padding()
                .opacity(showCompletion ? 0 : 1) // fade out behind overlay
            }

            if showCompletion {
                if let milestone = streakManager.pendingMilestone {
                    StreakMilestoneCelebrationView(milestone: milestone) {
                        streakManager.clearPendingMilestone()
                        endSession()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    ReturnTomorrowView(onDone: endSession)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Breathe with Scripture")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            if !isShowingIntroPrompts && !showCompletion {
                HStack(spacing: 24) {
                    audioControlButton(
                        systemName: isMusicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        action: toggleMusicMute
                    )
                    .accessibilityLabel("Sound")
                    .accessibilityValue(isMusicMuted ? "Off" : "On")

                    audioControlButton(
                        systemName: isVoiceGuidanceEnabled ? "person.wave.2.fill" : "person.wave.2",
                        action: toggleVoiceGuidance
                    )
                    .opacity(isVoiceGuidanceEnabled ? 1.0 : 0.6)
                    .accessibilityLabel("Voice Guidance")
                    .accessibilityValue(isVoiceGuidanceEnabled ? "On" : "Off")
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isShowingIntroPrompts else { return }
            showPlaybackOverlayTemporarily()
        }
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
            if launchSource == .onboarding {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        teardown()
                        onSkip?()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .onAppear {
            isMusicMuted = startMuted
            guard !shouldSkipOnAppear else {
                onSkip?()
                return
            }
            start()
        }
        .onDisappear { teardown() }
        .animation(.easeInOut(duration: 0.25), value: showCompletion)
        .animation(.easeInOut(duration: 0.35), value: isShowingIntroPrompts)
    }

    // MARK: - Prompts

    private var currentIntroPrompt: String {
        guard introPrompts.indices.contains(currentIntroPromptIndex) else { return "Let's begin." }
        return introPrompts[currentIntroPromptIndex]
    }

    private var introPromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(currentIntroPrompt)
                .id(currentIntroPromptIndex)
                .font(.title3.weight(.medium))
                .foregroundStyle(Theme.cardTitle)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var mainPrompt: String {
        switch phase {
        case .intro:  return "Let's Begin"
        case .inhale: return inhaleText
        case .hold:   return "Hold"
        case .exhale: return exhaleText
        }
    }
    private var phaseLabel: String {
        switch phase {
        case .intro:  return ""
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
    private var inhaleText: String {
        if let cue = verse.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathIn {
            return "Breathe In \(secs)s"
        }
        return splitVerse().0
    }

    private var exhaleText: String {
        if let cue = verse.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty {
            return cue
        }
        if let secs = verse.breathOut {
            return "Breathe Out \(secs)s"
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
        pendingCompletion = false
        hasRecordedCompletion = false
        showCompletion = false
        isEndingSession = false
        scale = 0.95

        setupAudioSession()

        if introPrompts.isEmpty {
            beginBreathingLoop(includeDefaultIntro: true)
        } else {
            beginIntroPrompts()
        }
    }

    private func beginIntroPrompts() {
        phase = .intro
        phaseRemaining = 0
        currentIntroPromptIndex = 0
        isShowingIntroPrompts = true
        scheduleNextIntroPrompt()
    }

    private func scheduleNextIntroPrompt() {
        introPromptTask?.cancel()

        let task = DispatchWorkItem {
            if currentIntroPromptIndex < introPrompts.count - 1 {
                withAnimation(.easeInOut(duration: 0.45)) {
                    currentIntroPromptIndex += 1
                }
                scheduleNextIntroPrompt()
            } else {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isShowingIntroPrompts = false
                }
                beginBreathingLoop(includeDefaultIntro: false)
            }
        }

        introPromptTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + introPromptDuration, execute: task)
    }

    private func beginBreathingLoop(includeDefaultIntro: Bool) {
        introPromptTask?.cancel()
        isShowingIntroPrompts = false
        configureMusicIfNeeded()

        if includeDefaultIntro {
            phase = .intro
            phaseRemaining = launchSource == .onboarding ? 3 : 2
            scale = 0.95
        } else {
            phase = .inhale
            phaseRemaining = inhaleSecs
            playCue(for: .inhale)
            animateScale(to: 1.15, duration: Double(inhaleSecs))
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            guard !isPaused else { return }
            guard phase != .intro else { return }
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                pendingCompletion = true
            }
        }

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !showCompletion else { return } // stop phase changes if completed
            guard !isPaused else { return }
            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                switch phase {
                case .intro:
                    phase = .inhale
                    phaseRemaining = inhaleSecs
                    playCue(for: .inhale)
                    animateScale(to: 1.15, duration: Double(inhaleSecs))
                case .inhale:
                    phase = .hold
                    phaseRemaining = holdSecs
                    playCue(for: .hold)
                    animateScale(to: 1.15, duration: 0.2)
                case .hold:
                    phase = .exhale
                    phaseRemaining = exhaleSecs
                    playCue(for: .exhale)
                    animateScale(to: 0.85, duration: Double(exhaleSecs))
                case .exhale:
                    if pendingCompletion {
                        completeSession()
                        return
                    } else {
                        phase = .inhale
                        phaseRemaining = inhaleSecs
                        playCue(for: .inhale)
                        animateScale(to: 1.15, duration: Double(inhaleSecs))
                    }
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

    private func toggleVoiceGuidance() {
        isVoiceGuidanceEnabled.toggle()
        if !isVoiceGuidanceEnabled {
            breathingAudio.stop()
        }
    }

    private func togglePauseResume() {
        isPaused.toggle()
        showPlaybackOverlayTemporarily()
        if isPaused {
            breathingAudio.stop()
        } else {
            resumePhaseAnimation()
        }
    }

    private func showPlaybackOverlayTemporarily() {
        overlayHideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showCenterPlaybackOverlay = true
        }
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                showCenterPlaybackOverlay = false
            }
        }
        overlayHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: task)
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
        guard !isEndingSession else { return }
        isEndingSession = true

        // Fade out music then complete
        fadeMusicVolume(to: 0.0, over: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            teardown()
            AppReviewManager.shared.registerMeaningfulEvent()
            AppReviewManager.shared.attemptPromptIfEligible(reason: "completed meditation")
            switch launchSource {
            case .onboarding:
                onCompleted?()
            case .standard:
                if let onCompleted = onCompleted {
                    onCompleted()
                } else {
                    dismiss()
                }
            }
        }
    }

    private func completeSession() {
        phaseTimer?.invalidate(); phaseTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        introPromptTask?.cancel(); introPromptTask = nil
        isShowingIntroPrompts = false
        isPaused = false
        overlayHideTask?.cancel(); overlayHideTask = nil
        showCenterPlaybackOverlay = false
        if recordsAnchorCompletion && !hasRecordedCompletion {
            hasRecordedCompletion = true
            streakManager.markAnchorCompleted()
            StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            showCompletion = true
        }
        Haptics.success()
    }

    private func teardown() {
        phaseTimer?.invalidate(); phaseTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        introPromptTask?.cancel(); introPromptTask = nil
        isShowingIntroPrompts = false
        isPaused = false
        overlayHideTask?.cancel(); overlayHideTask = nil
        showCenterPlaybackOverlay = false
        breathingAudio.stop()
        musicQueue?.pause(); musicQueue = nil
        musicLooper = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func playCue(for phase: Phase) {
        guard !isPaused else { return }
        guard isVoiceGuidanceEnabled else { return }
        switch phase {
        case .intro:
            return
        case .inhale:
            breathingAudio.play("breathein")
        case .hold:
            breathingAudio.play("hold")
        case .exhale:
            breathingAudio.play("breatheout")
        }
    }

    @ViewBuilder
    private func audioControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func resumePhaseAnimation() {
        switch phase {
        case .intro:
            break
        case .inhale:
            animateScale(to: 1.15, duration: Double(max(phaseRemaining, 1)))
        case .hold:
            animateScale(to: 1.15, duration: 0.2)
        case .exhale:
            animateScale(to: 0.85, duration: Double(max(phaseRemaining, 1)))
        }
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
