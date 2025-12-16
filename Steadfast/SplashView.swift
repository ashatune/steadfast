// SplashView.swift
import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                Image("LaunchLogo")           // same asset as your launch screen
                    .resizable()
                    .renderingMode(.template) // set to .original if full-color
                    .foregroundStyle(Theme.accent)
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                // Optional: tagline
                // Text("Steadfast").font(.headline).foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
