import SwiftUI

struct ReturnTomorrowView: View {
    @EnvironmentObject private var streakManager: StreakManager

    var onDone: () -> Void
    var showsSupportingText: Bool = true
    @State private var activeMilestone: Int?
    @State private var showMilestone = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 12) {
                Text(streakManager.streakText())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.accent.opacity(0.10), in: Capsule())
                    .padding(.bottom, 2)

                Text("You showed up for yourself today 🤍")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("Come back tomorrow for your next moment of peace.")
                    .font(.body)
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .multilineTextAlignment(.center)

                if showsSupportingText {
                    Text("Just 60 seconds a day can make a difference.")
                        .font(.footnote)
                        .foregroundStyle(Theme.ink.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            Haptics.light()
            if activeMilestone == nil {
                activeMilestone = streakManager.consumePendingMilestone()
                showMilestone = activeMilestone != nil
            }
        }
        .fullScreenCover(isPresented: $showMilestone, onDismiss: {
            activeMilestone = nil
        }) {
            if let activeMilestone {
                StreakMilestoneCelebrationView(milestone: activeMilestone) {
                    showMilestone = false
                }
            }
        }
    }
}

#Preview {
    ReturnTomorrowView(onDone: {})
        .environmentObject(StreakManager())
}
