import Foundation

enum MediaSource: Equatable {
    case local(name: String, ext: String)     // bundle: (name.ext)
    case remote(url: URL)                     // Firebase Storage downloadURL later
}

enum PrayerMeditationType: String, Equatable {
    case video
    case audio
    case text
}

struct PrayerMeditation: Identifiable, Equatable {
    let id: UUID
    let title: String
    let video: MediaSource?
    let audio: MediaSource
    let subtitle: String?
    let coverName: String?
    let displayDuration: String?
    let playbackBackgroundName: String
    let type: PrayerMeditationType
    
    init(
        id: UUID = UUID(),
        title: String,
        video: MediaSource? = nil,
        audio: MediaSource,
        subtitle: String? = nil,
        coverName: String? = nil,
        displayDuration: String? = nil,
        playbackBackgroundName: String,
        type: PrayerMeditationType = .video
    ) {
        self.id = id
        self.title = title
        self.video = video
        self.audio = audio
        self.subtitle = subtitle
        self.coverName = coverName
        self.displayDuration = displayDuration
        self.playbackBackgroundName = playbackBackgroundName
        self.type = type
    }
}
