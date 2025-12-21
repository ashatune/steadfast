import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Loads today's devotional (document ID = `yyyy-MM-dd`), otherwise falls back
/// to the most recent devotional ordered by `date`.
/// Firestore documents must include a `date` field that can be ordered
/// (`yyyy-MM-dd` string or `Timestamp`). Other fields:
/// - `title`, `verseReference`, `verseText`, `body`
/// - `cta` (optional)
/// - `imageURL` (optional string; https or Firebase Storage download URL for the card background)
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
        let placeholder = DailyDevotional.placeholder(for: today)

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let collection = db.collection(collectionName)

        // First, try today's document by ID (yyyy-MM-dd)
        collection.document(dateKey).getDocument { snapshot, _ in
            if
                let snapshot = snapshot,
                snapshot.exists,
                let mapped = self.map(document: snapshot, fallbackDate: today)
            {
                completion(mapped)
                return
            }

            // Fallback: most recent by date
            collection
                .order(by: "date", descending: true)
                .limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard
                        let document = snapshot?.documents.first,
                        let mapped = self.map(document: document, fallbackDate: today)
                    else {
                        completion(placeholder)
                        return
                    }
                    completion(mapped)
                }
        }
        #else
        completion(placeholder)
        #endif
    }

    // MARK: - Mapping
    #if canImport(FirebaseFirestore)
    private func map(document: DocumentSnapshot, fallbackDate: Date) -> DailyDevotional? {
        guard let data = document.data() else { return nil }
        return map(data: data, id: document.documentID, fallbackDate: fallbackDate)
    }

    private func map(document: QueryDocumentSnapshot, fallbackDate: Date) -> DailyDevotional? {
        let data = document.data()
        return map(data: data, id: document.documentID, fallbackDate: fallbackDate)
    }

    private func map(data: [String: Any], id: String, fallbackDate: Date) -> DailyDevotional? {
        let placeholder = DailyDevotional.placeholder(for: fallbackDate)
        let date: Date = {
            if let timestamp = data["date"] as? Timestamp { return timestamp.dateValue() }
            if let dateString = data["date"] as? String, let parsed = Self.dateFormatter.date(from: dateString) {
                return parsed
            }
            return fallbackDate
        }()

        let imageURL: URL? = {
            guard let urlString = data["imageURL"] as? String else { return nil }
            return URL(string: urlString)
        }()

        let devotional = DailyDevotional(
            id: id,
            date: date,
            title: data["title"] as? String ?? placeholder.title,
            verseReference: data["verseReference"] as? String ?? placeholder.verseReference,
            verseText: data["verseText"] as? String ?? placeholder.verseText,
            body: data["body"] as? String ?? placeholder.body,
            cta: data["cta"] as? String ?? placeholder.cta,
            imageURL: imageURL
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
