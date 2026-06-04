import SwiftUI

struct HomeMeditationsCarouselView: View {
    @EnvironmentObject private var vm: AppViewModel

    private let meditations = PrayerMeditationLibrary.all
    private let cardSize = CGSize(width: 180, height: 154)
    private let cardSpacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meditations")
                .font(.title3)
                .bold()
                .foregroundStyle(Theme.sectionTitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(meditations) { meditation in
                        NavigationLink {
                            PrayerMeditationView(meditation: meditation)
                        } label: {
                            MeditationCard(meditation: meditation, baseSize: cardSize)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        vm.selectedTab = .meditate
                    } label: {
                        ExploreMoreMeditationsNavigationCard(baseSize: cardSize)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)
    }
}

private struct ExploreMoreMeditationsNavigationCard: View {
    let baseSize: CGSize

    private let radius: CGFloat = 14

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.20), Theme.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: baseSize.height * 0.50)

            VStack(spacing: 6) {
                Text("Explore more meditations")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.sectionTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)

                Text("See all")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Explore more meditations")
    }
}
