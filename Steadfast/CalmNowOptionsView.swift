import SwiftUI

struct CalmNowOptionsView: View {
    enum Destination: Hashable {
        case panicReset
        case godIsWithYou
        case bodyCalmScan
    }

    var onExerciseSelected: () -> Void = {}
    @State private var destination: Destination?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("What would you like to focus on right now?")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Choose what feels most helpful in this moment.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                VStack(spacing: 16) {
                    optionNavButton(title: "Panic Reset", destination: .panicReset)
                    optionNavButton(title: "God Is With You", destination: .godIsWithYou)
                    optionNavButton(title: "Body Calm Scan", destination: .bodyCalmScan)
                }

                Text("Tip: tap the blank space during a workflow to reveal verses.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .panicReset:
                PanicResetView()
            case .godIsWithYou:
                GodIsWithYouView()
            case .bodyCalmScan:
                BodyCalmScanView()
            }
        }
    }

    private func optionNavButton(title: String, destination: Destination) -> some View {
        Button {
            onExerciseSelected()
            self.destination = destination
        } label: {
            optionLabel(title: title)
        }
        .buttonStyle(.plain)
    }

    private func optionLabel(title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.line.opacity(0.6), lineWidth: 1)
            )
    }
}

extension CalmNowOptionsView.Destination: Identifiable {
    var id: Self { self }
}
