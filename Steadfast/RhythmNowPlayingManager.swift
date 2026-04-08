import Foundation
import MediaPlayer
import UIKit

final class RhythmNowPlayingManager {
    static let shared = RhythmNowPlayingManager()

    private let commandCenter = MPRemoteCommandCenter.shared()
    private var configuredCommands = false

    private var onPlay: (() -> Void)?
    private var onPause: (() -> Void)?
    private var onSkipForward: ((Double) -> Void)?
    private var onSkipBackward: ((Double) -> Void)?

    private init() {}

    func setRemoteHandlers(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping (Double) -> Void,
        onSkipBackward: @escaping (Double) -> Void
    ) {
        self.onPlay = onPlay
        self.onPause = onPause
        self.onSkipForward = onSkipForward
        self.onSkipBackward = onSkipBackward

        guard !configuredCommands else { return }
        configuredCommands = true

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.preferredIntervals = [10]

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let action = self?.onPlay else { return .commandFailed }
            print("[RhythmAudio][Remote] play command received")
            action()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let action = self?.onPause else { return .commandFailed }
            print("[RhythmAudio][Remote] pause command received")
            action()
            return .success
        }

        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let action = self?.onSkipForward else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            print("[RhythmAudio][Remote] skip forward command received interval=\(interval)")
            action(interval)
            return .success
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let action = self?.onSkipBackward else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            print("[RhythmAudio][Remote] skip backward command received interval=\(interval)")
            action(interval)
            return .success
        }
    }

    func clearRemoteHandlers() {
        onPlay = nil
        onPause = nil
        onSkipForward = nil
        onSkipBackward = nil
    }

    func updateNowPlaying(
        title: String,
        artworkImageName: String?,
        elapsed: Double,
        duration: Double,
        isPlaying: Bool
    ) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = title
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, elapsed)
        info[MPMediaItemPropertyPlaybackDuration] = max(0, duration)
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let artworkImageName,
           let image = UIImage(named: artworkImageName) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
