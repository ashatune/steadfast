import SwiftUI

// VerseOfDayStrip.swift
struct VerseOfDayStrip: View {
    let verses: [Verse]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                Text("Today’s Anchors").font(.title3).bold()
            }
            ForEach(verses, id: \.self) { v in
                NavigationLink {
                    AnchorBreathView(verse: v,
                                     totalDuration: 90,
                                     inhaleSecs: 4,
                                     holdSecs: 4,
                                     exhaleSecs: 6,
                                     bgm: .local(name: "wanderingMeditation", ext: "mp3"))
                } label: {
                    VerseCard(verse: v) // VerseCard can keep its own surface style
                }
            }
        }
        // ❌ No extra background/padding wrapper — keeps the page uniform
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
