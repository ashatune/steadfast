import AVFoundation

final class TTSManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSManager()
    private let synth = AVSpeechSynthesizer()

    // Global toggle (gate all speak calls if needed)
    var enabled: Bool = true

    // Preferences (set once at launch or in Settings screen)
    var preferredLanguage: String = "en-US"
    var preferredVoiceIdentifier: String? // if set, use this exact voice when available

    // Ambient ducking for your background pad
    var ambientTargetVolume: Float = 0.6
    var ambientDuckVolume: Float = 0.25

    private override init() {
        super.init()
        synth.delegate = self
    }

    /// Call once at app start. It tries to pick/install the best voice automatically.
    func preparePreferredVoice(languages: [String] = ["en-US", "en-GB"]) {
        // 1) If user has already chosen and it's available, keep it
        if let id = preferredVoiceIdentifier, AVSpeechSynthesisVoice(identifier: id) != nil { return }

        // 2) Pick highest-quality installed for our language list
        let installed = AVSpeechSynthesisVoice.speechVoices()
        if let bestInstalled = installed
            .filter({ languages.contains($0.language) })
            .sorted(by: { $0.quality.rawValue > $1.quality.rawValue })
            .first {
            preferredLanguage = bestInstalled.language
            preferredVoiceIdentifier = bestInstalled.identifier
            return
        }

        // 3) Try known Enhanced/Premium identifiers (iOS may auto-download on first use)
        let candidates = [
            // US English
            "com.apple.ttsbundle.siri_female_en-US_premium",
            "com.apple.ttsbundle.siri_male_en-US_premium",
            "com.apple.ttsbundle.siri_female_en-US_enhanced",
            "com.apple.ttsbundle.siri_male_en-US_enhanced",
            // UK English
            "com.apple.ttsbundle.siri_female_en-GB_premium",
            "com.apple.ttsbundle.siri_male_en-GB_premium",
            "com.apple.ttsbundle.siri_female_en-GB_enhanced",
            "com.apple.ttsbundle.siri_male_en-GB_enhanced"
        ]

        for id in candidates {
            if let v = AVSpeechSynthesisVoice(identifier: id) {
                preferredLanguage = v.language
                preferredVoiceIdentifier = v.identifier
                // 4) Warm-up: speak a silent, 0-volume utterance once to nudge install
                let utt = AVSpeechUtterance(string: " ")
                utt.voice = v
                utt.rate = 0.45
                utt.volume = 0.0
                synth.speak(utt)
                break
            }
        }
    }

    func speak(_ text: String,
               language: String? = nil,
               rate: Float = 0.46,
               pitch: Float = 1.0,
               postDelay: TimeInterval = 0.25) {

        guard enabled else { return }
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }

        // Make sure we can be heard even if hardware mute is on (mix with ambient)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])

        // Duck your ambient pad
        SoundManager.shared.fade(to: ambientDuckVolume, duration: 0.25)

        synth.stopSpeaking(at: .immediate)

        let utt = AVSpeechUtterance(string: line)
        utt.voice = pickBestVoice(language ?? preferredLanguage)
        utt.rate = rate
        utt.pitchMultiplier = pitch
        utt.postUtteranceDelay = postDelay

        synth.speak(utt)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        SoundManager.shared.fade(to: ambientTargetVolume, duration: 0.25)
    }

    private func pickBestVoice(_ lang: String) -> AVSpeechSynthesisVoice? {
        // exact choice
        if let id = preferredVoiceIdentifier,
           let v  = AVSpeechSynthesisVoice(identifier: id) { return v }

        // best installed for language
        let installed = AVSpeechSynthesisVoice.speechVoices()
        if let best = installed
            .filter({ $0.language == lang })
            .sorted(by: { $0.quality.rawValue > $1.quality.rawValue })
            .first {
            return best
        }
        // fallback by language
        return AVSpeechSynthesisVoice(language: lang)
    }

    // Debug helper
    func logVoices() {
        for v in AVSpeechSynthesisVoice.speechVoices() {
            print("• \(v.name) | \(v.language) | quality=\(v.quality.rawValue) | id=\(v.identifier)")
        }
    }

    // Restore ambient after speaking
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        SoundManager.shared.fade(to: ambientTargetVolume, duration: 0.25)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        SoundManager.shared.fade(to: ambientTargetVolume, duration: 0.25)
    }
}
