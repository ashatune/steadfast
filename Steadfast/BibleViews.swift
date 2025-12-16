import SwiftUI

// Entry point from Library
struct BibleTOCView: View {
    @StateObject private var store = BibleStore.shared
    @State private var search = ""
    @State private var navParsed: BibleStore.ParsedRef? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Books") {
                    ForEach(store.books) { book in
                        NavigationLink(book.name) {
                            ChapterListView(book: book)
                        }
                    }
                }
            }
            .navigationTitle("KJV Bible")
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or jump (e.g., John 3:16)")
            .onSubmit(of: .search, submit)
            .navigationDestination(isPresented: Binding(
                get: { navParsed != nil },
                set: { if !$0 { navParsed = nil } })
            ) {
                if let p = navParsed {
                    PassageView(book: p.book, chapter: p.chapter,
                                verseStart: p.verseStart, verseEnd: p.verseEnd)
                }
            }
        }
    }

    private func submit() {
        if let parsed = store.parseReference(search) {
            navParsed = parsed
        }
    }
}

struct ChapterListView: View {
    let book: BibleBook
    var body: some View {
        List(1...book.chapters, id: \.self) { ch in
            NavigationLink("Chapter \(ch)") {
                PassageView(book: book, chapter: ch)
            }
        }
        .navigationTitle(book.name)
    }
}


struct PassageView: View {
    // Public init stays the same
    let initialBook: BibleBook
    let initialChapter: Int
    var initialVerseStart: Int? = nil
    var initialVerseEnd: Int? = nil

    // Local state so we can move within the same screen
    @State private var book: BibleBook
    @State private var chapter: Int
    @State private var verseStart: Int?
    @State private var verseEnd: Int?

    @StateObject private var store = BibleStore.shared

    init(book: BibleBook, chapter: Int, verseStart: Int? = nil, verseEnd: Int? = nil) {
        self.initialBook = book
        self.initialChapter = chapter
        self.initialVerseStart = verseStart
        self.initialVerseEnd = verseEnd
        _book = State(initialValue: book)
        _chapter = State(initialValue: chapter)
        _verseStart = State(initialValue: verseStart)
        _verseEnd = State(initialValue: verseEnd)
    }

    var body: some View {
        // Always load the full chapter
        let verses = store.verses(book: book, chapter: chapter)

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    // Anchor to jump to top
                    Color.clear.frame(height: 0).id("top")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(book.name) \(chapter)")
                            .font(.title3).bold()
                            .padding(.bottom, 6)

                        if verses.isEmpty {
                            Text("This chapter will appear when the bundled KJV file is loaded.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(verses) { v in
                                let isHighlighted: Bool = {
                                    if let s = verseStart {
                                        let e = verseEnd ?? s
                                        return v.verse >= s && v.verse <= e
                                    }
                                    return false
                                }()

                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("\(v.verse)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, alignment: .trailing)

                                    Text(v.text)
                                    // was: .foregroundStyle(isHighlighted ? .blue : .primary)
                                    .foregroundStyle(isHighlighted ? Theme.accent : .primary)
 // 🔵 highlight text
                                }
                                .padding(.vertical, 4)
                                .background(isHighlighted ? Color.blue.opacity(0.08) : .clear)
                                .cornerRadius(8)
                                .id("verse-\(v.verse)") // ✅ stable per-verse id for scrolling
                            }
                        }
                    }
                    .padding()
                }
                // Auto-scroll to first highlighted verse on first appear
                .onAppear {
                    if let s = verseStart {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo("verse-\(s)", anchor: .top) }
                        }
                    }
                }
                // When chapter changes via prev/next, clear highlight and scroll top
                .onChange(of: chapter) { _ in
                    verseStart = nil
                    verseEnd = nil
                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                }
            }
            .navigationTitle("\(book.name) \(chapter)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { goPrevious() } label: { Label("Previous", systemImage: "chevron.left") }
                        .disabled(prevLocation == nil)

                    Spacer()

                    Button { goNext() } label: { Label("Next", systemImage: "chevron.right") }
                        .disabled(nextLocation == nil)
                }
            }
        }
    }

    // MARK: - Navigation helpers
    private var bookIndex: Int? { store.books.firstIndex(where: { $0.id == book.id }) }

    private var nextLocation: (BibleBook, Int)? {
        guard let idx = bookIndex else { return nil }
        if chapter < book.chapters { return (book, chapter + 1) }
        if idx + 1 < store.books.count { return (store.books[idx + 1], 1) }
        return nil
    }

    private var prevLocation: (BibleBook, Int)? {
        guard let idx = bookIndex else { return nil }
        if chapter > 1 { return (book, chapter - 1) }
        if idx - 1 >= 0 {
            let pb = store.books[idx - 1]
            return (pb, pb.chapters)
        }
        return nil
    }

    private func goNext()    { if let (b, c) = nextLocation { book = b; chapter = c } }
    private func goPrevious(){ if let (b, c) = prevLocation { book = b; chapter = c } }
}
