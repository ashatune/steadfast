import Foundation

struct BibleVerse: Identifiable, Hashable, Codable {
    var id: String { "\(book)|\(chapter)|\(verse)" }
    let book: Int       // 1 = Genesis, ... 66 = Revelation
    let chapter: Int
    let verse: Int
    let text: String
}

struct BibleBook: Identifiable, Hashable, Codable {
    let id: Int         // 1..66
    let name: String
    let abbreviations: [String]
    let chapters: Int
}

/// Minimal list to get you going. Replace with a full list later via JSON.
let KJV_MINI_BOOKS: [BibleBook] = [
    .init(id: 1,  name: "Genesis",     abbreviations: ["Gen","Ge","Gn"], chapters: 50),
    .init(id: 19, name: "Psalms",      abbreviations: ["Ps","Psa","Pss"], chapters: 150),
    .init(id: 23, name: "Isaiah",      abbreviations: ["Isa","Is"], chapters: 66),
    .init(id: 40, name: "Matthew",     abbreviations: ["Matt","Mt","Mat"], chapters: 28),
    .init(id: 43, name: "John",        abbreviations: ["Jn","Jhn"], chapters: 21),
    .init(id: 66, name: "Revelation",  abbreviations: ["Rev","Re","Apoc"], chapters: 22)
]
