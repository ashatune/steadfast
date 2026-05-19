import SwiftUI

struct BreathingIconCircle: View {
    let size: CGFloat
    var iconName: String = "SteadfastCROSS1024"
    var scale: CGFloat = 1
    var iconScale: CGFloat = 0.48
    var iconShape: RoundedRectangle? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.14), Theme.accent2.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Theme.accent.opacity(0.18), lineWidth: 1)
                )

            iconView
                .frame(width: size * iconScale, height: size * iconScale)
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .shadow(color: Theme.accent.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var iconView: some View {
        let image = Image(iconName)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)

        if let iconShape {
            image.clipShape(iconShape)
        } else {
            image.clipShape(Circle())
        }
    }
}
