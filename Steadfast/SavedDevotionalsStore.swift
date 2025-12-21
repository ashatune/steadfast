import Foundation
import Combine

final class SavedDevotionalsStore: ObservableObject {
    @Published private(set) var saved: [DailyDevotional] = []

    private let storageKey = "steadfast.savedDevotionals"
    private let queue = DispatchQueue(label: "SavedDevotionalsStore")

    init() {
        load()
    }

    func isSaved(devotionalID: String) -> Bool {
        saved.contains(where: { $0.id == devotionalID })
    }

    func toggleSave(devotional: DailyDevotional) {
        if isSaved(devotionalID: devotional.id) {
            saved.removeAll { $0.id == devotional.id }
        } else {
            saved.append(devotional)
        }
        persist()
    }

    func getAllSaved() -> [DailyDevotional] {
        saved.sorted { $0.date > $1.date }
    }

    // MARK: - Persistence
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([DailyDevotional].self, from: data) {
            saved = decoded
        }
    }

    private func persist() {
        let items = saved
        queue.async {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(items) else { return }
            UserDefaults.standard.set(data, forKey: self.storageKey)
        }
    }
}
