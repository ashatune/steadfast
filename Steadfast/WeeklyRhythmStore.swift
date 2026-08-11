import Combine
import Foundation

struct WeeklyRhythmCompletionEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let sessionIdentifier: String
    let completedAt: Date
    let sessionType: String
}

struct WeeklyRhythmProgress: Equatable {
    static let target = 3

    let completedSessions: Int

    init(completedSessions: Int) {
        self.completedSessions = min(max(completedSessions, 0), Self.target)
    }

    var isComplete: Bool { completedSessions == Self.target }
}

/// Local completion ledger for My Steadfast Rhythm. Event records intentionally remain
/// independent from the UI so a synchronized persistence implementation can replace this one.
@MainActor
final class WeeklyRhythmStore: ObservableObject {
    @Published private(set) var events: [WeeklyRhythmCompletionEvent] = []

    private let defaults: UserDefaults
    private var calendar: Calendar
    private let storageKey = "weeklyRhythm.completionEvents.v1"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
        load()
    }

    func progress(at date: Date = Date()) -> WeeklyRhythmProgress {
        guard let interval = weekInterval(containing: date) else {
            return WeeklyRhythmProgress(completedSessions: 0)
        }
        return WeeklyRhythmProgress(completedSessions: events.lazy.filter {
            interval.contains($0.completedAt)
        }.count)
    }

    @discardableResult
    func recordSessionCompletion(
        eventID: UUID,
        sessionIdentifier: String,
        sessionType: String,
        completedAt: Date = Date()
    ) -> Bool {
        guard !events.contains(where: { $0.id == eventID }) else { return false }

        let progressBefore = progress(at: completedAt)
        events.append(WeeklyRhythmCompletionEvent(
            id: eventID,
            sessionIdentifier: sessionIdentifier,
            completedAt: completedAt,
            sessionType: sessionType
        ))
        save()

        let progressAfter = progress(at: completedAt)
        AnalyticsService.log("weekly_rhythm_session_recorded", parameters: [
            "session_type": sessionType,
            "weekly_progress": progressAfter.completedSessions
        ])
        if !progressBefore.isComplete && progressAfter.isComplete {
            AnalyticsService.log("weekly_rhythm_goal_completed")
        }
        return true
    }

    /// Daily content has one canonical completion per local day rather than a playback UUID.
    @discardableResult
    func recordDailySessionCompletion(
        sessionIdentifier: String,
        sessionType: String,
        completedAt: Date = Date()
    ) -> Bool {
        let day = calendar.startOfDay(for: completedAt)
        guard !events.contains(where: {
            $0.sessionIdentifier == sessionIdentifier && calendar.isDate($0.completedAt, inSameDayAs: day)
        }) else { return false }
        return recordSessionCompletion(
            eventID: UUID(),
            sessionIdentifier: sessionIdentifier,
            sessionType: sessionType,
            completedAt: completedAt
        )
    }

    func weekInterval(containing date: Date) -> DateInterval? {
        var localCalendar = calendar
        localCalendar.firstWeekday = 2 // Monday
        localCalendar.minimumDaysInFirstWeek = 1
        return localCalendar.dateInterval(of: .weekOfYear, for: date)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WeeklyRhythmCompletionEvent].self, from: data) else { return }
        events = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
