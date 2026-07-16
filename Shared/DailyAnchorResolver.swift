import Foundation

struct DailyAnchorResolver {
    static func localDayKey(for date: Date, calendar: Calendar = .current) -> String {
        var calendar = calendar
        calendar.timeZone = calendar.timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func startOfLocalDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func nextLocalDayBoundary(after date: Date, calendar: Calendar = .current) -> Date {
        let start = startOfLocalDay(for: date, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(60 * 60 * 24)
    }

    static func anchor(for date: Date = .now, calendar: Calendar = .current) -> Verse {
        AnchorService.shared.anchorsForToday(count: 1, date: date, calendar: calendar).first
            ?? Verse(ref: "Psalm 46:10", text: "Be still, and know that I am God.")
    }

    static func payload(for date: Date = .now, calendar: Calendar = .current, lastUpdated: Date = .now) -> AnchorOfDayPayload {
        AnchorOfDayStore.makePayload(
            from: anchor(for: date, calendar: calendar),
            anchorDate: startOfLocalDay(for: date, calendar: calendar),
            localDayKey: localDayKey(for: date, calendar: calendar),
            lastUpdated: lastUpdated
        )
    }

    static func payload(_ payload: AnchorOfDayPayload, matches date: Date = .now, calendar: Calendar = .current) -> Bool {
        let expectedKey = localDayKey(for: date, calendar: calendar)
        if let storedKey = payload.localDayKey {
            return storedKey == expectedKey
        }
        return calendar.isDate(payload.anchorDate, inSameDayAs: date)
    }
}
