import SwiftUI
import AVFoundation
import UIKit

final class MorningRhythmAudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isDraggingSlider = false
    @Published var didFailToLoadAudio = false
    var onPlaybackEnded: (() -> Void)?

    private let audioFileName: String
    private let audioFileExtension: String
    private let nowPlayingTitle: String
    private let nowPlayingArtworkImageName: String
    private let nowPlayingManager = RhythmNowPlayingManager.shared
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserverToken: NSObjectProtocol?
    private var itemFailedObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var shouldResumeAfterInterruption = false
    private var requestedPlayback = false

    init(audioFileName: String, audioFileExtension: String, nowPlayingTitle: String, nowPlayingArtworkImageName: String) {
        self.audioFileName = audioFileName
        self.audioFileExtension = audioFileExtension
        self.nowPlayingTitle = nowPlayingTitle
        self.nowPlayingArtworkImageName = nowPlayingArtworkImageName
    }

    func configureIfNeeded() {
        guard player == nil else { return }

        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: audioFileExtension) else {
            didFailToLoadAudio = true
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer

        duration = max(playerItem.asset.duration.seconds, 0)
        addTimeObserver(to: newPlayer)
        addPlaybackEndObserver(for: playerItem)
        addItemFailureObserver(for: playerItem)
        addLifecycleObservers()
        configureRemoteCommands()
        logPlaybackState(context: "configureIfNeeded")
        updateNowPlaying()
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

        if let itemFailedObserver {
            NotificationCenter.default.removeObserver(itemFailedObserver)
            self.itemFailedObserver = nil
        }

        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }

        if let appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
            self.appDidBecomeActiveObserver = nil
        }

        if let willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
            self.willResignActiveObserver = nil
        }

        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
            self.routeChangeObserver = nil
        }

        player = nil
        shouldResumeAfterInterruption = false
        requestedPlayback = false
        nowPlayingManager.clearRemoteHandlers()
        nowPlayingManager.clearNowPlaying()
    }

    func togglePlayPause() {
        guard player != nil else { return }
        if isPlaying {
            pausePlayback()
        } else {
            playPlayback()
        }
    }

    func seek(to time: Double) {
        guard let player else { return }
        let bounded = max(0, min(time, duration > 0 ? duration : time))
        let targetTime = CMTime(seconds: bounded, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = bounded
        updateNowPlaying()
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

            refreshPlaybackState(reason: "periodicTimeObserver")
            updateNowPlaying()
        }
    }

    private func addPlaybackEndObserver(for playerItem: AVPlayerItem) {
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            currentTime = duration
            player?.pause()
            requestedPlayback = false
            refreshPlaybackState(reason: "itemDidEnd")
            updateNowPlaying()
            onPlaybackEnded?()
        }
    }

    private func addItemFailureObserver(for playerItem: AVPlayerItem) {
        itemFailedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.logPlaybackState(context: "itemFailedToPlayToEnd")
            self?.refreshPlaybackState(reason: "itemFailedToPlayToEnd")
            self?.updateNowPlaying()
        }
    }

    private func configureRemoteCommands() {
        nowPlayingManager.setRemoteHandlers(
            onPlay: { [weak self] in self?.playPlayback() },
            onPause: { [weak self] in self?.pausePlayback() },
            onSkipForward: { [weak self] interval in self?.skip(by: interval) },
            onSkipBackward: { [weak self] interval in self?.skip(by: -interval) }
        )
    }

    private func playPlayback() {
        guard let player else { return }
        requestedPlayback = true
        AudioSessionManager.shared.configureForBackgroundPlayback()
        if player.timeControlStatus != .playing {
            player.play()
        }
        refreshPlaybackState(reason: "playPlayback")
        updateNowPlaying()
        logPlaybackState(context: "playPlayback")
    }

    private func pausePlayback() {
        requestedPlayback = false
        player?.pause()
        refreshPlaybackState(reason: "pausePlayback")
        updateNowPlaying()
        logPlaybackState(context: "pausePlayback")
    }

    private func updateNowPlaying() {
        nowPlayingManager.updateNowPlaying(
            title: nowPlayingTitle,
            artworkImageName: nowPlayingArtworkImageName,
            elapsed: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
    }

    private func addLifecycleObservers() {
        if interruptionObserver == nil {
            interruptionObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleInterruption(notification: notification)
            }
        }

        if willResignActiveObserver == nil {
            willResignActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillResignActive()
            }
        }

        if appDidBecomeActiveObserver == nil {
            appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
        }

        if routeChangeObserver == nil {
            routeChangeObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.logPlaybackState(context: "routeChange")
            }
        }
    }

    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            shouldResumeAfterInterruption = requestedPlayback || player?.timeControlStatus == .playing
            refreshPlaybackState(reason: "interruptionBegan")
            updateNowPlaying()
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = shouldResumeAfterInterruption || options.contains(.shouldResume)
            shouldResumeAfterInterruption = false
            guard shouldResume else { return }
            reactivateSessionAndResumeIfNeeded()
        @unknown default:
            break
        }
    }

    private func handleAppDidBecomeActive() {
        guard requestedPlayback || shouldResumeAfterInterruption else { return }
        reactivateSessionAndResumeIfNeeded()
    }

    private func handleWillResignActive() {
        logPlaybackState(context: "willResignActive")
    }

    private func reactivateSessionAndResumeIfNeeded() {
        guard let player else { return }
        AudioSessionManager.shared.configureForBackgroundPlayback()
        if player.timeControlStatus != .playing {
            player.play()
        }
        refreshPlaybackState(reason: "reactivateSessionAndResumeIfNeeded")
        updateNowPlaying()
        logPlaybackState(context: "reactivateSessionAndResumeIfNeeded")
    }

    private func refreshPlaybackState(reason: String) {
        guard let player else {
            isPlaying = false
            return
        }
        let playingNow = player.timeControlStatus == .playing && player.rate > 0.0
        if isPlaying != playingNow {
            print("[RhythmAudio] state-sync(\(reason)) -> isPlaying=\(playingNow)")
        }
        isPlaying = playingNow
    }

    private func logPlaybackState(context: String) {
        guard let player else { return }
        let playerID = ObjectIdentifier(player).hashValue
        let itemURL = (player.currentItem?.asset as? AVURLAsset)?.url.absoluteString ?? "nil"
        let route = AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")
        let waitingReason = player.reasonForWaitingToPlay?.rawValue ?? "none"
        let timeSeconds = CMTimeGetSeconds(player.currentTime())
        print("[RhythmAudio] \(context) TimeControlStatus:", player.timeControlStatus.rawValue)
        print("[RhythmAudio] \(context) PlayerID:", playerID, "ItemURL:", itemURL)
        print("[RhythmAudio] \(context) Rate:", player.rate)
        print("[RhythmAudio] \(context) CurrentTime:", timeSeconds, "WaitingReason:", waitingReason)
        print("[RhythmAudio] \(context) Route:", route)
        print("[RhythmAudio] \(context) RequestedPlayback:", requestedPlayback)
        print("[RhythmAudio] \(context) Session active:", AVAudioSession.sharedInstance().isOtherAudioPlaying)
    }

    deinit {
        cleanup()
    }
}

