// PrayersView.swift
import SwiftUI

struct PrayersView: View {
    private let hSpacing: CGFloat = 16
    private let vSpacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 16
    private let cardAspectRatio: CGFloat = 1.62

    // ✅ Add your three new meditations here (exact filenames)
    let meditations: [PrayerMeditation] = [
        PrayerMeditation(
            title: "Morning Body Scan",
            audio: .local(name: "MorningMeditationComplete1", ext: "mp3"),
            coverName: "MorningCover1",
            playbackBackgroundName: "morningRhythmImage"
        ),
        PrayerMeditation(
            title: "Evening Rest",
            audio: .local(name: "eveningwindown1complete", ext: "mp3"),
            coverName: "EveningCover1",
            playbackBackgroundName: "eveningRhythmImage"
        ),
        // 🆕 Panic relief
        PrayerMeditation(
            title: "Panic Attack Relief",
            audio: .local(name: "PanicMeditation", ext: "mp3"),
            coverName: "PanicCover1", // add an asset with this name, or change to one you have
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        ),
        // 🆕 Healing meditation
        PrayerMeditation(
            title: "Healing & Renewal",
            audio: .local(name: "healingMeditation", ext: "mp3"), // note the lowercase 'h' as you provided
            coverName: "HealingCover1",
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        ),
        // 🆕 The Lord's Prayer
        PrayerMeditation(
            title: "The Lord’s Prayer",
            audio: .local(name: "TheLordsPrayer", ext: "mp3"),
            coverName: "LordsPrayerCover1",
            playbackBackgroundName: "steadfastFiverrSplashScreen"
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - (horizontalPadding * 2)
            let columnWidth = floor((available - hSpacing) / 2)
            let cardHeight = columnWidth / cardAspectRatio
            let cardSize = CGSize(width: columnWidth, height: cardHeight)

            // 🔢 Dynamic placeholder count to keep a neat grid
            let columns = 2
            let totalSlotsForFullRows = Int(ceil(Double(meditations.count) / Double(columns))) * columns
            let placeholderCount = max(0, totalSlotsForFullRows - meditations.count)

            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: hSpacing),
                        GridItem(.flexible(), spacing: hSpacing)
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
                            .contentShape(Rectangle())
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
        .navigationBarTitleDisplayMode(.large)
    }
}
