import Foundation

@MainActor
final class DailyDevotionalViewModel: ObservableObject {
    @Published var devotional: DailyDevotional?
    @Published var isLoading: Bool = false

    private let service: DailyDevotionalService
    private var hasLoaded = false

    init(service: DailyDevotionalService = DailyDevotionalService()) {
        self.service = service
    }

    func loadDevotionalIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadDevotional()
    }

    func refresh() {
        loadDevotional()
    }

    private func loadDevotional() {
        isLoading = true
        service.fetchDevotionalForToday { [weak self] devotional in
            guard let self else { return }
            Task { @MainActor in
                self.devotional = devotional
                self.isLoading = false
            }
        }
    }
}
