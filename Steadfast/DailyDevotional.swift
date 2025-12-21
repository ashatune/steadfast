import Foundation

struct DailyDevotional: Identifiable, Codable {
    var id: String
    var date: Date
    var title: String
    var verseReference: String
    var verseText: String
    var body: String
    var cta: String?
}

extension DailyDevotional {
    static func placeholder(for date: Date = .now) -> DailyDevotional {
        DailyDevotional(
            id: "placeholder-\(Int(date.timeIntervalSince1970))",
            date: date,
            title: "Rest for the Weary",
            verseReference: "Matthew 11:28–30",
            verseText: "“Come to me, all who labor and are heavy laden, and I will give you rest.”",
            body: "Lay down the weight you are carrying today. Jesus invites you to bring your worries, pace your breath, and rest in His gentle care.",
            cta: "Tap to read today’s devotional"
        )
    }

    var previewSnippet: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 140 { return trimmed }
        let endIdx = trimmed.index(trimmed.startIndex, offsetBy: 140, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        return "\(trimmed[..<endIdx])…"
    }
}
