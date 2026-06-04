// MeditationCard.swift
import SwiftUI

struct MeditationCard: View {
    let meditation: PrayerMeditation
    let baseSize: CGSize

    private let radius: CGFloat = 14
    private let footerHeightRatio: CGFloat = 0.34

    var body: some View {
        VStack(spacing: 0) {
            coverView
                .frame(width: baseSize.width, height: baseSize.height * (1 - footerHeightRatio))
                .clipped()

            footerView
                .frame(width: baseSize.width, height: baseSize.height * footerHeightRatio)
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var coverView: some View {
        if let name = meditation.coverName {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [.purple.opacity(0.35), .blue.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var footerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(meditation.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.cardTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            if let duration = meditation.displayDuration {
                Text(duration)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }

    private var accessibilityLabel: Text {
        if let duration = meditation.displayDuration {
            Text("\(meditation.title), \(duration)")
        } else {
            Text(meditation.title)
        }
    }
}
