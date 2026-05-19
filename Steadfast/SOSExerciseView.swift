import SwiftUI
import AVFoundation

struct SOSExerciseView: View {
    enum BreathPhase {
        case inhale
        case exhale
    }

    let title: String
    let subtitle: String
    let audioResource: String
    let audioExtension: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breathPhase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var breathTimer: Timer?

    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false

    @State private var currentVerse = ""
    @State private var showVerse = false
    @State private var verseTask: Task<Void, Never>?

    private let haptic = UIImpactFeedbackGenerator(style: .soft)

    private let groundingVerses = [
        "God is our refuge and strength. — Psalm 46:1",
        "The Lord is near to the brokenhearted. — Psalm 34:18",
        "When I am afraid, I put my trust in You. — Psalm 56:3",
        "Peace I leave with you; My peace I give you. — John 14:27",
        "Be still, and know that I am God. — Psalm 46:10",
        "Cast all your anxiety on Him. — 1 Peter 5:7"
    ]

    var body: some View {
        GeometryReader { geometry in
            let circleSize = min(160.0, geometry.size.width * 0.42)

            ZStack {
                Theme.bg
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { showRandomGroundingVerse() }

                VStack(spacing: 0) {
                    headerSection

                    Spacer()

                    VStack(spacing: 16) {
                        breathingCircle(size: circleSize)

                        Text(breathPhase == .inhale ? "Breathe in" : "Breathe out")
                            .font(.headline)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()

                    if let audioPlayer {
                        MeditationAudioPlayerView(
                            player: audioPlayer,
                            isPlaying: $isPlaying,
                            rewindInterval: 10,
                            forwardInterval: 10,
                            showsRemainingTime: false,
                            controlColor: Theme.ink,
                            timeColor: Theme.inkSecondary,
                            playButtonBackgroundColor: Theme.accent.opacity(0.16),
                            onTogglePlay: togglePlayPause,
                            onRewind: { _ in skip(by: -10) },
                            onForward: { _ in skip(by: 10) },
                            onSeek: seek,
                            onUserInteraction: {}
                        )
                        .tint(Theme.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                if !currentVerse.isEmpty {
                    GroundingVerseOverlay(verse: currentVerse, showVerse: showVerse)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 120)
                        .allowsHitTesting(false)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(Theme.accent)
                .accessibilityLabel("Back")
            }
        }
        .onAppear {
            startBreathingLoop()
            setupAndPlayAudio()
        }
        .onDisappear {
            breathTimer?.invalidate()
            verseTask?.cancel()
            audioPlayer?.pause()
            audioPlayer = nil
            isPlaying = false
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.ink)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)

            Text("Tip: Tap blank space to show a verse.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func breathingCircle(size: CGFloat) -> some View {
        BreathingIconCircle(
            size: size,
            iconName: "SteadfastCROSS1024",
            scale: scale,
            iconScale: 0.45,
            iconShape: nil
        )
    }

    private func startBreathingLoop() {
        animateBreath(to: .inhale)
        breathTimer?.invalidate()
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            animateBreath(to: .exhale)
            breathTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                animateBreath(to: .inhale)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    animateBreath(to: .exhale)
                }
            }
        }
    }

    private func animateBreath(to phase: BreathPhase) {
        breathPhase = phase
        triggerBreathHaptic()
        let duration: Double = phase == .inhale ? 4 : 6
        let targetScale: CGFloat = phase == .inhale ? 1.2 : 0.8
        withAnimation(.easeInOut(duration: duration)) {
            scale = targetScale
        }
    }

    private func triggerBreathHaptic() {
        guard !reduceMotion else { return }
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.45)
    }

    private func showRandomGroundingVerse() {
        verseTask?.cancel()

        let options = groundingVerses.filter { $0 != currentVerse }
        let nextVerse = options.randomElement() ?? groundingVerses.randomElement() ?? ""
        currentVerse = nextVerse

        verseTask = Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showVerse = true
                }
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.2)) {
                    showVerse = false
                }
            }
        }
    }

    private func setupAndPlayAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Unable to configure audio session: \(error.localizedDescription)")
        }

        guard let url = Bundle.main.url(forResource: audioResource, withExtension: audioExtension) else {
            return
        }

        let player = AVPlayer(url: url)
        self.audioPlayer = player
        player.play()
        isPlaying = true
    }

    private func togglePlayPause() {
        guard let audioPlayer else { return }
        if isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
        isPlaying.toggle()
    }

    private func skip(by seconds: Double) {
        guard let audioPlayer else { return }
        let current = audioPlayer.currentTime().seconds
        let duration = audioPlayer.currentItem?.duration.seconds ?? 0
        let target = min(max(current + seconds, 0), duration.isFinite ? duration : current + seconds)
        audioPlayer.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func seek(to seconds: Double) {
        guard let audioPlayer else { return }
        audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
}

private struct GroundingVerseOverlay: View {
    let verse: String
    let showVerse: Bool

    var body: some View {
        VStack {
            Spacer()
            Text(verse)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.surface.opacity(0.94))
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                )
                .opacity(showVerse ? 1 : 0)
            Spacer()
        }
    }
}
