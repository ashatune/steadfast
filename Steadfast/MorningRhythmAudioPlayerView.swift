import SwiftUI
import AVFoundation

final class MorningRhythmAudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isDraggingSlider = false
    @Published var didFailToLoadAudio = false

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserverToken: NSObjectProtocol?

    func configureIfNeeded() {
        guard player == nil else { return }

        guard let url = Bundle.main.url(forResource: "SteadfastMorningRhythm", withExtension: "mp3") else {
            didFailToLoadAudio = true
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer

        duration = max(playerItem.asset.duration.seconds, 0)
        addTimeObserver(to: newPlayer)
        addPlaybackEndObserver(for: playerItem)
    }

    func cleanup() {
        isPlaying = false
        player?.pause()

        if let timeObserverToken, let player {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        if let endObserverToken {
            NotificationCenter.default.removeObserver(endObserverToken)
            self.endObserverToken = nil
        }

        player = nil
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: Double) {
        guard let player else { return }
        let bounded = max(0, min(time, duration > 0 ? duration : time))
        let targetTime = CMTime(seconds: bounded, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = bounded
    }

    func skip(by delta: Double) {
        seek(to: currentTime + delta)
    }

    private func addTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            if !isDraggingSlider {
                currentTime = max(0, time.seconds)
            }

            if let item = player.currentItem {
                let itemDuration = item.duration.seconds
                if itemDuration.isFinite && itemDuration > 0 {
                    duration = itemDuration
                }
            }
        }
    }

    private func addPlaybackEndObserver(for playerItem: AVPlayerItem) {
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            isPlaying = false
            currentTime = duration
            player?.pause()
        }
    }

    deinit {
        cleanup()
    }
}

struct MorningRhythmAudioPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MorningRhythmAudioPlayerViewModel()

    var body: some View {
        ZStack {
            Image("morningRhythmImage")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.40),
                    .black.opacity(0.25),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.25), in: Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Morning Rhythm")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Start your day with God")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 24) {
                    HStack(spacing: 34) {
                        controlButton(systemImage: "gobackward.10", size: 24) {
                            viewModel.skip(by: -10)
                        }

                        Button {
                            viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 96, height: 96)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(.white.opacity(0.42), lineWidth: 1))
                                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .disabled(viewModel.didFailToLoadAudio)

                        controlButton(systemImage: "goforward.10", size: 24) {
                            viewModel.skip(by: 10)
                        }
                    }

                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.currentTime = $0 }
                            ),
                            in: 0...max(viewModel.duration, 1),
                            onEditingChanged: { editing in
                                viewModel.isDraggingSlider = editing
                                if !editing {
                                    viewModel.seek(to: viewModel.currentTime)
                                }
                            }
                        )
                        .tint(.white)
                        .disabled(viewModel.didFailToLoadAudio)

                        HStack {
                            Text(formatTime(viewModel.currentTime))
                            Spacer()
                            Text(formatTime(viewModel.duration))
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.95))
                    }

                    if viewModel.didFailToLoadAudio {
                        Text("Unable to load audio right now.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Button {
                        AppReviewManager.shared.registerMeaningfulEvent()
                        dismiss()
                    } label: {
                        Text("Mark Complete")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.88))
                    .foregroundStyle(.black)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.configureIfNeeded()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    private func controlButton(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(.black.opacity(0.28), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
        }
        .disabled(viewModel.didFailToLoadAudio)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
