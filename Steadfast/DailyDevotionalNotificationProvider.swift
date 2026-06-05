import Foundation

struct DailyDevotionalNotificationContent {
    let title: String
    let preview: String
    let subtitle: String?
    let category: String
    let isQuestionBased: Bool

    init(title: String, preview: String, subtitle: String? = nil, category: String = "devotional_reminder", isQuestionBased: Bool = false) {
        self.title = title
        self.preview = preview
        self.subtitle = subtitle
        self.category = category
        self.isQuestionBased = isQuestionBased
    }
}

final class DailyDevotionalNotificationProvider {
    static let shared = DailyDevotionalNotificationProvider()

    enum NotificationMoment: String {
        case morning
        case afternoon
        case evening
        case streak
    }

    private let defaults: UserDefaults
    private let dayKeyKey = "steadfast.devotional.notification.dayKey"
    private let titleKey = "steadfast.devotional.notification.title"
    private let previewKey = "steadfast.devotional.notification.preview"
    private let questionKey = "steadfast.devotional.notification.question"
    private let takeawayKey = "steadfast.devotional.notification.takeaway"
    private let eveningPromptKey = "steadfast.devotional.notification.eveningPrompt"
    private let devotionalTitleKey = "steadfast.devotional.notification.devotionalTitle"
    private let devotionalVerseKey = "steadfast.devotional.notification.verse"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cache(devotional: DailyDevotional, for date: Date = Date()) {
        let dayKey = Self.dayKey(for: date)
        defaults.set(dayKey, forKey: dayKeyKey)
        defaults.set(sanitizedPreview(devotional.notificationTitle ?? devotional.title, maxLength: 80), forKey: titleKey)
        defaults.set(sanitizedPreview(devotional.notificationPreview ?? devotional.previewSnippet), forKey: previewKey)
        defaults.set(sanitizedPreview(devotional.notificationQuestion ?? reflectiveQuestion(for: devotional)), forKey: questionKey)
        defaults.set(sanitizedPreview(devotional.notificationTakeaway ?? takeaway(for: devotional)), forKey: takeawayKey)
        defaults.set(sanitizedPreview(devotional.notificationEveningPrompt ?? eveningPrompt(for: devotional)), forKey: eveningPromptKey)
        defaults.set(sanitizedPreview(devotional.title, maxLength: 80), forKey: devotionalTitleKey)
        defaults.set(sanitizedPreview(devotional.verseReference, maxLength: 40), forKey: devotionalVerseKey)
    }

    func cachedContent(for date: Date = Date(), moment: NotificationMoment = .morning) -> DailyDevotionalNotificationContent {
        let todayKey = Self.dayKey(for: date)
        let storedKey = defaults.string(forKey: dayKeyKey)

        if storedKey == todayKey {
            let cached = CachedNotificationFields(
                title: normalizedStoredValue(forKey: titleKey),
                preview: normalizedStoredValue(forKey: previewKey),
                question: normalizedStoredValue(forKey: questionKey),
                takeaway: normalizedStoredValue(forKey: takeawayKey),
                eveningPrompt: normalizedStoredValue(forKey: eveningPromptKey),
                devotionalTitle: normalizedStoredValue(forKey: devotionalTitleKey),
                verseReference: normalizedStoredValue(forKey: devotionalVerseKey)
            )

            if let content = content(from: cached, moment: moment, date: date) {
                return content
            }
        }

        let fallback = DailyDevotional.placeholder(for: date)
        return content(for: fallback, moment: moment, fallbackDate: date)
    }

