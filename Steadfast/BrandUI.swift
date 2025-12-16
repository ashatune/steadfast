//
//  BrandUI.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

// BrandUI.swift
import SwiftUI

// 1) Background: gradient + gentle clouds overlay
struct BrandBackground<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x5B5EE1), // indigo
                    Color(hex: 0x8A7BE7), // purple
                    Color(hex: 0x7DD3FC)  // teal-blue
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // optional: reuse your CalmCloudsBackground if you prefer
            Color.white.opacity(0.06).blendMode(.softLight) // subtle wash

            content()
        }
    }
}

// 2) Glass card
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var maxWidth: CGFloat = 340   // smaller cards look better on iPhone

    var body: some View {
        VStack { content() }
            .padding(20)
            .frame(maxWidth: maxWidth)
            .background(
                // 👇 Use a ZStack to keep blur AND dark tint together
                ZStack {
                    // Keep your frosted blur
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Add a gentle dark overlay tint
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.25)) // tweak between 0.2–0.35
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.25))
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
            .padding(.horizontal, 16)
    }
}



// 3) Primary CTA (capsule)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// 4) Subtle bordered button
struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25)))
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// 5) Hex color convenience (if you want precise brand hues)
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF)/255,
            green: Double((hex >> 8) & 0xFF)/255,
            blue:  Double(hex & 0xFF)/255,
            opacity: alpha
        )
    }
}


struct OnboardingBackground<Content: View>: View {
    var imageName: String? = nil
    var darken: Double = 0.25  // how much to darken the image for contrast
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if let name = imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                // darken overlay so white text pops
                Color.black.opacity(darken).ignoresSafeArea()
            } else {
                // fallback to your current gradient look
                LinearGradient(
                    colors: [Color(hex: 0x5B5EE1), Color(hex: 0x8A7BE7), Color(hex: 0x7DD3FC)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            content()
        }
    }
}
