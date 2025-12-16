import SwiftUI

struct SupportView: View {
    @Environment(\.openURL) private var openURL

    // Update this when your page is live
    private let supportURL = URL(string: "https://www.mustardseedlabs.io/support")!

    var body: some View {
        ScrollView{
            VStack(spacing: 20) {
                // Header / hero
                VStack(spacing: 8) {
                    Image("steadfastLogo") // or use: Image(systemName: "heart.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 56)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                    Text("Support Steadfast")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.ink)

                    Text("""
                    Steadfast is independently created and cared for by a single developer at Mustard Seed Labs.
                    If Steadfast has been helpful, you can support its growth here.
                    Every bit of encouragement helps, and your contribution is completely optional and doesn’t affect features.
                    We’re deeply grateful for your support — and for sharing Steadfast with a friend.
                    """)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }

                // Card with link
                VStack(spacing: 12) {
                    Text("Help Us Grow")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)

                    Text("Contributions are processed on our website by Mustard Seed Labs, LLC.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        openURL(supportURL) // ✅ open in Safari
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Support Us Here")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: 600) // keeps nice width on iPad; remove if you prefer full width
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1)
                )

                // Optional transparency / FAQ
                VStack(alignment: .leading, spacing: 12) {
                    Text("How is my support used?")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Your contribution helps cover hosting, audio production, and ongoing feature development. Every bit of encouragement helps Steadfast continue to grow.")
                        .foregroundStyle(Theme.inkSecondary)

                    /*Text("Why not in-app purchases?")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("We’ll offer optional subscriptions for premium content via Apple’s in-app purchases soon. Until then, this page is a voluntary way to support development — no features are gated behind it.")
                        .foregroundStyle(Theme.inkSecondary)*/
                }
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
