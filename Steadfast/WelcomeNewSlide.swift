//
//  WelcomeNewSlide.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/31/25.
//
import SwiftUI

struct WelcomeUserSlide: View {
    @AppStorage("displayName") private var displayName = ""

    var body: some View {
        GlassCard {
            VStack(spacing: 18) {
                // Optional image or icon
                Image("OnboardWelcome") // 👈 optional; replace with your asset
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 7)

                // Greeting
                Text("Welcome to Steadfast, \(firstName)!")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)

                Text("We’re so glad you’re here. This is the beginning of your mindfulness journey, with God at the center.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 22)
            }
            .padding(.vertical, 8)
        }
        .transition(.opacity.combined(with: .scale))
    }

    private var firstName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed.components(separatedBy: " ").first!.capitalized
    }
}
