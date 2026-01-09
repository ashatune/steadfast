import Foundation
import Combine

final class AnchorViewModel: ObservableObject {
    @Published private(set) var todaysAnchor: Verse =
        DailyVerseProvider.shared.verse(for: Date(), calendar: Calendar.current)

    private var timer: AnyCancellable?

    init(calendar: Calendar = Calendar.current) {
        scheduleMidnightTick(calendar: calendar)
    }

    private func scheduleMidnightTick(calendar: Calendar) {
        let next = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? Date().addingTimeInterval(86405)

        let interval = max(5, next.timeIntervalSinceNow)
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshNow()
                self?.scheduleMidnightTick(calendar: calendar) // schedule for the next day
            }
    }

    func refreshNow() {
        todaysAnchor = DailyVerseProvider.shared.verse(for: Date(), calendar: Calendar.current)
    }
}
