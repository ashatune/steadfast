import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Loads the day's devotional from Firestore.
/// Expects a `dailyDevotions` collection with fields:
/// - `date`: either a `Timestamp` or string in `yyyy-MM-dd`
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
        let dateKey = Self.dateFormatter.string(from: today)

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        db.collection(collectionName)
            .whereField("date", isEqualTo: dateKey)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                guard
                    let document = snapshot?.documents.first,
                    let mapped = self.map(document: document, fallbackDate: today)
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
