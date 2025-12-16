// PrayerMeditationView.swift
import SwiftUI
import AVKit

struct PrayerMeditationView: View {
    let meditation: PrayerMeditation

    @State private var videoPlayer: AVPlayer?
    @State private var audioPlayer: AVPlayer?
    @State private var videoItem: AVPlayerItem?

    @State private var isPlaying = false
    @State private var rateObserver: NSKeyValueObservation?

    var body: some View {
        ZStack {
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
