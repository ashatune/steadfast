// MeditationCard.swift
import SwiftUI

struct MeditationCard: View {
    let meditation: PrayerMeditation
    let baseSize: CGSize          // 👈 pass in width/height

    private let radius: CGFloat = 14

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or gradient
            Group {
                if let name = meditation.coverName {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: baseSize.width, height: baseSize.height)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [.purple.opacity(0.35), .blue.opacity(0.35)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }

            // Readability overlay (cover whole card)
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: baseSize.width, height: baseSize.height)

            // Text block
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)

                if let sub = meditation.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(12)
        }
        .frame(width: baseSize.width, height: baseSize.height)   // 👈 hard size
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: radius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(meditation.title))
    }
}
