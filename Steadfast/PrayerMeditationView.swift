// PrayerMeditationView.swift
import SwiftUI
import AVKit

struct PrayerMeditationView: View {
    let meditation: PrayerMeditation

    @State private var videoPlayer: AVPlayer?
    @State private var audioPlayer: AVPlayer?
    @State private var videoItem: AVPlayerItem?

    private let rewindInterval: Double = 15

    @State private var isPlaying = false
    @State private var rateObserver: NSKeyValueObservation?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let player = videoPlayer {
                VideoPlayer(player: player) // keeps native controls
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Optional: a tiny status chip; remove if you don't want it
            if !isPlaying {
                Image(systemName: "play.fill")
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .offset(y: 140)
            }

            if meditation.type == .video, let audioPlayer {
                VStack {
                    Spacer()
                    MeditationAudioPlayerView(
                        player: audioPlayer,
                        isPlaying: $isPlaying,
                        rewindInterval: rewindInterval,
                        onTogglePlay: togglePlayback,
                        onRewind: rewind,
                        onSeek: seek
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            setupAudioSession()
            configurePlayers()
            startPlayback()
            observeVideoRateForSync()
            loopVideo()
        }
        .onDisappear { teardown() }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    teardown()
                    dismiss()
                } label: { Image(systemName: "chevron.left").font(.headline) }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    // MARK: - Setup

    private func url(for source: MediaSource) -> URL? {
        switch source {
        case .local(let name, let ext): return Bundle.main.url(forResource: name, withExtension: ext)
        case .remote(let u): return u
        }
    }

    private func configurePlayers() {
        if let v = url(for: meditation.video) {
            let item = AVPlayerItem(url: v)
            videoItem = item
            let vp = AVPlayer(playerItem: item)
            vp.actionAtItemEnd = .none
            vp.isMuted = true
            videoPlayer = vp
        }
        if let a = url(for: meditation.audio) {
            audioPlayer = AVPlayer(url: a)
        }
    }

    private func startPlayback() {
        videoPlayer?.play()
        audioPlayer?.play()
        isPlaying = true
    }

    private func togglePlayback() {
        if isPlaying {
            videoPlayer?.pause()
            audioPlayer?.pause()
        } else {
            videoPlayer?.play()
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }

    private func rewind(by interval: Double) {
        let currentSeconds = audioPlayer?.currentTime().seconds ?? 0
        let newTime = max(currentSeconds - interval, 0)
        let target = CMTime(seconds: newTime, preferredTimescale: 600)
        audioPlayer?.seek(to: target)
        videoPlayer?.seek(to: target)
        if isPlaying {
            videoPlayer?.play()
            audioPlayer?.play()
        }
    }

    private func seek(to seconds: Double) {
        let safeSeconds = max(seconds, 0)
        let target = CMTime(seconds: safeSeconds, preferredTimescale: 600)
        audioPlayer?.seek(to: target)
        videoPlayer?.seek(to: target)
        if isPlaying {
            videoPlayer?.play()
            audioPlayer?.play()
        }
    }

    private func loopVideo() {
        guard let item = videoItem else { return }
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            videoPlayer?.seek(to: .zero)
            videoPlayer?.play()
        }
    }

    private func observeVideoRateForSync() {
        rateObserver = videoPlayer?.observe(\.rate, options: [.new]) { player, _ in
            DispatchQueue.main.async {
                let playing = player.rate > 0
                isPlaying = playing
                if playing {
                    audioPlayer?.play()
                } else {
                    audioPlayer?.pause()
                }
            }
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio session error: \(error)") }
    }

    private func teardown() {
        NotificationCenter.default.removeObserver(self)
        rateObserver?.invalidate()
        rateObserver = nil
        audioPlayer?.pause()
        videoPlayer?.pause()
        audioPlayer = nil
        videoPlayer = nil
        videoItem = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
