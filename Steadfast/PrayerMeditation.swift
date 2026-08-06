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

extension PrayerMeditation {
    var analyticsID: String {
        switch audio {
        case .local(let name, _): return name.lowercased()
        case .remote(let url): return url.lastPathComponent.lowercased()
        }
    }
}

enum PrayerMeditationLibrary {
    static let all: [PrayerMeditation] = [
        PrayerMeditation(
            title: "Morning Body Scan",
            audio: .local(name: "MorningMeditationComplete1", ext: "mp3"),
            coverName: "MorningCover1",
            displayDuration: "2:57",
            playbackBackgroundName: "morningRhythmImage"
        ),
        PrayerMeditation(
            title: "Evening Rest",
            audio: .local(name: "eveningwindown1complete", ext: "mp3"),
            coverName: "EveningCover1",
            displayDuration: "3:18",
            playbackBackgroundName: "eveningRhythmImage"
        ),
        PrayerMeditation(
            title: "Panic Attack Relief",
            audio: .local(name: "PanicMeditation", ext: "mp3"),
            coverName: "panicMedCard",
            displayDuration: "8:00",
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        ),
        PrayerMeditation(
            title: "Healing and Renewal",
            audio: .local(name: "healingMeditation", ext: "mp3"),
            coverName: "healingMedCard",
            displayDuration: "4:00",
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        ),
        PrayerMeditation(
            title: "Lord’s Prayer",
            audio: .local(name: "TheLordsPrayer", ext: "mp3"),
            coverName: "lordsPrayerMedCard",
            displayDuration: "4:45",
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        )
    ]
}
