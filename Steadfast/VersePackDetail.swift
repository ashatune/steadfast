import SwiftUI

struct VersePackDetail: View {
    let pack: VersePack
    @State private var durationVerse: Verse? = nil
    @State private var exerciseVerse: Verse? = nil
    @State private var selectedDuration: MeditationDurationOption?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Reflection header + pulse
                Text(pack.reflectionHeader ?? "Reflection")
                    .font(.headline)
                    .foregroundStyle(Theme.inkSecondary)

                Text("Select a verse to choose a duration before beginning a meditation exercise.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                    Text("Verses").font(.headline).foregroundStyle(Theme.sectionTitle)
                }
                .padding(.top, 2)

                // Verse cards
                LazyVStack(spacing: 10) {
                    ForEach(pack.verses, id: \.self) { v in
                        Button { durationVerse = v } label: {
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
        .sheet(item: $durationVerse) { v in
            MeditationDurationPickerSheet(
                title: pack.title,
                prompt: "How long would you like to breathe with this anchor?",
                selectedDuration: selectedDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedDuration = duration
                durationVerse = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    exerciseVerse = v
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $exerciseVerse) { v in
            NavigationStack {
                AnchorBreathView(
                    verse: v,
                    totalDuration: selectedDuration?.seconds ?? MeditationDurationOption.default.seconds,
                    inhaleSecs: 4,
                    exhaleSecs: 6
                )
            }
        }
    }
}
