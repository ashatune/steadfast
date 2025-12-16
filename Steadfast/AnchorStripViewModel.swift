import Foundation
import Combine

final class AnchorStripViewModel: ObservableObject {
    @Published private(set) var todays: [Verse] = []

    private let count: Int
    private var timer: AnyCancellable?

    init(calendar: Calendar = .current, count: Int = 2) {   // default 2
        self.count = max(1, count)
        todays = AnchorService.shared.anchorsForToday(count: self.count)
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
                guard let self else { return }
                self.todays = AnchorService.shared.anchorsForToday(count: self.count)
                self.scheduleMidnightTick(calendar: calendar) // schedule next day
            }
    }

    func refreshNow() {
        todays = AnchorService.shared.anchorsForToday(count: count)
    }
}
