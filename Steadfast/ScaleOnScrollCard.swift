// ScaleOnScrollCard.swift
import SwiftUI

struct ScaleOnScrollCard<Content: View>: View {
    let baseSize: CGSize
    @ViewBuilder var content: () -> Content

    // tune these to taste
    private let minScale: CGFloat = 0.94
    private let maxScale: CGFloat = 1.08
    private let falloff: CGFloat  = 800   // bigger = gentler scaling

    @State private var isPressed = false

    var body: some View {
        GeometryReader { proxy in
            // Position of this card in the global coordinate space
            let frame = proxy.frame(in: .global)
            let screenMidY = UIScreen.main.bounds.midY
            let distance = abs(frame.midY - screenMidY)

            // Closer to center => bigger scale
            let computed = max(minScale, maxScale - (distance / falloff))

            content()
                .frame(width: baseSize.width, height: baseSize.height)
                .scaleEffect(isPressed ? computed * 0.97 : computed) // tiny press bounce
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: computed)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
                // Track a quick press without breaking NavigationLink
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !isPressed { isPressed = true } }
                        .onEnded { _ in isPressed = false }
                )
        }
        .frame(width: baseSize.width, height: baseSize.height)
    }
}
