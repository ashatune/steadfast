import SwiftUI
import UIKit

struct StreakMilestoneCelebrationView: View {
    let milestone: Int
    let onDone: () -> Void

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            FallingPrayerHandsView()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                Spacer()

                VStack(spacing: 12) {
                    Text("You’re building a beautiful rhythm 🙏")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Text("\(milestone) day streak")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.accent)

                    Text("Thank you for showing up with intention.")
                        .font(.body)
                        .foregroundStyle(Theme.ink.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)

                Spacer()

                VStack(spacing: 10) {
                    Button("Share") {
                        shareImage = MilestoneCardRenderer.renderImage(milestone: milestone)
                        showShareSheet = shareImage != nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)

                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
        .onAppear { Haptics.success() }
    }
}

struct ShareableStreakCardView: View {
    let milestone: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.surface, Theme.bg],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                Text("Steadfast")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.accent.opacity(0.9))

                Text("You’re building a beautiful rhythm 🙏")
                    .font(.system(size: 52, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(8)

                Text("\(milestone) day streak")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(Theme.accent)

                Text("Thank you for showing up with intention.")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(80)
        }
        .frame(width: 1080, height: 1350)
        .overlay(
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .stroke(Theme.line.opacity(0.8), lineWidth: 3)
                .padding(26)
        )
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }
}

private struct FallingPrayerHandsView: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let duration: Double
        let delay: Double
        let size: CGFloat
        let opacity: Double
    }

    private let particles: [Particle] = (0..<16).map { idx in
        Particle(
            x: CGFloat((idx * 37) % 100) / 100.0,
            duration: 6.4 + Double((idx * 11) % 7),
            delay: Double((idx * 13) % 20) * 0.12,
            size: CGFloat(18 + ((idx * 5) % 10)),
            opacity: 0.18 + Double((idx * 3) % 8) * 0.07
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Text("🙏")
                        .font(.system(size: particle.size))
                        .opacity(particle.opacity)
                        .position(x: particle.x * geo.size.width,
                                  y: animate ? geo.size.height + 60 : -80)
                        .animation(
                            .linear(duration: particle.duration)
                                .delay(particle.delay)
                                .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
    }
}

private enum MilestoneCardRenderer {
    static func renderImage(milestone: Int) -> UIImage? {
        let view = ShareableStreakCardView(milestone: milestone)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    StreakMilestoneCelebrationView(milestone: 7, onDone: {})
}
