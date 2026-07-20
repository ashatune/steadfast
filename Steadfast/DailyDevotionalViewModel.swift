import Foundation

@MainActor
final class DailyDevotionalViewModel: ObservableObject {
    typealias FetchDevotional = (@escaping (DailyDevotional) -> Void) -> Void

    @Published var devotional: DailyDevotional?
    @Published var isLoading: Bool = false

    private let service: DailyDevotionalService
    private let fetchDevotional: FetchDevotional
    private let calendar: Calendar
    private let afterLoad: (DailyDevotional) -> Void
    private var lastAttemptedDayKey: String?
    private var hasLoaded = false

    init(service: DailyDevotionalService = DailyDevotionalService()) {
        self.service = service
        self.fetchDevotional = service.fetchDevotionalForToday
        self.calendar = service.calendar
        self.afterLoad = { devotional in
            DailyDevotionalNotificationProvider.shared.cache(devotional: devotional)
            NotificationManager.shared.scheduleMorningDevotional()
        }
    }

    init(
        calendar: Calendar,
        fetchDevotional: @escaping FetchDevotional,
        afterLoad: @escaping (DailyDevotional) -> Void = { _ in }
    ) {
        self.service = DailyDevotionalService(calendar: calendar)
        self.fetchDevotional = fetchDevotional
        self.calendar = calendar
        self.afterLoad = afterLoad
    }

    var loadedDayKey: String? { lastAttemptedDayKey }

    func loadDevotionalIfNeeded(now: Date = Date()) {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadDevotional(for: now)
    }

    func refresh(now: Date = Date()) {
        loadDevotional(for: now)
    }

    func refreshIfDayChanged(now: Date = Date()) {
        let dayKey = Self.dayKey(for: now, calendar: calendar)
        guard lastAttemptedDayKey != dayKey else { return }
        hasLoaded = true
        loadDevotional(for: now, dayKey: dayKey)
    }

    static func dayKey(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        DailyDevotionalService.dayKey(for: date, calendar: calendar)
    }

    private func loadDevotional(for date: Date, dayKey: String? = nil) {
        let attemptedDayKey = dayKey ?? Self.dayKey(for: date, calendar: calendar)
        lastAttemptedDayKey = attemptedDayKey
        isLoading = true
        print("📖 DevotionalVM load called")
        fetchDevotional { [weak self] devotional in
            guard let self else { return }
            Task { @MainActor in
                self.devotional = devotional
                self.isLoading = false
                self.afterLoad(devotional)
                let source = devotional.id.hasPrefix("placeholder-") ? "placeholder" : "firestore devotional"
                print("DailyDevotionalViewModel: loadDevotional complete -> \(source) (id=\(devotional.id))")
            }
        }
    }
}
