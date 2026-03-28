import SwiftUI

struct DailyDevotionalCard: View {
    let devotional: DailyDevotional?
    let isLoading: Bool

    private let cornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topLeading) {
            baseFallbackImage
            remoteImageOverlay
            gradientOverlay
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.line)
        )
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

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
        Image("DefaultDevotionalImage")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DailyDevotionalDetailView: View {
    let devotional: DailyDevotional
    @EnvironmentObject private var savedStore: SavedDevotionalsStore
    @EnvironmentObject private var streakManager: StreakManager
    @Environment(\.dismiss) private var dismiss
    @State private var showMeditation = false
    @State private var showReturnTomorrow = false

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

                VStack(spacing: 12) {
                    Button("Meditate on this verse") {
                        showMeditation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Done") {
                        streakManager.markSessionCompleted()
                        StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReturnTomorrow = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Daily Devotional")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showReturnTomorrow)
        .toolbar {
            if !showReturnTomorrow {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        savedStore.toggleSave(devotional: devotional)
                    } label: {
                        Image(systemName: savedStore.isSaved(devotionalID: devotional.id) ? "bookmark.fill" : "bookmark")
                            .font(.headline)
                    }
                    .accessibilityLabel(savedStore.isSaved(devotionalID: devotional.id) ? "Remove bookmark" : "Save devotional")
                }
            }
        }
        .background(
            NavigationLink(
                "",
                isActive: $showMeditation,
                destination: {
                    AnchorBreathView(
                        verse: Verse(ref: devotional.verseReference, text: devotional.verseText),
                        totalDuration: 60,
                        inhaleSecs: 4,
                        holdSecs: 4,
                        exhaleSecs: 6
                    )
                }
            )
            .hidden()
        )
        .overlay {
            if showReturnTomorrow {
                ReturnTomorrowView {
                    dismiss()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
