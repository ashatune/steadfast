import Foundation

enum VerseAudioResolver {
    private static let fallbackFilename = "wanderingMeditation.mp3"

    static func track(for verse: Verse) -> MediaSource? {
        if let file = verse.audioFile, let source = mediaSource(from: file) {
            return source
        }

        if let anchorFile = AnchorService.shared.audioFileName(for: verse.ref),
           let source = mediaSource(from: anchorFile) {
            return source
        }

        return mediaSource(from: AnchorService.shared.defaultAnchorAudioFilename ?? fallbackFilename)
    }

    private static func mediaSource(from filename: String) -> MediaSource? {
        let parts = filename.split(separator: ".")
        guard parts.count == 2 else { return nil }
        return .local(name: String(parts[0]), ext: String(parts[1]))
    }
}
