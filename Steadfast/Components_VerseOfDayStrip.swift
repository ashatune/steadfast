import SwiftUI

// VerseOfDayStrip.swift
struct VerseOfDayStrip: View {
    let verse: Verse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anchor of the Day")
                .font(.title3)
                .bold()
                .foregroundStyle(Theme.sectionTitle)

            NavigationLink {
                AnchorBreathView(verse: verse,
                                 totalDuration: 90,
                                 inhaleSecs: 4,
                                 holdSecs: 4,
                                 exhaleSecs: 6)
            } label: {
                VerseCard(verse: verse, isFlatStyle: true)
            }
        }
        // ❌ No extra background/padding wrapper — keeps the page uniform
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
