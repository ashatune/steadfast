import SwiftUI
import AVFoundation

struct PanicResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var breathPhase: CalmNowIntroView.BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @StateObject private var audioPlayer = PanicResetAudioPlayer()
    @State private var breathTimer: Timer?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Panic Reset")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text("Let’s slow things down together.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)

                Spacer()

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.9), Theme.accent2.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(scale)
                    .shadow(color: Theme.accent.opacity(0.22), radius: 18, x: 0, y: 8)

                Spacer()

                Button("Close") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startBreathingLoop()
            audioPlayer.play()
        }
        .onDisappear {
            breathTimer?.invalidate()
            audioPlayer.stop()
        }
    }

    private func startBreathingLoop() {
        animateBreath(to: .inhale)
        breathTimer?.invalidate()
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            let nextPhase: CalmNowIntroView.BreathPhase = breathPhase == .inhale ? .exhale : .inhale
            animateBreath(to: nextPhase)
        }
    }

    private func animateBreath(to phase: CalmNowIntroView.BreathPhase) {
        breathPhase = phase
        let targetScale: CGFloat = phase == .inhale ? 1.2 : 0.8
        withAnimation(.easeInOut(duration: 4)) {
            scale = targetScale
        }
    }
}

final class PanicResetAudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func play() {
        configureSession()

        let url = Bundle.main.url(forResource: "SteadfastSOSbodyScan", withExtension: "wav")
            ?? Bundle.main.url(forResource: "PanicMeditation", withExtension: "mp3")

        guard let url else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Unable to play SteadfastSOSbodyScan.wav: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
    }

    private func configureSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Unable to configure audio session: \(error.localizedDescription)")
        }
    }
}