enum DailyRhythmType {
    case morning
    case midday
    case evening

    func isCompleted(in streakManager: StreakManager, on date: Date = Date()) -> Bool {
        switch self {
        case .morning: return streakManager.hasMorningRhythmCompletion(on: date)
        case .midday: return streakManager.hasMiddayRhythmCompletion(on: date)
        case .evening: return streakManager.hasEveningRhythmCompletion(on: date)
        }
    }

    func markCompleted(in streakManager: StreakManager, on date: Date = Date()) {
        switch self {
        case .morning: streakManager.markMorningRhythmCompleted(on: date)
        case .midday: streakManager.markMiddayRhythmCompleted(on: date)
        case .evening: streakManager.markEveningRhythmCompleted(on: date)
        }
    }
}

struct RhythmAudioPlayerView: View {
    let title: String
    let subtitle: String?
    let audioFileName: String
    let audioFileExtension: String
    let backgroundImageName: String
    let rhythmType: DailyRhythmType

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var streakManager: StreakManager
    @StateObject private var viewModel: MorningRhythmAudioPlayerViewModel
    @State private var hasProcessedCompletion = false
    @State private var dismissAfterOverlay = false

    init(
        title: String,
        subtitle: String? = nil,
        audioFileName: String,
        audioFileExtension: String,
        backgroundImageName: String,
        rhythmType: DailyRhythmType
    ) {
        self.title = title
        self.subtitle = subtitle
        self.audioFileName = audioFileName
        self.audioFileExtension = audioFileExtension
        self.backgroundImageName = backgroundImageName
        self.rhythmType = rhythmType
        _viewModel = StateObject(wrappedValue: MorningRhythmAudioPlayerViewModel(
            audioFileName: audioFileName,
            audioFileExtension: audioFileExtension,
            nowPlayingTitle: title,
            nowPlayingArtworkImageName: backgroundImageName
        ))
    }

