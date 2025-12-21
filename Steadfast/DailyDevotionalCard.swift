import SwiftUI

struct DailyDevotionalCard: View {
    let devotional: DailyDevotional?
    let isLoading: Bool
    var height: CGFloat = 260

    private let cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            baseFallbackImage
            remoteImageOverlay
            gradientOverlay
            content
                .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.line)
        )
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sunrise.fill")
                .foregroundStyle(Theme.accent)
            Text("Daily Devotional")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if isLoading {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Loading today’s devotional…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let devotional {
                Text(devotional.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text(devotional.verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(devotional.previewSnippet)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)

                Text(ctaText(for: devotional))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 2)
            } else {
                Text("No devotional available for today.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ctaText(for devotional: DailyDevotional) -> String {
        if let cta = devotional.cta?.trimmingCharacters(in: .whitespacesAndNewlines), !cta.isEmpty {
            return cta
        }
        return "Tap to read today’s devotional"
    }

    @ViewBuilder
    private var remoteImageOverlay: some View {
        if let imageURL = devotional?.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure(_):
                    EmptyView() // fallback still visible underneath
                case .empty:
                    EmptyView() // fallback still visible underneath
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            EmptyView()
        }
    }

    private var baseFallbackImage: some View {
        // TODO: Add "DefaultDevotionalImage" to Assets.xcassets for the devotional fallback artwork.
        Image("DefaultDevotionalImage")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.05),
                .black.opacity(0.35),
                .black.opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
