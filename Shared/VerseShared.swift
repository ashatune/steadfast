import Foundation

struct Verse: Identifiable, Hashable {
    let id: UUID = .init()
    let ref: String

    /// Full Bible text if you have it (optional for anchors)
    var text: String

    /// Breath durations in seconds (used by the breathing loop)
    var breathIn: Int?
    var breathOut: Int?

    /// Optional spoken/narration file in bundle (e.g., "psalm23.mp3")
    var audioFile: String?

    /// Optional text cues that appear on inhale/exhale
    var inhaleCue: String?
    var exhaleCue: String?

    // Primary (flexible) init
    init(
        ref: String,
        text: String = "",
        breathIn: Int? = nil,
        breathOut: Int? = nil,
        audioFile: String? = nil,
        inhaleCue: String? = nil,
        exhaleCue: String? = nil
    ) {
        self.ref = ref
        self.text = text
        self.breathIn = breathIn
        self.breathOut = breathOut
        self.audioFile = audioFile
        self.inhaleCue = inhaleCue
        self.exhaleCue = exhaleCue
    }

    /// ✅ Convenience init for your existing AnchorService calls:
    /// Verse(ref: "Phil 4:6–7",
    ///       breathIn: "Do not be anxious...",
    ///       breathOut: "God’s peace...")
    /// Optionally override seconds if you want something other than 4/6.
    init(
        ref: String,
        breathIn cueIn: String,
        breathOut cueOut: String,
        secondsIn: Int = 4,
        secondsOut: Int = 6,
        audioFile: String? = nil
    ) {
        self.ref = ref
        self.text = ""              // anchors don't require full verse text
        self.breathIn = secondsIn
        self.breathOut = secondsOut
        self.audioFile = audioFile
        self.inhaleCue = cueIn
        self.exhaleCue = cueOut
    }
}
