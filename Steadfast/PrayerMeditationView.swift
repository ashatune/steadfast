// PrayerMeditationView.swift
import SwiftUI

struct PrayerMeditationView: View {
    let meditation: PrayerMeditation

    @ViewBuilder
    var body: some View {
        Group {
            switch meditation.audio {
            case .local(let name, let ext):
                RhythmAudioPlayerView(
                    title: meditation.title,
                    subtitle: meditation.subtitle,
                    audioFileName: name,
                    audioFileExtension: ext,
                    backgroundImageName: meditation.playbackBackgroundName
                )
            case .remote:
                UnsupportedPrayerMeditationAudioView(
                    title: meditation.title,
                    backgroundImageName: meditation.playbackBackgroundName
                )
            }
        }
        .analyticsScreen("meditation_detail", screenClass: "PrayerMeditationView")
    }
}

private struct UnsupportedPrayerMeditationAudioView: View {
    let title: String
    let backgroundImageName: String

    var body: some View {
        ZStack {
            Image(backgroundImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.40),
                    .black.opacity(0.25),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Unable to load audio right now.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(24)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
