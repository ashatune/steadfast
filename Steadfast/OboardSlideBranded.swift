import SwiftUI

struct OnboardSlideBranded: View {
    let title: String
    let subtitle: String
    let icon: String    // refers to an image in Assets (not SF Symbol)

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                // ✅ Image sizing + styling
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 120, maxHeight: 120)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
                    .padding(.bottom, 4)

                // Title
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(Theme.ink)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.inkSecondary)
                    .padding(.horizontal, 14)
            }
            .frame(maxWidth: 320)
            .padding(.vertical, 6)
        }
        .transition(.opacity.combined(with: .scale))
    }
}
