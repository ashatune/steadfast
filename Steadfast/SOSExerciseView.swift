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

    @State private var breathPhase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var breathTimer: Timer?

    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        GeometryReader { geometry in
            let circleSize = min(160.0, geometry.size.width * 0.42)

            ZStack {
                Color.white.ignoresSafeArea()

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
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startBreathingLoop()
            setupAndPlayAudio()
        }
        .onDisappear {
            breathTimer?.invalidate()
            audioPlayer?.pause()
            audioPlayer = nil
            isPlaying = false
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Close") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Spacer()
            }

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.ink)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func breathingCircle(size: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.accent.opacity(0.9), Theme.accent2.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .shadow(color: Theme.accent.opacity(0.22), radius: 18, x: 0, y: 8)
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
        let duration: Double = phase == .inhale ? 4 : 6
        let targetScale: CGFloat = phase == .inhale ? 1.2 : 0.8
        withAnimation(.easeInOut(duration: duration)) {
            scale = targetScale
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
