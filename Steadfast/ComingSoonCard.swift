// ComingSoonCard.swift
import SwiftUI

struct ComingSoonCard: View {
    let baseSize: CGSize
    let coverName: String? = nil   // replace with an image name later if you want
    private let radius: CGFloat = 14

    var body: some View {
        ZStack {
            // Background image or gradient
            Group {
                if let name = coverName {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: baseSize.width, height: baseSize.height)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [.purple.opacity(0.25), .blue.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }

            // Soft wash + label
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: baseSize.width, height: baseSize.height)

            Text("More Coming Soon..")
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .frame(width: baseSize.width, height: baseSize.height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
        .accessibilityLabel("Coming Soon")
    }
}
