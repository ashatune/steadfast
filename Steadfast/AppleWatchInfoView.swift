import SwiftUI
import UIKit

struct AppleWatchInfoView: View {
    @State private var showManualOpenAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 14) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Take Steadfast with you")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Steadfast is available on Apple Watch so you can stay grounded wherever you are.")
                    .font(.headline)
                    .foregroundStyle(Theme.inkSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Set it up in a minute")
                        .font(.headline)

                    Text("1. Open the Watch app on your iPhone")
                    Text("2. Scroll to Available Apps")
                    Text("3. Find Steadfast and tap Install")
                    Text("4. Open Steadfast on your Apple Watch")
                }

                Text("Once it’s installed, you can access your breathing and grounding moments right from your wrist.")
                    .foregroundStyle(Theme.inkSecondary)

                Button {
                    openWatchAppIfPossible()
                } label: {
                    Label("Open Watch App", systemImage: "applewatch")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)

                Text("You can open the Watch app anytime from your iPhone to install Steadfast.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Apple Watch")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Open the Watch app manually", isPresented: $showManualOpenAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Apple doesn't provide a public deep link for opening the Watch app directly. Open the Watch app on your iPhone to install Steadfast on Apple Watch.")
        }
    }

    private func openWatchAppIfPossible() {
        // Apple does not document a public URL scheme for directly opening the Watch app.
        showManualOpenAlert = true
    }
}