    private func content(for devotional: DailyDevotional, moment: NotificationMoment, fallbackDate: Date) -> DailyDevotionalNotificationContent {
        let fallback = DailyDevotional.placeholder(for: fallbackDate)
        let title = sanitizedPreview(nonEmpty(devotional.notificationTitle) ?? nonEmpty(devotional.title) ?? fallback.title, maxLength: 80)
        let preview = sanitizedPreview(nonEmpty(devotional.notificationPreview) ?? devotional.previewSnippet)
        let question = sanitizedPreview(nonEmpty(devotional.notificationQuestion) ?? reflectiveQuestion(for: devotional))
        let takeaway = sanitizedPreview(nonEmpty(devotional.notificationTakeaway) ?? takeaway(for: devotional))
        let eveningPrompt = sanitizedPreview(nonEmpty(devotional.notificationEveningPrompt) ?? eveningPrompt(for: devotional))

        let cached = CachedNotificationFields(
            title: title,
            preview: preview,
            question: question,
            takeaway: takeaway,
            eveningPrompt: eveningPrompt,
            devotionalTitle: sanitizedPreview(devotional.title, maxLength: 80),
            verseReference: sanitizedPreview(devotional.verseReference, maxLength: 40)
        )
        return content(from: cached, moment: moment, date: fallbackDate) ?? DailyDevotionalNotificationContent(
            title: "Today's devotional is ready.",
            preview: preview,
            subtitle: title,
            category: category(for: moment, isQuestionBased: false),
            isQuestionBased: false
        )
    }

    private func content(from fields: CachedNotificationFields, moment: NotificationMoment, date: Date) -> DailyDevotionalNotificationContent? {
        let selector = Self.daySelector(for: date, salt: moment.rawValue)
        let title = fields.title ?? fields.devotionalTitle ?? "Today's devotional is ready."
        let preview = fields.preview ?? fields.takeaway ?? "Take a quiet moment with God today."
        let question = fields.question ?? questionFallbacks[selector % questionFallbacks.count]
        let takeaway = fields.takeaway ?? takeawayFallbacks[selector % takeawayFallbacks.count]
        let eveningPrompt = fields.eveningPrompt ?? eveningFallbacks[selector % eveningFallbacks.count]
        let scriptureSubtitle = fields.verseReference.map { "Reflecting on \($0)" }

        switch moment {
        case .morning:
            let options: [DailyDevotionalNotificationContent] = [
                DailyDevotionalNotificationContent(title: "Today's devotional is ready.", preview: takeaway, subtitle: title, category: category(for: moment, isQuestionBased: false)),
                DailyDevotionalNotificationContent(title: question, preview: scriptureSubtitle ?? preview, subtitle: title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true),
                DailyDevotionalNotificationContent(title: titlePrefixed(title), preview: preview, subtitle: scriptureSubtitle, category: category(for: moment, isQuestionBased: false))
            ]
            return options[selector % options.count]
        case .afternoon:
            let options: [DailyDevotionalNotificationContent] = [
                DailyDevotionalNotificationContent(title: "Pause for a moment.", preview: question, subtitle: title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true),
                DailyDevotionalNotificationContent(title: "Still carrying today's stress?", preview: "Take a moment to reset with God.", subtitle: title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true),
                DailyDevotionalNotificationContent(title: "Today's devotional asks a question worth reflecting on.", preview: question, subtitle: scriptureSubtitle ?? title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true)
            ]
            return options[selector % options.count]
        case .evening:
            let options: [DailyDevotionalNotificationContent] = [
                DailyDevotionalNotificationContent(title: "Before today ends", preview: "Spend a few quiet moments with God.", subtitle: title, category: category(for: moment, isQuestionBased: false)),
                DailyDevotionalNotificationContent(title: "Did today's devotional question ever get answered?", preview: question, subtitle: title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true),
                DailyDevotionalNotificationContent(title: "Before bed, reflect on this:", preview: eveningPrompt, subtitle: scriptureSubtitle ?? title, category: category(for: moment, isQuestionBased: true), isQuestionBased: true)
            ]
            return options[selector % options.count]
        case .streak:
            let options: [DailyDevotionalNotificationContent] = [
                DailyDevotionalNotificationContent(title: "Small moments with God add up.", preview: takeaway, subtitle: title, category: category(for: moment, isQuestionBased: false)),
                DailyDevotionalNotificationContent(title: "You've shown up consistently.", preview: "Keep building the rhythm with one quiet step today.", subtitle: title, category: category(for: moment, isQuestionBased: false)),
                DailyDevotionalNotificationContent(title: "Today's devotional is ready for your next step.", preview: preview, subtitle: scriptureSubtitle ?? title, category: category(for: moment, isQuestionBased: false))
            ]
            return options[selector % options.count]
        }
    }

