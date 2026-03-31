import SwiftUI
import UIKit

struct AppleWatchInfoView: View {
    @State private var showManualOpenAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label {
                    Text("Use Steadfast on Apple Watch")
                        .font(.title2.weight(.bold))
                } icon: {
                    Image(systemName: "applewatch")
                        .foregroundStyle(Theme.accent)
                }

                Text("Take Steadfast with you on Apple Watch")
                    .font(.headline)

                Text("Use the Watch app on your iPhone to make sure Steadfast is installed on your Apple Watch.")
                    .foregroundStyle(Theme.inkSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("How to add it:")
                        .font(.headline)

                    Text("1. Open the Watch app on your iPhone")
                    Text("2. Scroll to Available Apps or find Steadfast")
                    Text("3. Tap Install")
                    Text("4. Once installed, open Steadfast on your Apple Watch")
                }

                Text("If Steadfast is already installed, you can launch it from your watch’s app list.")
                    .foregroundStyle(Theme.inkSecondary)

                Button {
                    openWatchAppIfPossible()
                } label: {
                    Label("Open Watch App", systemImage: "applewatch")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
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
