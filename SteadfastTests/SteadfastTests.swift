import Foundation
import Testing
@testable import Steadfast

struct SteadfastTests {
    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test func anchorChangesBetweenConsecutiveLocalCalendarDates() {
        let calendar = calendar("America/Chicago")
        let first = date(2026, 7, 16, 12, 0, in: calendar)
        let second = date(2026, 7, 17, 12, 0, in: calendar)

        #expect(DailyAnchorResolver.anchor(for: first, calendar: calendar).ref != DailyAnchorResolver.anchor(for: second, calendar: calendar).ref)
    }

    @Test func multipleReadsOnSameDateReturnSameAnchor() {
        let calendar = calendar("America/Chicago")
        let morning = date(2026, 7, 16, 8, 0, in: calendar)
        let evening = date(2026, 7, 16, 22, 30, in: calendar)

        #expect(DailyAnchorResolver.anchor(for: morning, calendar: calendar).ref == DailyAnchorResolver.anchor(for: evening, calendar: calendar).ref)
    }

    @Test func widgetAndMainAppResolveSameAnchorForGivenDate() {
        let calendar = calendar("America/New_York")
        let today = date(2026, 11, 5, 9, 15, in: calendar)
        let suiteName = "DailyVerseProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = DailyVerseProvider(userDefaults: defaults)

        #expect(provider.verse(for: today, calendar: calendar).ref == DailyAnchorResolver.payload(for: today, calendar: calendar).ref)
    }

    @Test func dateTransitionAroundLocalMidnight() {
        let calendar = calendar("America/Los_Angeles")
        let beforeMidnight = date(2026, 3, 8, 23, 59, in: calendar)
        let afterMidnight = date(2026, 3, 9, 0, 1, in: calendar)

        #expect(DailyAnchorResolver.localDayKey(for: beforeMidnight, calendar: calendar) == "2026-03-08")
        #expect(DailyAnchorResolver.localDayKey(for: afterMidnight, calendar: calendar) == "2026-03-09")
        #expect(DailyAnchorResolver.anchor(for: beforeMidnight, calendar: calendar).ref != DailyAnchorResolver.anchor(for: afterMidnight, calendar: calendar).ref)
    }

    @Test func nonUTCTimeZoneUsesLocalDay() {
        let tokyo = calendar("Asia/Tokyo")
        let instant = ISO8601DateFormatter().date(from: "2026-01-01T15:30:00Z")!

        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: tokyo) == "2026-01-02")
    }

    @Test func timeZoneChangeCanMoveInstantIntoDifferentLocalDate() {
        let honolulu = calendar("Pacific/Honolulu")
        let kiritimati = calendar("Pacific/Kiritimati")
        let instant = ISO8601DateFormatter().date(from: "2026-07-16T10:30:00Z")!

        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: honolulu) == "2026-07-16")
        #expect(DailyAnchorResolver.localDayKey(for: instant, calendar: kiritimati) == "2026-07-17")
    }

    @Test func staleCachedPayloadFromYesterdayIsRejected() {
        let calendar = calendar("America/Chicago")
        let yesterday = date(2026, 7, 15, 12, 0, in: calendar)
        let today = date(2026, 7, 16, 12, 0, in: calendar)
        let stalePayload = DailyAnchorResolver.payload(for: yesterday, calendar: calendar)

        #expect(!DailyAnchorResolver.payload(stalePayload, matches: today, calendar: calendar))
    }

    @Test func offlineBehaviorUsesLocallyAvailableDailyAnchorData() {
        let calendar = calendar("America/Chicago")
        let today = date(2026, 7, 16, 12, 0, in: calendar)
        let payload = DailyAnchorResolver.payload(for: today, calendar: calendar)

        #expect(DailyAnchorResolver.payload(payload, matches: today, calendar: calendar))
        #expect(payload.ref == DailyAnchorResolver.anchor(for: today, calendar: calendar).ref)
    }
}
