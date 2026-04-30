import SwiftUI

struct CalmNowOptionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What would you like to focus on right now?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)

            Text("Choose what feels most helpful in this moment.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)

            VStack(spacing: 12) {
                optionButton(title: "Panic Reset")
                optionButton(title: "God Is With You")
                optionButton(title: "Body Calm Scan")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionButton(title: String) -> some View {
        Button(action: {}) {
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
        .buttonStyle(.plain)
    }
}
