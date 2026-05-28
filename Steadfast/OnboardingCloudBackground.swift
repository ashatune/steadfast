import SwiftUI

struct OnboardingCloudBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateClouds = false
    @State private var animateMidCloud = false
    @State private var animateLowerCloud = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                cloud(width: geo.size.width * 0.78, height: 180, opacity: 0.24, blur: 26)
                    .offset(x: animateClouds ? -geo.size.width * 0.10 : -geo.size.width * 0.30,
                            y: animateClouds ? -geo.size.height * 0.16 : -geo.size.height * 0.28)

                cloud(width: geo.size.width * 0.72, height: 170, opacity: 0.20, blur: 22)
                    .offset(x: animateMidCloud ? geo.size.width * 0.26 : geo.size.width * 0.04,
                            y: animateMidCloud ? -geo.size.height * 0.07 : geo.size.height * 0.05)

                cloud(width: geo.size.width * 0.82, height: 190, opacity: 0.18, blur: 28)
                    .offset(x: animateLowerCloud ? -geo.size.width * 0.11 : geo.size.width * 0.11,
                            y: animateLowerCloud ? geo.size.height * 0.20 : geo.size.height * 0.32)
            }
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    animateClouds = true
                }
                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    animateMidCloud = true
                }
                withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                    animateLowerCloud = true
                }
            }
        }
    }

    private func cloud(width: CGFloat, height: CGFloat, opacity: Double, blur: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: cloudColors(opacity: opacity),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .blur(radius: blur)
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: 0x120A2A),
                Color(hex: 0x21124B),
                Color(hex: 0x122A4A),
                Color(hex: 0x2B155B)
            ]
        }

        return [
            Theme.accent.opacity(0.15),
            Theme.accent2.opacity(0.16),
            Color.white.opacity(0.92),
            Theme.accent.opacity(0.10)
        ]
    }

    private func cloudColors(opacity: Double) -> [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: 0xBFA7FF).opacity(opacity * 1.15),
                Color(hex: 0x6DE7FF).opacity(opacity * 0.78)
            ]
        }

        return [Theme.accent.opacity(opacity), Theme.accent2.opacity(opacity * 0.92)]
    }
}
