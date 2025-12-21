import SwiftUI

struct DailyDevotionalCard: View {
    let devotional: DailyDevotional?
    let isLoading: Bool

    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if isLoading {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Theme.accent)
                    Text("Loading today’s devotional…")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let devotional {
                Text(devotional.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text(devotional.verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)

                Text(devotional.previewSnippet)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(3)

                if let cta = devotional.cta?.trimmingCharacters(in: .whitespacesAndNewlines), !cta.isEmpty {
                    Text(cta)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                } else {
                    Text("Tap to read today’s devotional")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                }
            } else {
                Text("No devotional available for today.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Theme.line))
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sunrise.fill")
                .foregroundStyle(Theme.accent)
            Text("Daily Devotional")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

struct DailyDevotionalDetailView: View {
    let devotional: DailyDevotional

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(devotional.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                VStack(alignment: .leading, spacing: 4) {
                    Text(devotional.verseReference)
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                    Text(devotional.verseText)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                }

                Divider()

                Text(devotional.body)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Daily Devotional")
        .navigationBarTitleDisplayMode(.inline)
    }
}
