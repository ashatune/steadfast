import Foundation

struct DailyDevotionalNotificationContent {
    let title: String
    let preview: String
}

final class DailyDevotionalNotificationProvider {
    static let shared = DailyDevotionalNotificationProvider()

    private let defaults: UserDefaults
    private let dayKeyKey = "steadfast.devotional.notification.dayKey"
    private let titleKey = "steadfast.devotional.notification.title"
    private let previewKey = "steadfast.devotional.notification.preview"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cache(devotional: DailyDevotional, for date: Date = Date()) {
        let content = content(for: devotional, fallbackDate: date)
        let dayKey = Self.dayKey(for: date)
        defaults.set(dayKey, forKey: dayKeyKey)
        defaults.set(content.title, forKey: titleKey)
        defaults.set(content.preview, forKey: previewKey)
    }

    func cachedContent(for date: Date = Date()) -> DailyDevotionalNotificationContent {
        let todayKey = Self.dayKey(for: date)
        let storedKey = defaults.string(forKey: dayKeyKey)
        let storedTitle = defaults.string(forKey: titleKey)
        let storedPreview = defaults.string(forKey: previewKey)

        if storedKey == todayKey,
           let storedTitle,
           let storedPreview,
           !storedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !storedPreview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return DailyDevotionalNotificationContent(title: storedTitle, preview: storedPreview)
        }

        let fallback = DailyDevotional.placeholder(for: date)
        return content(for: fallback, fallbackDate: date)
    }

    private func content(for devotional: DailyDevotional, fallbackDate: Date) -> DailyDevotionalNotificationContent {
        let fallback = DailyDevotional.placeholder(for: fallbackDate)
        let rawTitle = devotional.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = rawTitle.isEmpty ? fallback.title : rawTitle
        let rawPreview = devotional.previewSnippet
        let preview = sanitizedPreview(rawPreview.isEmpty ? fallback.previewSnippet : rawPreview)
        return DailyDevotionalNotificationContent(title: title, preview: preview)
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

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
