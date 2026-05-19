import SwiftUI

struct WelcomeUserSlide: View {
    @AppStorage("displayName") private var displayName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                BreathingIconCircle(
                    size: 124,
                    iconName: "SteadfastCROSS1024",
                    animated: true,
                    minScale: 0.84,
                    maxScale: 1.16,
                    breathDuration: 4.0,
                    minOpacity: 0.24,
                    maxOpacity: 0.44,
                    iconScale: 0.64,
                    iconShape: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

                Text("Welcome to Steadfast, \(firstName)!")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)

                Text("We’re so glad you’re here. This is the beginning of your mindfulness journey, with God at the center.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 22)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private var firstName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed.components(separatedBy: " ").first!.capitalized
    }
}
