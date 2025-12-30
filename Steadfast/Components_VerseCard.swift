import SwiftUI

struct VerseCard: View {
    let verse: Verse
    @ObservedObject private var audio = VerseAudioManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var primaryText: Color {
        colorScheme == .dark ? .white : Theme.ink
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.82) : Theme.inkSecondary
    }

    private var iconColor: Color {
        colorScheme == .dark ? .white : Theme.ink
    }

    private var readabilityOverlay: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                Color.black.opacity(0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // If you didn’t add Verse.previewLine earlier, this local helper mirrors it.
    private var previewLine: String {
        // Prefer cue strings (most of your data has these)
        if let i = verse.inhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines),
           let e = verse.exhaleCue?.trimmingCharacters(in: .whitespacesAndNewlines),
           !i.isEmpty, !e.isEmpty {
            return "\(i) / \(e)"
        }
        // Then full verse text (if present)
        let t = verse.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }

        // Then durations (if provided)
        if let bi = verse.breathIn, let bo = verse.breathOut {
            return "Inhale \(bi)s • Exhale \(bo)s"
        }

        // Last resort: just the ref
        return verse.ref
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Play / Pause (only if we have audio)
            if verse.audioFile != nil {
                Button {
                    audio.toggle(verse: verse)
                } label: {
                    Image(systemName: audio.isPlaying(verse.id) ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .shadow(radius: 3)
                        .accessibilityLabel(audio.isPlaying(verse.id) ? "Pause audio" : "Play audio")
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            } else {
                Image(systemName: "book")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor.opacity(0.9))
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(verse.ref)
                    .font(.headline)
                    .foregroundStyle(primaryText)

                // ✅ Subtitle now shows a single, meaningful preview (not a duplicate ref)
                Text(previewLine)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Inhale: \(verse.inhalePreview)")
                    Text("Exhale: \(verse.exhalePreview)")
                }
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .lineLimit(2)

            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surface)
                .overlay(
                    readabilityOverlay
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
        .onDisappear { VerseAudioManager.shared.stop(verseID: verse.id) }
    }
}
