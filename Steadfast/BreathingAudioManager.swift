import Foundation
import AVFoundation

final class BreathingAudioManager: ObservableObject {
    private var player: AVAudioPlayer?

    func play(_ filename: String, fileExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Missing audio file: \(filename).\(fileExtension)")
            return
        }

        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play audio \(filename): \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
