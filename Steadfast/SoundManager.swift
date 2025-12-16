import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit // for NSDataAsset on iOS/tvOS
#endif

final class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    // Call once (e.g., app launch)
    // playThroughSilentSwitch: true -> plays even if hardware mute is on.
    func configureAudioSession(playThroughSilentSwitch: Bool = true) {
        do {
            let category: AVAudioSession.Category = playThroughSilentSwitch ? .playback : .ambient
            try AVAudioSession.sharedInstance().setCategory(category, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("🔈 AudioSession error:", error)
        }
    }

    /// Plays an ambient track from the bundle (preferred) or from a Data Asset (fallback).
    func playAmbient(named name: String, startVolume: Float = 0.0, loop: Bool = true) {
        // Try bundle file first
        if let parts = split(name: name),
           let url = Bundle.main.url(forResource: parts.res, withExtension: parts.ext) {
            startPlayer(url: url, startVolume: startVolume, loop: loop)
            return
        }

        // Fallback to Data Asset (only on UIKit platforms)
        #if canImport(UIKit)
        if let parts = split(name: name),
           let dataAsset = NSDataAsset(name: parts.res) {
            startPlayer(data: dataAsset.data, startVolume: startVolume, loop: loop)
            return
        }
        #endif

        print("🚫 Could not find audio resource '\(name)' in bundle or data assets.")
    }

    func fade(to volume: Float, duration: TimeInterval, stopAfter: Bool = false) {
        guard let player = player else { return }
        let steps = max(1, Int(duration * 30)) // ~30 fps fade
        let startVol = player.volume
        let delta = (volume - startVol) / Float(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(i) / Double(steps)) { [weak self] in
                guard let self = self, let p = self.player else { return }
                p.volume = startVol + delta * Float(i)
                if i == steps, stopAfter { p.stop() }
            }
        }
    }

    func stop() { player?.stop(); player = nil }

    // MARK: - Internals

    private func startPlayer(url: URL, startVolume: Float, loop: Bool) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            setupAndPlay(startVolume: startVolume, loop: loop)
        } catch {
            print("🎧 AVAudioPlayer init error:", error)
        }
    }

    private func startPlayer(data: Data, startVolume: Float, loop: Bool) {
        do {
            player = try AVAudioPlayer(data: data)
            setupAndPlay(startVolume: startVolume, loop: loop)
        } catch {
            print("🎧 AVAudioPlayer(data:) init error:", error)
        }
    }

    private func setupAndPlay(startVolume: Float, loop: Bool) {
        guard let player = player else { return }
        player.numberOfLoops = loop ? -1 : 0
        player.volume = startVolume
        player.prepareToPlay()
        player.play()
    }

    /// Splits "filename.ext" into (res: "filename", ext: "ext")
    private func split(name: String) -> (res: String, ext: String)? {
        guard let dot = name.lastIndex(of: ".") else { return nil }
        let res = String(name[..<dot])
        let ext = String(name[name.index(after: dot)...])
        return (res, ext)
    }
}
