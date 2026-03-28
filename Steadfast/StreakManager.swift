import SwiftUI

final class StreakManager: ObservableObject {
    struct WeekDayStatus: Identifiable {
        let date: Date
        let label: String
        let isCompleted: Bool
        let isToday: Bool

        var id: Date { date }
    }

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var lastCompletedDate: Date?
    @Published private(set) var completionDays: Set<Date> = []

    private let defaults: UserDefaults
    private let calendar: Calendar

    private let streakKey = "streak.current"
    private let lastCompletedKey = "streak.lastCompletedDay"
    private let completedDaysKey = "streak.completedDays"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        load()
    }

    func markSessionCompleted(on date: Date = Date()) {
        let day = startOfDay(for: date)

        if let lastCompletedDate, calendar.isDate(lastCompletedDate, inSameDayAs: day) {
            return
        }

        if let lastCompletedDate,
           let nextDay = calendar.date(byAdding: .day, value: 1, to: lastCompletedDate),
           calendar.isDate(nextDay, inSameDayAs: day) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        self.lastCompletedDate = day
        completionDays.insert(day)
        pruneOldDays(keepingLast: 30, referenceDate: day)
        save()
    }

    func statusForLast7Days(endingOn endDate: Date = Date()) -> [WeekDayStatus] {
        let end = startOfDay(for: endDate)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: end) else { return nil }
            let day = startOfDay(for: date)
            return WeekDayStatus(
                date: day,
                label: formatter.string(from: day),
                isCompleted: completionDays.contains(day),
                isToday: calendar.isDate(day, inSameDayAs: end)
            )
        }
    }

    func streakText(prefix: String = "🙏") -> String {
        let dayWord = currentStreak == 1 ? "day" : "days"
        return "\(prefix) \(currentStreak) \(dayWord) streak"
    }

    func hasCompletion(on date: Date) -> Bool {
        completionDays.contains(startOfDay(for: date))
    }

    private func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func pruneOldDays(keepingLast count: Int, referenceDate: Date) {
        guard let oldestAllowed = calendar.date(byAdding: .day, value: -(count - 1), to: referenceDate) else { return }
        completionDays = completionDays.filter { $0 >= oldestAllowed }
    }

    private func load() {
        currentStreak = max(0, defaults.integer(forKey: streakKey))

        if let interval = defaults.object(forKey: lastCompletedKey) as? Double {
            lastCompletedDate = startOfDay(for: Date(timeIntervalSince1970: interval))
        }

        if let intervals = defaults.array(forKey: completedDaysKey) as? [Double] {
            completionDays = Set(intervals.map { startOfDay(for: Date(timeIntervalSince1970: $0)) })
        }
    }

    private func save() {
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(lastCompletedDate?.timeIntervalSince1970, forKey: lastCompletedKey)
        defaults.set(completionDays.map(\.timeIntervalSince1970), forKey: completedDaysKey)
    }
}
