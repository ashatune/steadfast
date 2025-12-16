// Put this below LibraryPackCard / LargeActionCard, or in its own file.
import SwiftUI

struct BibleHeroCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let imageName: String
    var height: CGFloat = 160

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()

            // Readability overlay
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.25), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )

            // Content
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.9))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)            // keep full width
        .frame(height: height)                  // taller vertical size
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
