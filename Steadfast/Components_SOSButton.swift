import SwiftUI

struct SOSButton: View {
    var action: () -> Void
    var imageName: String = "SOSIcon"    // asset name
    var imageIsTemplate: Bool = false    // true: tintable PDF, false: full-color PNG/JPG
    var size: CGFloat = 160              // button diameter
    var iconScale: CGFloat = 0.55        // icon relative size
    var accessibilityLabelText: String = "Open Reset Calm"

    @State private var pulse = false

    // Pulse tuning
    private let minScale: CGFloat = 0.94
    private let maxScale: CGFloat = 1.06
    private let period: Double = 1.8
    
    // Extra room so the scaled edge never gets clipped
    private var growPad: CGFloat { ((maxScale - 1.0) * size) / 2.0 + 1.0 }

    var body: some View {
        Button(action: action) {
            ZStack {
                // The only thing that scales
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.accent, Theme.accent2
                            ]),
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: size * 0.6
                                )
                            )
                    )
                    .frame(width: size, height: size) // base disc size
                    .padding(growPad)
                    .scaleEffect(pulse ? maxScale : minScale, anchor: .center)
                    .animation(.easeInOut(duration: period).repeatForever(autoreverses: true),
                               value: pulse)
                    .drawingGroup() // keep to avoid “sliding” gradient

                // Centered icon (does not scale)
                Group {
                    if imageIsTemplate {
                        Image(imageName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                    } else {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: size * iconScale, height: size * iconScale)
            }
            // Give the scaling room so edges don’t get cropped by the label’s bounds
            .frame(width: size + 2*growPad, height: size + 2*growPad)
            .contentShape(Circle().inset(by: -growPad))
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
        .accessibilityLabel(accessibilityLabelText)
    }
}