    private func reflectiveQuestion(for devotional: DailyDevotional) -> String {
        let text = searchableText(for: devotional)
        if text.contains("waiting") || text.contains("wait") {
            return "Where might God still be present in what feels delayed?"
        }
        if text.contains("carry") || text.contains("control") || text.contains("surrender") {
            return "Have you been carrying something God never asked you to carry?"
        }
        if text.contains("peace") {
            return "What if the peace you're looking for starts with one small surrender?"
        }
        if text.contains("fear") || text.contains("afraid") {
            return "What fear could you place in God's hands today?"
        }
        if text.contains("trust") {
            return "What are you trusting God with today?"
        }
        return nonEmpty(devotional.cta) ?? "What is God inviting you to notice today?"
    }

    private func takeaway(for devotional: DailyDevotional) -> String {
        let text = searchableText(for: devotional)
        if text.contains("waiting") || text.contains("wait") {
            return "Today's devotional explores why waiting doesn't mean God is absent."
        }
        if text.contains("carry") || text.contains("control") || text.contains("surrender") {
            return "You do not have to carry what belongs in God's hands."
        }
        if text.contains("peace") {
            return "Peace can begin with one small act of surrender."
        }
        if text.contains("fear") || text.contains("afraid") {
            return "God can hold the fear that feels too heavy today."
        }
        return "Today's devotional offers a quiet moment to return to God."
    }

    private func eveningPrompt(for devotional: DailyDevotional) -> String {
        let text = searchableText(for: devotional)
        if text.contains("waiting") || text.contains("wait") {
            return "What are you waiting on God for tonight?"
        }
        if text.contains("carry") || text.contains("control") || text.contains("surrender") {
            return "What can you release back to God before bed?"
        }
        if text.contains("peace") {
            return "Where do you need God's peace tonight?"
        }
        return "What are you trusting God with tonight?"
    }

    private func searchableText(for devotional: DailyDevotional) -> String {
        [devotional.title, devotional.verseReference, devotional.verseText, devotional.body, devotional.cta ?? ""]
            .joined(separator: " ")
            .lowercased()
    }

    private func titlePrefixed(_ title: String) -> String {
        guard !title.lowercased().hasPrefix("today") else { return title }
        return "Today: \(title)"
    }

    private func normalizedStoredValue(forKey key: String) -> String? {
        nonEmpty(defaults.string(forKey: key))
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func category(for moment: NotificationMoment, isQuestionBased: Bool) -> String {
        "devotional_\(moment.rawValue)_\(isQuestionBased ? "question" : "reflection")"
    }

    private func sanitizedPreview(_ preview: String, maxLength: Int = 120) -> String {
        let noNewlines = preview.replacingOccurrences(of: "\n", with: " ")
        let condensed = noNewlines.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let trimmed = condensed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: maxLength, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        return "\(trimmed[..<end])…"
    }

    private static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    private static func daySelector(for date: Date, salt: String) -> Int {
        let key = "\(dayKey(for: date))-\(salt)"
        return key.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 10_000 }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let questionFallbacks = [
        "What has been weighing on you today?",
        "What would it look like to bring this moment to God?",
        "Where do you need God's steadiness right now?"
    ]

    private let takeawayFallbacks = [
        "Take a quiet moment to return your attention to God.",
        "Small moments with God can reshape the rest of the day.",
        "Today's devotional is a peaceful place to pause."
    ]

    private let eveningFallbacks = [
        "What are you trusting God with tonight?",
        "Where did you notice God's care today?",
        "What can you place in God's hands before sleep?"
    ]

    private struct CachedNotificationFields {
        let title: String?
        let preview: String?
        let question: String?
        let takeaway: String?
        let eveningPrompt: String?
        let devotionalTitle: String?
        let verseReference: String?
    }
}