    var body: some View {
        ZStack {
            Image(backgroundImageName)
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
                        closePlayerAndDismiss()
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
                    Text(title)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                    }
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
                        if hasProcessedCompletion {
                            closePlayerAndDismiss()
                        } else {
                            completeRhythmAndMaybeDismiss(shouldDismiss: true)
                        }
                    } label: {
                        Text(hasProcessedCompletion ? "Done" : "Mark Complete")
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

            if let milestone = streakManager.pendingMilestone {
                StreakMilestoneCelebrationView(milestone: milestone) {
                    streakManager.clearPendingMilestone()
                    if dismissAfterOverlay {
                        closePlayerAndDismiss()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            hasProcessedCompletion = rhythmType.isCompleted(in: streakManager)
            dismissAfterOverlay = false
            viewModel.onPlaybackEnded = {
                completeRhythmAndMaybeDismiss(shouldDismiss: false)
            }
            viewModel.configureIfNeeded()
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

    private func completeRhythmAndMaybeDismiss(shouldDismiss: Bool) {
        if hasProcessedCompletion {
            if shouldDismiss { closePlayerAndDismiss() }
            return
        }

        hasProcessedCompletion = true
        dismissAfterOverlay = shouldDismiss

        rhythmType.markCompleted(in: streakManager)
        StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
        AppReviewManager.shared.registerMeaningfulEvent()

        if streakManager.pendingMilestone == nil, shouldDismiss {
            closePlayerAndDismiss()
        }
    }

    private func closePlayerAndDismiss() {
        viewModel.onPlaybackEnded = nil
        viewModel.cleanup()
        dismiss()
    }
}

struct MorningRhythmAudioPlayerView: View {
    var body: some View {
        RhythmAudioPlayerView(
            title: "Morning Rhythm",
            subtitle: "Start your day with God",
            audioFileName: "SteadfastMorningRhythm",
            audioFileExtension: "mp3",
            backgroundImageName: "morningRhythmImage",
            rhythmType: .morning
        )
    }
}

struct MiddayRhythmAudioPlayerView: View {
    var body: some View {
        RhythmAudioPlayerView(
            title: "Midday Reset",
            subtitle: "Pause and realign with God",
            audioFileName: "SteadfastMiddayReset",
            audioFileExtension: "mp3",
            backgroundImageName: "middayRhythmImage",
            rhythmType: .midday
        )
    }
}

struct EveningRhythmAudioPlayerView: View {
    var body: some View {
        RhythmAudioPlayerView(
            title: "Evening Rhythm",
            subtitle: "Wind down in peace with God",
            audioFileName: "SteadfastEveningRhythm",
            audioFileExtension: "wav",
            backgroundImageName: "eveningRhythmImage",
            rhythmType: .evening
        )
    }
}
