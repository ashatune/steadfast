import SwiftUI

struct ReturnTomorrowView: View {
    var onDone: () -> Void
    var showsSupportingText: Bool = true

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 12) {
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
        }
    }
}

#Preview {
    ReturnTomorrowView(onDone: {})
}
