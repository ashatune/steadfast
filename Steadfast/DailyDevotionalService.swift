import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Loads the most recent devotional from Firestore (ordered by `date`).
/// Firestore documents must include a `date` field that can be ordered
/// (`yyyy-MM-dd` string or `Timestamp`). Other fields:
/// - `title`, `verseReference`, `verseText`, `body`
/// - `cta` (optional)
///
/// TODO: Ensure FirebaseApp.configure() is called at app launch.
/// TODO: Make sure Firestore is added to the project via SPM or CocoaPods.
final class DailyDevotionalService {
    private let collectionName: String
    private let calendar: Calendar

    init(collectionName: String = "dailyDevotions", calendar: Calendar = .autoupdatingCurrent) {
        self.collectionName = collectionName
        self.calendar = calendar
    }

    /// Fetches today's devotional from Firestore or falls back to a local placeholder.
    func fetchDevotionalForToday(completion: @escaping (DailyDevotional) -> Void) {
        let today = calendar.startOfDay(for: Date())

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        db.collection(collectionName)
            .order(by: "date", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                guard
                    let document = snapshot?.documents.first,
                    let mapped = self.map(document: document, fallbackDate: Date())
                else {
                    completion(DailyDevotional.placeholder(for: today))
                    return
                }
                completion(mapped)
            }
        #else
        completion(DailyDevotional.placeholder(for: today))
        #endif
    }

    // MARK: - Mapping
    #if canImport(FirebaseFirestore)
    private func map(document: QueryDocumentSnapshot, fallbackDate: Date) -> DailyDevotional? {
        let data = document.data()
        let placeholder = DailyDevotional.placeholder(for: fallbackDate)
        let date: Date = {
            if let timestamp = data["date"] as? Timestamp { return timestamp.dateValue() }
            if let dateString = data["date"] as? String, let parsed = Self.dateFormatter.date(from: dateString) {
                return parsed
            }
            return fallbackDate
        }()

        let devotional = DailyDevotional(
            id: document.documentID,
            date: date,
            title: data["title"] as? String ?? placeholder.title,
            verseReference: data["verseReference"] as? String ?? placeholder.verseReference,
            verseText: data["verseText"] as? String ?? placeholder.verseText,
            body: data["body"] as? String ?? placeholder.body,
            cta: data["cta"] as? String ?? placeholder.cta
        )

        return devotional
    }
    #endif

    // MARK: - Formatting
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = .autoupdatingCurrent
        df.timeZone = .autoupdatingCurrent
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
