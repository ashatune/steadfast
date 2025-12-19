import SwiftUI

// VerseOfDayStrip.swift
struct VerseOfDayStrip: View {
    let verse: Verse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                Text("Anchor of the Day").font(.title3).bold()
            }

            NavigationLink {
                AnchorBreathView(verse: verse,
                                 totalDuration: 90,
                                 inhaleSecs: 4,
                                 holdSecs: 4,
                                 exhaleSecs: 6,
                                 bgm: .local(name: "wanderingMeditation", ext: "mp3"))
            } label: {
                VerseCard(verse: verse) // VerseCard keeps its own surface style
            }
        }
        // ❌ No extra background/padding wrapper — keeps the page uniform
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
