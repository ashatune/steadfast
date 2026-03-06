import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseCore)
import FirebaseCore
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

        func completeWithPlaceholder(reason: String) {
            print("DailyDevotionalService: placeholder fallback triggered (reason=\(reason))")
            completion(placeholder)
        }

        print("🔥 DevotionalService fetch start")
        print("DailyDevotionalService: fetchDevotionalForToday start (todayString=\(todayString), tz=\(calendar.timeZone.identifier), calendar=\(calendar.identifier), collection=\(collectionName))")
        #if canImport(FirebaseCore)
        if let app = FirebaseApp.app() {
            let options = app.options
            print("DailyDevotionalService: Firebase app context (name=\(app.name), projectID=\(options.projectID ?? "nil"), googleAppID=\(options.googleAppID))")
        } else {
            print("DailyDevotionalService: Firebase app context unavailable (FirebaseApp.app() == nil)")
        }
        #endif

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let collection = db.collection(collectionName)

        // Query: fetch today's devotional by exact date key
        let stringQuery = collection
            .whereField("date", isEqualTo: todayString)
            .limit(to: 1)

        func handleSnapshot(_ snapshot: QuerySnapshot?, source: String) {
            let count = snapshot?.documents.count ?? 0
            print("DailyDevotionalService: \(source) query returned \(count) docs")
            print("DailyDevotionalService: query context (todayString=\(todayString), collection=\(collectionName), source=\(source))")
            guard
                let document = snapshot?.documents.first,
                let mapped = self.map(document: document, fallbackDate: today)
            else {
                if let firstDocument = snapshot?.documents.first {
                    print("DailyDevotionalService: selected document id=\(firstDocument.documentID)")
                    print("DailyDevotionalService: selected document raw data=\(firstDocument.data())")
                    completeWithPlaceholder(reason: "first-document-map-failed")
                } else {
                    completeWithPlaceholder(reason: "query-returned-zero-documents")
                }
                return
            }
            print("DailyDevotionalService: selected document id=\(document.documentID)")
            print("DailyDevotionalService: selected document raw data=\(document.data())")
            print("DailyDevotionalService: using Firestore devotional id=\(mapped.id) date=\(mapped.date)")
            completion(mapped)
        }

        let handleError: (Error) -> Void = { error in
            print("DailyDevotionalService: Firestore query error: \(error) | \(error.localizedDescription)")
            completeWithPlaceholder(reason: "firestore-query-error")
        }

        // Prefer server to avoid stale cache during debugging
        stringQuery.getDocuments(source: .server) { snapshot, error in
            print("DailyDevotionalService: Firestore query completed (todayString=\(todayString))")
            if let error = error {
                handleError(error)
                return
            }
            handleSnapshot(snapshot, source: "string (server)")
        }
        #else
        print("DailyDevotionalService: FirebaseFirestore not available; returning placeholder")
        completeWithPlaceholder(reason: "firebasefirestore-module-unavailable")
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
