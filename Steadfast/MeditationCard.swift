// MeditationCard.swift
import SwiftUI

struct MeditationCard: View {
    let meditation: PrayerMeditation
    let baseSize: CGSize

    private let radius: CGFloat = 14

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let name = meditation.coverName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: baseSize.width, height: baseSize.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [.purple.opacity(0.35), .blue.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: baseSize.width, height: baseSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let sub = meditation.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: radius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(meditation.title))
    }
}
