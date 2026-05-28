import SwiftUI

struct OnboardSlideBranded: View {
    enum IconShape {
        case circle
        case roundedSquare
    }

    let title: String
    let subtitle: String
    let icon: String
    var iconShape: IconShape = .circle

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)

                BreathingIconCircle(
                    size: iconShape == .roundedSquare ? 122 : 132,
                    iconName: icon,
                    animated: true,
                    minScale: 0.84,
                    maxScale: 1.16,
                    breathDuration: 4.0,
                    minOpacity: 0.24,
                    maxOpacity: 0.44,
                    iconScale: iconShape == .roundedSquare ? 0.66 : 0.62,
                    iconShape: iconShape == .roundedSquare ? RoundedRectangle(cornerRadius: 20, style: .continuous) : nil
                )

                Text(title)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(OnboardingPalette.primaryText)

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(OnboardingPalette.secondaryText)
                    .padding(.horizontal, 8)

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
}
