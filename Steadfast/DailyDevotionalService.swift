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
        let todayString = dateKey
        let placeholder = DailyDevotional.placeholder(for: today)

        print("DailyDevotionalService: fetchDevotionalForToday called for \(today) (todayString=\(todayString)) in collection \(collectionName)")

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let collection = db.collection(collectionName)

        // Query: find the most recent devotional on or before today (assumes `date` stored as "yyyy-MM-dd" string for ordering)
        let stringQuery = collection
            .whereField("date", isLessThanOrEqualTo: todayString)
            .order(by: "date", descending: true)
            .limit(to: 1)

        let timestampQuery = collection
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: today))
            .order(by: "date", descending: true)
            .limit(to: 1)

        func handleSnapshot(_ snapshot: QuerySnapshot?, source: String, fallback: () -> Void) {
            print("DailyDevotionalService: \(source) query returned \(snapshot?.documents.count ?? 0) docs")
            guard
                let document = snapshot?.documents.first,
                let mapped = self.map(document: document, fallbackDate: today)
            else {
                print("DailyDevotionalService: no devotional found on or before today; returning placeholder")
                fallback()
                return
            }
            completion(mapped)
        }

        stringQuery.getDocuments { snapshot, error in
            if let error = error {
                print("DailyDevotionalService string query error: \(error.localizedDescription)")
                // Fallback for Timestamp-backed `date`
                timestampQuery.getDocuments { tsSnapshot, tsError in
                    if let tsError = tsError {
                        print("DailyDevotionalService timestamp query error: \(tsError.localizedDescription)")
                        completion(placeholder)
                        return
                    }
                    print("DailyDevotionalService: timestamp query returned \(tsSnapshot?.documents.count ?? 0) docs (error path)")
                    handleSnapshot(tsSnapshot, source: "timestamp (error path)") {
                        completion(placeholder)
                    }
                }
                return
            }

            // If no doc matched string query, try timestamp query
            if snapshot?.documents.isEmpty ?? true {
                timestampQuery.getDocuments { tsSnapshot, tsError in
                    if let tsError = tsError {
                        print("DailyDevotionalService timestamp query error: \(tsError.localizedDescription)")
                        completion(placeholder)
                        return
                    }
                    print("DailyDevotionalService: timestamp query returned \(tsSnapshot?.documents.count ?? 0) docs (string empty path)")
                    handleSnapshot(tsSnapshot, source: "timestamp (string empty path)") {
                        completion(placeholder)
                    }
                }
                return
            }

            handleSnapshot(snapshot, source: "string") {
                completion(placeholder)
            }
        }
        #else
        print("DailyDevotionalService: FirebaseFirestore not available; returning placeholder")
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
