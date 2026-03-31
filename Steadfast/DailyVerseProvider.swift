import Foundation

struct DailyVerseProvider {
    static let shared = DailyVerseProvider()

    private let dayKeyKey = "daily_verse_dayKey"
    private let refKey = "daily_verse_ref"
    private let textKey = "daily_verse_text"
    private let breathInKey = "daily_verse_breathIn"
    private let breathOutKey = "daily_verse_breathOut"
    private let inhaleCueKey = "daily_verse_inhaleCue"
    private let exhaleCueKey = "daily_verse_exhaleCue"
    private let cacheKey = "daily_verse_cache"

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    func verse(for date: Date = Date(), calendar: Calendar = Calendar.current) -> Verse {
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        if let cached = cachedVerse(for: dayKey) {
            return cached
        }

        if let stored = storedVerse(for: dayKey) {
            return stored
        }

        let selected = selectVerse(for: date, calendar: calendar)
        persist(selected, for: dayKey)
        return selected
    }

    func anchorBannerLine(for verse: Verse?) -> (String, String) {
        let title = "Anchor Verse of the Day"
        guard let v = verse else {
            return (title, "“Be still, and know that I am God.” — Psalm 46:10")
        }

        let text = v.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let ref = v.ref.trimmingCharacters(in: .whitespacesAndNewlines)

        let biStr: String = {
            if let cue = v.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
            if let secs = v.breathIn { return "Breathe In \(secs)s" }
            return ""
        }()

        let boStr: String = {
            if let cue = v.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines), !cue.isEmpty { return cue }
            if let secs = v.breathOut { return "Breathe Out \(secs)s" }
            return ""
        }()

        if !text.isEmpty {
            return (title, "“\(text)”" + (ref.isEmpty ? "" : " — \(ref)"))
        }

        let parts = [biStr, boStr].filter { !$0.isEmpty }
        if !parts.isEmpty {
            let line = parts.joined(separator: " / ")
            return (title, "“\(line)”" + (ref.isEmpty ? "" : " — \(ref)"))
        }

        if !ref.isEmpty {
            return (title, ref)
        }
        return (title, "“Be still, and know that I am God.” — Psalm 46:10")
    }

    private func cachedVerse(for dayKey: String) -> Verse? {
        guard let data = defaults.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: StoredVerse].self, from: data),
              let stored = cache[dayKey] else { return nil }
        return stored.toVerse()
    }

    private func storedVerse(for dayKey: String) -> Verse? {
        guard defaults.string(forKey: dayKeyKey) == dayKey,
              let ref = defaults.string(forKey: refKey) else { return nil }

        let stored = StoredVerse(
            ref: ref,
            text: defaults.string(forKey: textKey) ?? "",
            breathIn: defaults.object(forKey: breathInKey) as? Int,
            breathOut: defaults.object(forKey: breathOutKey) as? Int,
            inhaleCue: defaults.string(forKey: inhaleCueKey),
            exhaleCue: defaults.string(forKey: exhaleCueKey)
        )
        return stored.toVerse()
    }

    private func selectVerse(for date: Date, calendar: Calendar) -> Verse {
        let anchor = AnchorService.shared.anchorsForToday(count: 1, date: date, calendar: calendar).first
        return anchor ?? Verse(ref: "Psalm 46:10", text: "Be still, and know that I am God.")
    }

    private func persist(_ verse: Verse, for dayKey: String) {
        let stored = StoredVerse(from: verse)

        defaults.set(dayKey, forKey: dayKeyKey)
        defaults.set(stored.ref, forKey: refKey)
        defaults.set(stored.text, forKey: textKey)
        defaults.set(stored.breathIn, forKey: breathInKey)
        defaults.set(stored.breathOut, forKey: breathOutKey)
        defaults.set(stored.inhaleCue, forKey: inhaleCueKey)
        defaults.set(stored.exhaleCue, forKey: exhaleCueKey)

        var cache: [String: StoredVerse] = [:]
        if let data = defaults.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: StoredVerse].self, from: data) {
            cache = decoded
        }
        cache[dayKey] = stored
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: cacheKey)
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct StoredVerse: Codable {
    let ref: String
    let text: String
    let breathIn: Int?
    let breathOut: Int?
    let inhaleCue: String?
    let exhaleCue: String?

    init(ref: String, text: String, breathIn: Int?, breathOut: Int?, inhaleCue: String?, exhaleCue: String?) {
        self.ref = ref
        self.text = text
        self.breathIn = breathIn
        self.breathOut = breathOut
        self.inhaleCue = inhaleCue
        self.exhaleCue = exhaleCue
    }

    init(from verse: Verse) {
        self.ref = verse.ref
        self.text = verse.text
        self.breathIn = verse.breathIn
        self.breathOut = verse.breathOut
        self.inhaleCue = verse.inhaleCue
        self.exhaleCue = verse.exhaleCue
    }

    func toVerse() -> Verse {
        Verse(
            ref: ref,
            text: text,
            breathIn: breathIn,
            breathOut: breathOut,
            audioFile: AnchorService.shared.audioFileName(for: ref),
            inhaleCue: inhaleCue,
            exhaleCue: exhaleCue
        )
    }
}
