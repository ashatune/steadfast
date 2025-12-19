import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    /// Configure playback to continue when the device is locked or the app is backgrounded.
    /// Ensure "Background Modes" -> "Audio, AirPlay, and Picture in Picture" is enabled in Signing & Capabilities.
    func configureForBackgroundPlayback() {
        /// This category and mode keeps meditation audio active in the background.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
    }

    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivation error: \(error)")
        }
    }
}
