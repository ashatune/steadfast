import Foundation

enum MediaSource: Equatable {
    case local(name: String, ext: String)     // bundle: (name.ext)
    case remote(url: URL)                     // Firebase Storage downloadURL later
}

struct PrayerMeditation: Identifiable, Equatable {
    let id: UUID
    let title: String
    let video: MediaSource
    let audio: MediaSource
    let subtitle: String?
    let coverName: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        video: MediaSource,
        audio: MediaSource,
        subtitle: String? = nil,
        coverName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.video = video
        self.audio = audio
        self.subtitle = subtitle
        self.coverName = coverName
    }
}
