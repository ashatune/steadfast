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
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 4)

                // Title
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
            }
            .frame(maxWidth: 320)
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
}
