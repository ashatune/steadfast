//
//  ComingSoonOverlay.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/5/25.
//

// ComingSoonOverlay.swift (or inline in same file)
import SwiftUI
struct ComingSoonOverlay: View {
    var title: String = "Reframe is Coming Soon"
    var message: String = "A guided, faith-based thought reframing journey is on the way."

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.95))
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Label("Check back soon", systemImage: "clock")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }
                .padding(18)
                .background(.ultraThinMaterial.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            }
            .padding(24)
        }
        .allowsHitTesting(true) // blocks taps beneath
        .accessibilityAddTraits(.isModal)
    }
}
