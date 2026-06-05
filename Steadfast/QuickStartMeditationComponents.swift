import SwiftUI

struct MeditationDurationOption: Identifiable, Equatable {
    let minutes: Int

    var id: Int { minutes }
    var seconds: Int { minutes * 60 }
    var title: String { minutes == 1 ? "1 minute" : "\(minutes) minutes" }
    var subtitle: String {
        switch minutes {
        case 1: return "A simple reset"
        case 3: return "Settle your breath"
        case 5: return "Steady and centered"
        case 10: return "Deep calm practice"
        case 15: return "Unhurried restoration"
        default: return "Timed breathing practice"
        }
    }

    static let all: [MeditationDurationOption] = [1, 3, 5, 10, 15].map { MeditationDurationOption(minutes: $0) }
    static let `default` = MeditationDurationOption(minutes: 5)
}

enum QuickStartMeditation {
    static let verse = Verse(
        ref: "Quick Start Meditation",
        text: "Be still, and know that I am God.",
        breathIn: 4,
        breathOut: 6,
        inhaleCue: "Breathe in peace",
        exhaleCue: "Release what you are holding"
    )

    static let introPrompts = [
        "Welcome.",
        "Thank you for showing up for yourself today.",
        "Wherever you are, find a comfortable position.",
        "If it is safe to do so, gently close or dim your eyes.",
        "Try to think about God and your breath.",
        "If other thoughts come, that is okay.",
        "Just bring your awareness back to your breath.",
        "Let’s begin."
    ]
}

struct QuickStartMeditationSessionView: View {
    let duration: MeditationDurationOption

    @EnvironmentObject private var streakManager: StreakManager

    var body: some View {
        AnchorBreathView(
            verse: QuickStartMeditation.verse,
            totalDuration: duration.seconds,
            inhaleSecs: 4,
            holdSecs: 2,
            exhaleSecs: 6,
            bgm: .local(name: "oceanWaves", ext: "mp3"),
            showBibleLink: false,
            onCompleted: {
                streakManager.markSessionCompleted()
                StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
            },
            recordsAnchorCompletion: false,
            headerImageName: "SteadfastCROSS1024",
            introPrompts: QuickStartMeditation.introPrompts
        )
    }
}

struct QuickStartMeditationFlow: View {
    var autoPresentDurations = false
    var onExit: (() -> Void)? = nil

    @State private var showDurations = false
    @State private var selectedDuration: MeditationDurationOption?
    @State private var showSession = false
    @State private var didAutoPresentDurations = false

    var body: some View {
        VStack(spacing: 18) {
            Image("SteadfastCROSS1024")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .opacity(0.86)
                .accessibilityLabel("Steadfast")

            Text("Quick Meditation")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.cardTitle)
                .multilineTextAlignment(.center)

            Text("Choose a length, settle into the intro prompts, then breathe with the same guided Quick Start practice.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                showDurations = true
            } label: {
                HStack {
                    Text("Choose Duration")
                    Image(systemName: "arrow.right")
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let onExit {
                Button("Back to SOS options", action: onExit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            NavigationLink("", isActive: $showSession) {
                QuickStartMeditationSessionView(
                    duration: selectedDuration ?? MeditationDurationOption.default
                )
            }
            .hidden()
        )
        .sheet(isPresented: $showDurations) {
            MeditationDurationPickerSheet(
                selectedDuration: selectedDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedDuration = duration
                showDurations = false
                SoundManager.shared.fade(to: 0.0, duration: 0.25, stopAfter: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showSession = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            guard autoPresentDurations, !didAutoPresentDurations else { return }
            didAutoPresentDurations = true
            DispatchQueue.main.async {
                showDurations = true
            }
        }
    }
}


struct QuickStartMeditationCard: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Quick Start Meditation")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.34))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 360)
        .accessibilityLabel("Quick Start Meditation")
        .accessibilityHint("Opens duration options before starting a breathing meditation")
    }
}


struct MeditationDurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: MeditationDurationOption

    var title: String
    var prompt: String
    var onStart: (MeditationDurationOption) -> Void

    init(
        title: String = "Quick Start Meditation",
        prompt: String = "How long would you like to breathe?",
        selectedDuration: MeditationDurationOption = .default,
        onStart: @escaping (MeditationDurationOption) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        _selectedDuration = State(initialValue: selectedDuration)
        self.onStart = onStart
    }

    var body: some View {
        VStack(spacing: 22) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.cardTitle)

                    Text(prompt)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink.opacity(0.70))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.ink.opacity(0.66))
                        .frame(width: 32, height: 32)
                        .background(Theme.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.top, 10)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(MeditationDurationOption.all) { duration in
                        durationRow(duration)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(maxHeight: 245)

            Button {
                onStart(selectedDuration)
            } label: {
                HStack {
                    Text("Start \(selectedDuration.title)")
                    Image(systemName: "arrow.right")
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(Theme.bg.ignoresSafeArea())
    }

    private func durationRow(_ duration: MeditationDurationOption) -> some View {
        let isSelected = selectedDuration == duration

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedDuration = duration
            }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Theme.cardTitle)

                    Text(duration.subtitle)
                        .font(.footnote)
                        .foregroundStyle(Theme.ink.opacity(0.66))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.ink.opacity(0.28))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.12) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Theme.accent.opacity(0.46) : Theme.line.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(duration.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview("Quick Start Card") {
    QuickStartMeditationCard {}
        .padding()
        .background(Theme.bg)
}

#Preview("Duration Picker") {
    MeditationDurationPickerSheet { _ in }
}
