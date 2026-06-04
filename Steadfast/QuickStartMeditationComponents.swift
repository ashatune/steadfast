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

struct QuickStartMeditationCard: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("Quick Start Meditation")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Theme.line.opacity(0.16), radius: 7, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(0.22), lineWidth: 1)
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

    var onStart: (MeditationDurationOption) -> Void

    init(
        selectedDuration: MeditationDurationOption = .default,
        onStart: @escaping (MeditationDurationOption) -> Void
    ) {
        _selectedDuration = State(initialValue: selectedDuration)
        self.onStart = onStart
    }

    var body: some View {
        VStack(spacing: 22) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text("Quick Start Meditation")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.cardTitle)

                    Text("How long would you like to breathe?")
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
