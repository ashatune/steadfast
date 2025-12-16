// ProfileMonogram.swift
import SwiftUI

struct ProfileMonogram: View {
    var initial: String = "U"
    var body: some View {
        Text(initial)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Circle().fill(Theme.accent))
            .overlay(Circle().stroke(Theme.line.opacity(0.3)))
            .accessibilityLabel("Profile")
    }
}
