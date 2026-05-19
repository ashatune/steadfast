import SwiftUI

struct OnboardingCloudBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateClouds = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.accent.opacity(0.15),
                        Theme.accent2.opacity(0.16),
                        Color.white.opacity(0.92),
                        Theme.accent.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                cloud(width: geo.size.width * 0.78, height: 180, opacity: 0.24, blur: 26)
                    .offset(x: animateClouds ? -geo.size.width * 0.16 : -geo.size.width * 0.22,
                            y: animateClouds ? -geo.size.height * 0.20 : -geo.size.height * 0.24)

                cloud(width: geo.size.width * 0.72, height: 170, opacity: 0.20, blur: 22)
                    .offset(x: animateClouds ? geo.size.width * 0.18 : geo.size.width * 0.12,
                            y: animateClouds ? -geo.size.height * 0.02 : geo.size.height * 0.02)

                cloud(width: geo.size.width * 0.82, height: 190, opacity: 0.18, blur: 28)
                    .offset(x: animateClouds ? -geo.size.width * 0.02 : geo.size.width * 0.05,
                            y: animateClouds ? geo.size.height * 0.24 : geo.size.height * 0.28)
            }
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                    animateClouds = true
                }
            }
        }
    }

    private func cloud(width: CGFloat, height: CGFloat, opacity: Double, blur: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Theme.accent.opacity(opacity), Theme.accent2.opacity(opacity * 0.92)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .blur(radius: blur)
    }
}
