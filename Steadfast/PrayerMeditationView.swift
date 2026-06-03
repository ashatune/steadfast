// PrayerMeditationView.swift
import SwiftUI

struct PrayerMeditationView: View {
    let meditation: PrayerMeditation

    private let placeholderBackgroundImageName = "morningRhythmImage"

    var body: some View {
        Group {
            if let audio = meditation.localAudioResource {
                RhythmAudioPlayerView(
                    title: meditation.title,
                    subtitle: meditation.subtitle,
                    audioFileName: audio.name,
                    audioFileExtension: audio.ext,
                    backgroundImageName: placeholderBackgroundImageName
                )
            } else {
                unsupportedAudioView
            }
        }
    }

    private var unsupportedAudioView: some View {
        ZStack {
            Image(placeholderBackgroundImageName)
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
                Text(meditation.title)
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

private extension PrayerMeditation {
    var localAudioResource: (name: String, ext: String)? {
        guard case let .local(name, ext) = audio else { return nil }
        return (name, ext)
    }
}
