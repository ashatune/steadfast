import SwiftUI

struct OnboardSlideBranded: View {
    enum IconShape {
        case circle
        case roundedSquare
    }

    let title: String
    let subtitle: String
    let icon: String    // refers to an image in Assets (not SF Symbol)
    var iconShape: IconShape = .circle

    var body: some View {
        GlassCard(maxWidth: .infinity) {
            VStack(spacing: 20) {
                // ✅ Image sizing + styling
                Group {
                    if iconShape == .roundedSquare {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    }
                }
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
                .padding(.bottom, 4)

                // Title
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
            }
             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
        .transition(.opacity.combined(with: .scale))
    }
}
