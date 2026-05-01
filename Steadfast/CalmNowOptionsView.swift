import SwiftUI

struct CalmNowOptionsView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Text("What would you like to focus on right now?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Choose what feels most helpful in this moment.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(spacing: 16) {
                NavigationLink {
                    PanicResetView()
                } label: {
                    optionLabel(title: "Panic Reset")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GodIsWithYouView()
                } label: {
                    optionLabel(title: "God Is With You")
                }
                .buttonStyle(.plain)
                optionButton(title: "Body Calm Scan")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private func optionButton(title: String) -> some View {
        Button(action: {}) {
            optionLabel(title: title)
        }
        .buttonStyle(.plain)
    }

    private func optionLabel(title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.line.opacity(0.6), lineWidth: 1)
            )
    }
}
