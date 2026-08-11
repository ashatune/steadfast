import SwiftUI

struct SteadfastRhythmCard: View {
    let progress: WeeklyRhythmProgress
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedCount = 0

    private var encouragement: String {
        switch progress.completedSessions {
        case 0: "Begin with a quiet moment today."
        case 1: "You’ve made space for peace once this week."
        case 2: "One more moment to complete your rhythm."
        default: "You created space for peace this week."
        }
    }

    private var buttonTitle: String {
        switch progress.completedSessions {
        case 0: "Begin Today’s Session"
        case 1, 2: "Continue Your Rhythm"
        default: "Find Another Moment of Calm"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("My Steadfast Rhythm")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.cardTitle)
                Spacer(minLength: 8)
                if progress.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.accent)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }

            Text("Anchor yourself 3 times this week")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)

            HStack(spacing: 8) {
                ForEach(0..<WeeklyRhythmProgress.target, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index < animatedCount ? Theme.accent : Theme.line)
                        .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
                }
            }
            .accessibilityHidden(true)

            Text("\(progress.completedSessions) of 3 sessions completed")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()

            Text(encouragement)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(buttonTitle, action: action)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface.opacity(0.94))
                .overlay {
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.10), Theme.accent2.opacity(0.04), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line))
        .shadow(color: Theme.accent.opacity(0.08), radius: 12, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("My Steadfast Rhythm, \(progress.completedSessions) of 3 sessions completed. \(encouragement)")
        .onAppear { updateAnimation(logView: true) }
        .onChange(of: progress.completedSessions) { _ in updateAnimation(logView: false) }
    }

    private func updateAnimation(logView: Bool) {
        if logView { AnalyticsService.log("weekly_rhythm_card_viewed") }
        if reduceMotion {
            animatedCount = progress.completedSessions
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                animatedCount = progress.completedSessions
            }
        }
    }
}
