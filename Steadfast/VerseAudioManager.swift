//
//  VerseAudioManager.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/6/25.
//

import AVFoundation
import SwiftUI

final class VerseAudioManager: ObservableObject {
    static let shared = VerseAudioManager()
    @Published private(set) var playing: Set<UUID> = []

    private var players: [UUID: AVAudioPlayer] = [:]
    private var breathTimer: [UUID: Timer] = [:]
    private var chimeIn: AVAudioPlayer?
    private var chimeOut: AVAudioPlayer?

    private init() {
        // Preload chimes if you add them to the bundle (optional)
        chimeIn = loadPlayer(filename: "breathe_in.caf")
        chimeOut = loadPlayer(filename: "breathe_out.caf")
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func isPlaying(_ id: UUID) -> Bool { playing.contains(id) }

    func toggle(verse: Verse, volume: Float = 1.0) {
        isPlaying(verse.id) ? stop(verseID: verse.id) : play(verse: verse, volume: volume)
    }

    func play(verse: Verse, volume: Float = 1.0) {
        guard let file = verse.audioFile else { return }
        let player = players[verse.id] ?? loadPlayer(filename: file)
        guard let p = player else { return }
        p.numberOfLoops = -1
        p.volume = volume
        p.play()
        players[verse.id] = p
        playing.insert(verse.id)
        scheduleBreathCuesIfNeeded(for: verse)
        objectWillChange.send()
    }

    func stop(verseID: UUID) {
        players[verseID]?.stop()
        players[verseID] = nil
        breathTimer[verseID]?.invalidate()
        breathTimer[verseID] = nil
        playing.remove(verseID)
        objectWillChange.send()
    }

    // MARK: - Private
    private func loadPlayer(filename: String) -> AVAudioPlayer? {
        let parts = filename.split(separator: ".")
        guard parts.count == 2,
              let url = Bundle.main.url(forResource: String(parts[0]), withExtension: String(parts[1])) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }

    private func scheduleBreathCuesIfNeeded(for verse: Verse) {
        guard let bi = verse.breathIn, let bo = verse.breathOut, bi > 0, bo > 0 else { return }
        let total = TimeInterval(bi + bo)

        // Fire immediately once per cycle: inhale at t=0, exhale at t=bi
        let id = verse.id
        breathTimer[id]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: total, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.chimeIn?.currentTime = 0; self.chimeIn?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(bi)) {
                self.chimeOut?.currentTime = 0; self.chimeOut?.play()
            }
        }
        breathTimer[id] = timer

        // Kick the first cycle right away
        chimeIn?.currentTime = 0; chimeIn?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(bi)) { [weak self] in
            self?.chimeOut?.currentTime = 0; self?.chimeOut?.play()
        }
    }
}
