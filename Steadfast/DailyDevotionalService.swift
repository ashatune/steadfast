import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

/// Loads today's devotional from Firestore by exact local day key (`date == yyyy-MM-dd`).
/// Firestore documents must include `date` as a `yyyy-MM-dd` string for lookup.
/// Required non-empty string fields: `title`, `verseReference`, `verseText`, `body`.
/// Optional fields: `cta` (canonical lowercase; uppercase `CTA` is read as a legacy fallback)
/// and `imageURL` (HTTPS download URL for story backgrounds).
/// - Future notification metadata (optional, not required today):
///   `notificationTitle`, `notificationPreview`, `notificationQuestion`,
///   `notificationTakeaway`, `notificationEveningPrompt`
///
/// TODO: Ensure FirebaseApp.configure() is called at app launch.
/// TODO: Make sure Firestore is added to the project via SPM or CocoaPods.
final class DailyDevotionalService {
    private let collectionName: String
    let calendar: Calendar

    init(collectionName: String = "dailyDevotions", calendar: Calendar = .autoupdatingCurrent) {
        self.collectionName = collectionName
        self.calendar = calendar
    }

    /// Fetches today's devotional from Firestore or falls back to a local placeholder.
    func fetchDevotionalForToday(completion: @escaping (DailyDevotional) -> Void) {
        let today = calendar.startOfDay(for: Date())
        let todayString = Self.dayKey(for: today, calendar: calendar)
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
                    #if DEBUG
                    print("DailyDevotionalService: selected document id=\(firstDocument.documentID) failed required-field validation")
                    #endif
                    completeWithPlaceholder(reason: "first-document-map-failed")
                } else {
                    completeWithPlaceholder(reason: "query-returned-zero-documents")
                }
                return
            }
            print("DailyDevotionalService: selected document id=\(document.documentID)")
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
        Self.mapFirestoreData(data, id: id, fallbackDate: fallbackDate)
    }
    #endif

    // MARK: - Mapping helpers
    static func mapFirestoreData(_ data: [String: Any], id: String, fallbackDate: Date, calendar: Calendar = .autoupdatingCurrent) -> DailyDevotional? {
        guard let title = trimmedRequiredString(data["title"], key: "title", documentID: id),
              let verseReference = trimmedRequiredString(data["verseReference"], key: "verseReference", documentID: id),
              let verseText = trimmedRequiredString(data["verseText"], key: "verseText", documentID: id),
              let body = trimmedRequiredString(data["body"], key: "body", documentID: id)
        else { return nil }

        let date: Date = {
            if let dateString = data["date"] as? String, let parsed = dateFormatter(for: calendar).date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return parsed
            }
            return fallbackDate
        }()

        return DailyDevotional(
            id: id,
            date: date,
            title: title,
            verseReference: verseReference,
            verseText: verseText,
            body: body,
            cta: optionalTrimmedString(data["cta"]) ?? optionalTrimmedString(data["CTA"]),
            imageURL: validatedImageURL(from: data["imageURL"]),
            notificationTitle: optionalTrimmedString(data["notificationTitle"]),
            notificationPreview: optionalTrimmedString(data["notificationPreview"]),
            notificationQuestion: optionalTrimmedString(data["notificationQuestion"]),
            notificationTakeaway: optionalTrimmedString(data["notificationTakeaway"]),
            notificationEveningPrompt: optionalTrimmedString(data["notificationEveningPrompt"])
        )
    }

    static func validatedImageURL(from value: Any?) -> URL? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              components.host?.isEmpty == false,
              let url = components.url,
              url.scheme?.lowercased() == "https"
        else { return nil }
        return url
    }

    static func dayKey(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let startOfDay = calendar.startOfDay(for: date)
        return dateFormatter(for: calendar).string(from: startOfDay)
    }

    private static func trimmedRequiredString(_ value: Any?, key: String, documentID: String) -> String? {
        guard let string = value as? String else {
            debugInvalidDocument(documentID: documentID, reason: "missing-or-wrong-type required field \(key)")
            return nil
        }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            debugInvalidDocument(documentID: documentID, reason: "blank required field \(key)")
            return nil
        }
        return trimmed
    }

    private static func optionalTrimmedString(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func debugInvalidDocument(documentID: String, reason: String) {
        #if DEBUG
        print("DailyDevotionalService: rejected Firestore devotional id=\(documentID) reason=\(reason)")
        #endif
    }

    // MARK: - Formatting
    private static func dateFormatter(for calendar: Calendar) -> DateFormatter {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = calendar.timeZone
        df.dateFormat = "yyyy-MM-dd"
        return df
    }
}
