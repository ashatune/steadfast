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
    @Published private(set) var pendingMilestone: Int?

    private let defaults: UserDefaults
    private let calendar: Calendar

    private let streakKey = "streak.current"
    private let lastCompletedKey = "streak.lastCompletedDay"
    private let completedDaysKey = "streak.completedDays"
    private let celebratedMilestonesKey = "streak.celebratedMilestones"
    private let devotionalCompletedDaysKey = "streak.devotionalCompletedDays"
    private let anchorCompletedDaysKey = "streak.anchorCompletedDays"
    private var celebratedMilestones: Set<Int> = []
    @Published private(set) var devotionalCompletionDays: Set<Date> = []
    @Published private(set) var anchorCompletionDays: Set<Date> = []

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
        queueMilestoneCelebrationIfNeeded(for: currentStreak)
        save()
    }

    func markDevotionalCompleted(on date: Date = Date()) {
        let day = startOfDay(for: date)
        devotionalCompletionDays.insert(day)
        pruneDevotionalAndAnchorDays(referenceDate: day)
        markSessionCompleted(on: day)
    }

    func markAnchorCompleted(on date: Date = Date()) {
        let day = startOfDay(for: date)
        anchorCompletionDays.insert(day)
        pruneDevotionalAndAnchorDays(referenceDate: day)
        markSessionCompleted(on: day)
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

    func hasDevotionalCompletion(on date: Date) -> Bool {
        devotionalCompletionDays.contains(startOfDay(for: date))
    }

    func hasAnchorCompletion(on date: Date) -> Bool {
        anchorCompletionDays.contains(startOfDay(for: date))
    }

    func consumePendingMilestone() -> Int? {
        let value = pendingMilestone
        pendingMilestone = nil
        return value
    }

    func clearPendingMilestone() {
        pendingMilestone = nil
    }

    func isCelebrationMilestone(_ streak: Int) -> Bool {
        let fixed: Set<Int> = [1, 3, 7, 14, 21, 30, 45, 60]
        if fixed.contains(streak) { return true }
        return streak > 60 && streak.isMultiple(of: 10)
    }

    private func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func pruneOldDays(keepingLast count: Int, referenceDate: Date) {
        guard let oldestAllowed = calendar.date(byAdding: .day, value: -(count - 1), to: referenceDate) else { return }
        completionDays = completionDays.filter { $0 >= oldestAllowed }
    }

    private func pruneDevotionalAndAnchorDays(referenceDate: Date) {
        guard let oldestAllowed = calendar.date(byAdding: .day, value: -29, to: referenceDate) else { return }
        devotionalCompletionDays = devotionalCompletionDays.filter { $0 >= oldestAllowed }
        anchorCompletionDays = anchorCompletionDays.filter { $0 >= oldestAllowed }
    }

    private func load() {
        currentStreak = max(0, defaults.integer(forKey: streakKey))

        if let interval = defaults.object(forKey: lastCompletedKey) as? Double {
            lastCompletedDate = startOfDay(for: Date(timeIntervalSince1970: interval))
        }

        if let intervals = defaults.array(forKey: completedDaysKey) as? [Double] {
            completionDays = Set(intervals.map { startOfDay(for: Date(timeIntervalSince1970: $0)) })
        }

        if let milestones = defaults.array(forKey: celebratedMilestonesKey) as? [Int] {
            celebratedMilestones = Set(milestones)
        }

        if let intervals = defaults.array(forKey: devotionalCompletedDaysKey) as? [Double] {
            devotionalCompletionDays = Set(intervals.map { startOfDay(for: Date(timeIntervalSince1970: $0)) })
        }

        if let intervals = defaults.array(forKey: anchorCompletedDaysKey) as? [Double] {
            anchorCompletionDays = Set(intervals.map { startOfDay(for: Date(timeIntervalSince1970: $0)) })
        }
    }

    private func save() {
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(lastCompletedDate?.timeIntervalSince1970, forKey: lastCompletedKey)
        defaults.set(completionDays.map(\.timeIntervalSince1970), forKey: completedDaysKey)
        defaults.set(Array(celebratedMilestones).sorted(), forKey: celebratedMilestonesKey)
        defaults.set(devotionalCompletionDays.map(\.timeIntervalSince1970), forKey: devotionalCompletedDaysKey)
        defaults.set(anchorCompletionDays.map(\.timeIntervalSince1970), forKey: anchorCompletedDaysKey)
    }

    private func queueMilestoneCelebrationIfNeeded(for streak: Int) {
        guard isCelebrationMilestone(streak), !celebratedMilestones.contains(streak) else { return }
        celebratedMilestones.insert(streak)
        pendingMilestone = streak
    }
}
