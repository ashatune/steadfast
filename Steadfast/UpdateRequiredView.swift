import SwiftUI

struct UpdateRequiredView: View {
    let storeUrl: String
    var currentVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    var body: some View {
        ZStack {
            // Dimmed, slightly transparent background so the app is visible behind
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 16) {
                // App icon
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 8, y: 4)

                // Title
                Text("Please update Steadfast")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                // Friendly message
                Text("We’ve shipped important fixes and new features. To keep everything running smoothly and unlock the latest content, please update to the newest version.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // (Optional) tiny version hint
                if let v = currentVersion {
                    Text("You’re on version \(v).")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // CTA
                Button {
                    if let url = URL(string: storeUrl) {
                        UIApplication.shared.open(url)
                        // A little haptic nudge
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Text("Update in the App Store")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)

                // Small reassurance
                Text("This only takes a moment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(20)
            .background(.ultraThinMaterial) // soft, translucent card
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(radius: 16, y: 8)
            .padding(.horizontal, 24)
        }
        .interactiveDismissDisabled(true)   // prevent swipe-down
        .accessibilityAddTraits(.isModal)   // announce as modal
        .onAppear {
            // Gentle haptic when the gate appears
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

