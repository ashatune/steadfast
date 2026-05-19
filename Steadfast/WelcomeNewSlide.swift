import SwiftUI

struct WelcomeUserSlide: View {
    @AppStorage("displayName") private var displayName = ""
    @State private var breathScale: CGFloat = 0.95

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                BreathingIconCircle(
                    size: 124,
                    iconName: "SteadfastCROSS1024",
                    scale: breathScale,
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
        .onAppear {
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                breathScale = 1.05
            }
        }
    }

    private var firstName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed.components(separatedBy: " ").first!.capitalized
    }
}
