import SwiftUI

struct VersePackDetail: View {
    let pack: VersePack
    @State private var selected: Verse? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Reflection header + pulse
                Text(pack.reflectionHeader ?? "Reflection")
                    .font(.headline)
                    .foregroundStyle(Theme.inkSecondary)

                ReflectionPulseView(
                    reflections: pack.reflections,
                    interval: 8.0,
                    subtitle: pack.reflectionSubtitle,
                    customTokens: pack.reflectionTokens
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 6)

                // Verses header
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill").foregroundStyle(Theme.accent)
                    Text("Verses").font(.headline).foregroundStyle(Theme.ink)
                }
                .padding(.top, 2)

                // Verse cards
                LazyVStack(spacing: 10) {
                    ForEach(pack.verses, id: \.self) { v in
                        Button { selected = v } label: {
                            VerseCard(verse: v) // your themed card (surface + stroke)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.bg.ignoresSafeArea())
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
        .navigationTitle(pack.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { v in
            NavigationStack {
                AnchorBreathView(verse: v, totalDuration: 90, inhaleSecs: 4, exhaleSecs: 6)
            }
        }
    }
}
