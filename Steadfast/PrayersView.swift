// PrayersView.swift
import SwiftUI

struct PrayersView: View {
    private let hSpacing: CGFloat = 16
    private let vSpacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 16
    private let targetHeight: CGFloat = 110   // match DailyRhythm

    // ✅ Add your three new meditations here (exact filenames)
    let meditations: [PrayerMeditation] = [
        PrayerMeditation(
            title: "Morning Body Scan",
            video: .local(name: "MorningBodyScan1Vid", ext: "mp4"),
            audio: .local(name: "MorningMeditationComplete1", ext: "mp3"),
            coverName: "MorningCover1"
        ),
        PrayerMeditation(
            title: "Evening Rest",
            video: .local(name: "EveningWindownVid1", ext: "mp4"),
            audio: .local(name: "eveningwindown1complete", ext: "mp3"),
            coverName: "EveningCover1"
        ),
        // 🆕 Panic relief
        PrayerMeditation(
            title: "Panic Attack Relief",
            video: .local(name: "PanicVid", ext: "mp4"),
            audio: .local(name: "PanicMeditation", ext: "mp3"),
            coverName: "PanicCover1" // add an asset with this name, or change to one you have
        ),
        // 🆕 Healing meditation
        PrayerMeditation(
            title: "Healing & Renewal",
            video: .local(name: "HealingMeditationVid", ext: "mp4"),
            audio: .local(name: "healingMeditation", ext: "mp3"), // note the lowercase 'h' as you provided
            coverName: "HealingCover1"
        ),
        // 🆕 The Lord's Prayer
        PrayerMeditation(
            title: "The Lord’s Prayer",
            video: .local(name: "LordsPrayerVid", ext: "mp4"),
            audio: .local(name: "TheLordsPrayer", ext: "mp3"),
            coverName: "LordsPrayerCover1"
        )
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let available = geo.size.width - (horizontalPadding * 2)
                let columnWidth = floor((available - hSpacing) / 2)
                let cardSize = CGSize(width: columnWidth, height: targetHeight)

                // 🔢 Dynamic placeholder count to keep a neat grid
                let columns = 2
                let totalSlotsForFullRows = Int(ceil(Double(meditations.count) / Double(columns))) * columns
                let placeholderCount = max(0, totalSlotsForFullRows - meditations.count)

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(columnWidth), spacing: hSpacing),
                            GridItem(.fixed(columnWidth), spacing: hSpacing)
                        ],
                        spacing: vSpacing
                    ) {
                        // 1) Real meditations (tappable)
                        ForEach(meditations) { m in
                            NavigationLink {
                                PrayerMeditationView(meditation: m)
                            } label: {
                                ScaleOnScrollCard(baseSize: cardSize) {
                                    MeditationCard(meditation: m, baseSize: cardSize)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // 2) Placeholder cards to complete the last row (non-tappable)
                        ForEach(0..<placeholderCount, id: \.self) { _ in
                            ScaleOnScrollCard(baseSize: cardSize) {
                                ComingSoonCard(baseSize: cardSize)
                            }
                            .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Prayerful Meditations")
        }
    }
}
