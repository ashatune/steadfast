import Foundation
import Combine

final class BibleStore: ObservableObject {
    static let shared = BibleStore()
    @Published private(set) var books: [BibleBook] = KJV_ALL_BOOKS


    // In-memory verse sample (so the app compiles without a big file).
    private var sampleVerses: [BibleVerse] = [
        .init(book: 1, chapter: 1, verse: 1, text: "In the beginning God created the heaven and the earth."),
        .init(book: 1, chapter: 1, verse: 2, text: "And the earth was without form, and void; ..."),
        .init(book: 1, chapter: 1, verse: 3, text: "And God said, Let there be light: and there was light."),
        .init(book: 43, chapter: 3, verse: 16, text: "For God so loved the world, that he gave his only begotten Son, ..."),
    ]

    // If you add a bundled file named "kjv_compact.json", this will load it.
    // JSON format: array of BibleVerse rows.
    private lazy var bundledVerses: [BibleVerse] = {
        guard let url = Bundle.main.url(forResource: "kjv_compact", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([BibleVerse].self, from: data)
        else { return sampleVerses }
        return verses
    }()

    // MARK: Public API
    func chapters(in book: BibleBook) -> Int { book.chapters }

    func verses(book: BibleBook, chapter: Int) -> [BibleVerse] {
        bundledVerses.filter { $0.book == book.id && $0.chapter == chapter }
            .sorted { $0.verse < $1.verse }
    }

    func passage(book: BibleBook, chapter: Int, verseStart: Int? = nil, verseEnd: Int? = nil) -> [BibleVerse] {
        let all = verses(book: book, chapter: chapter)
        guard let s = verseStart, let e = verseEnd else { return all }
        return all.filter { $0.verse >= s && $0.verse <= e }
    }

    struct ParsedRef { let book: BibleBook; let chapter: Int; let verseStart: Int?; let verseEnd: Int? }

    /// Accepts strings like "John 3:16", "Jn 3", "Genesis 1:1-3"
    func parseReference(_ query: String) -> ParsedRef? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return nil }

        // find book by prefix / abbreviation
        guard let book = books.first(where: { b in
            let toks = ([b.name] + b.abbreviations).map { $0.lowercased() }
            return toks.contains(where: { q.hasPrefix($0) })
        }) else { return nil }

        // remove book name from query
        var rest = q.replacingOccurrences(of: book.name.lowercased(), with: "")
        for ab in book.abbreviations { rest = rest.replacingOccurrences(of: ab.lowercased(), with: "") }
        rest = rest.trimmingCharacters(in: .whitespaces)

        // patterns: "3:16-18" | "3:16" | "3"
        if rest.isEmpty { return ParsedRef(book: book, chapter: 1, verseStart: nil, verseEnd: nil) }
        // split chapter/verse
        let parts = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard let chap = Int(parts[0].filter(\.isNumber)) else { return nil }

        if parts.count == 1 {
            return ParsedRef(book: book, chapter: chap, verseStart: nil, verseEnd: nil)
        } else {
            let vs = parts[1]
            if let dash = vs.firstIndex(of: "-") {
                let s = Int(vs[..<dash].filter(\.isNumber))
                let e = Int(vs[vs.index(after: dash)...].filter(\.isNumber))
                return ParsedRef(book: book, chapter: chap, verseStart: s, verseEnd: e)
            } else {
                let s = Int(vs.filter(\.isNumber))
                return ParsedRef(book: book, chapter: chap, verseStart: s, verseEnd: s)
            }
        }
    }
}
