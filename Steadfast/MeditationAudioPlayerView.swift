import SwiftUI
import AVFoundation

final class MeditationPlayerObserver: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isScrubbing = false

    private weak var player: AVPlayer?
    private var timeObserver: Any?

    init(player: AVPlayer) {
        self.player = player
        addObservers(for: player)
    }

    deinit {
        if let token = timeObserver {
            player?.removeTimeObserver(token)
        }
    }

    private func addObservers(for player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            if !isScrubbing {
                currentTime = time.seconds
            }
            if let item = player.currentItem {
                let length = item.duration.seconds
                if length.isFinite {
                    duration = length
                }
            }
        }
    }
}

struct MeditationAudioPlayerView: View {
    @ObservedObject private var observer: MeditationPlayerObserver

    @Binding var isPlaying: Bool

    let rewindInterval: Double
    let onTogglePlay: () -> Void
    let onRewind: (Double) -> Void
    let onSeek: (Double) -> Void
    let onUserInteraction: () -> Void

    init(
        player: AVPlayer,
        isPlaying: Binding<Bool>,
        rewindInterval: Double = 15,
        onTogglePlay: @escaping () -> Void,
        onRewind: @escaping (Double) -> Void,
        onSeek: @escaping (Double) -> Void,
        onUserInteraction: @escaping () -> Void
    ) {
        self.observer = MeditationPlayerObserver(player: player)
        self._isPlaying = isPlaying
        self.rewindInterval = rewindInterval
        self.onTogglePlay = onTogglePlay
        self.onRewind = onRewind
        self.onSeek = onSeek
        self.onUserInteraction = onUserInteraction
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                Button {
                    onUserInteraction()
                    let newTime = max(observer.currentTime - rewindInterval, 0)
                    observer.currentTime = newTime
                    onRewind(rewindInterval)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22, weight: .semibold))
                }

                Button {
                    onUserInteraction()
                    onTogglePlay()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.16)))
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(.white)

            VStack(spacing: 6) {
                Slider(
                    value: Binding(
                        get: { observer.currentTime },
                        set: { newValue in
                            onUserInteraction()
                            observer.currentTime = newValue
                        }
                    ),
                    in: 0...(observer.duration.isFinite && observer.duration > 0 ? observer.duration : 1),
                    onEditingChanged: { editing in
                        onUserInteraction()
                        observer.isScrubbing = editing
                        if !editing {
                            onSeek(observer.currentTime)
                        }
                    }
                )

                HStack {
                    Text(timeString(observer.currentTime))
                    Spacer()
                    let remaining = max((observer.duration.isFinite ? observer.duration : 0) - observer.currentTime, 0)
                    Text("-" + timeString(remaining))
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct MeditationAudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let player = AVPlayer(url: URL(string: "https://www.example.com/audio.mp3")!)
        MeditationAudioPlayerView(
            player: player,
            isPlaying: .constant(true),
            rewindInterval: 15,
            onTogglePlay: {},
            onRewind: { _ in },
            onSeek: { _ in },
            onUserInteraction: {}
        )
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
