import SwiftUI

struct BreathingIconCircle: View {
    let size: CGFloat
    var iconName: String = "SteadfastCROSS1024"
    var animated: Bool = true
    var externalScale: CGFloat? = nil
    var minScale: CGFloat = 0.82
    var maxScale: CGFloat = 1.18
    var breathDuration: Double = 4.0
    var minOpacity: Double = 0.25
    var maxOpacity: Double = 0.45
    var iconScale: CGFloat = 0.48
    var iconShape: RoundedRectangle? = nil
    @State private var isBreathing = false

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
                .opacity(circleOpacity)
                .scaleEffect(circleScale)

            iconView
                .frame(width: size * iconScale, height: size * iconScale)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.accent.opacity(0.12), radius: 14, x: 0, y: 8)
        .onAppear {
            guard animated, externalScale == nil else { return }
            withAnimation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
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

    private var circleScale: CGFloat {
        if let externalScale { return externalScale }
        guard animated else { return 1 }
        return isBreathing ? maxScale : minScale
    }

    private var circleOpacity: Double {
        if externalScale != nil { return maxOpacity }
        guard animated else { return maxOpacity }
        return isBreathing ? maxOpacity : minOpacity
    }
}
