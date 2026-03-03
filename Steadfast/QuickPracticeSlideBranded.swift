import SwiftUI

struct QuickPracticeSlideBranded: View {
    let verse: Verse
    var onCompleted: (() -> Void)? = nil

    @State private var stage: Stage = .intro
    @State private var promptIndex = 0
    @State private var showPrompt = false

    private let promptVisible: TimeInterval = 3.0
    private let fade: TimeInterval = 0.6

    private let prompts: [String] = [
        "Welcome to your first Steadfast meditation.",
        "Thank you for taking this time to reset and connect with the Word.",
        "Find a comfortable position if you can.",
        "Release any tension in your shoulders and jaw.",
        "Let’s begin your first breathing exercise.",
        "Inhale on the first part of the verse, and exhale with the second part."
    ]

    enum Stage { case intro, breathing }

    var body: some View {
        VStack(spacing: 14) {
            if stage == .intro {
                Spacer()
                if showPrompt {
                    Text(prompts[promptIndex])
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: fade), value: showPrompt)
                }
                Spacer()
            }

            if stage == .breathing {
                AnchorBreathView(
                    verse: verse,
                    totalDuration: 60,
                    inhaleSecs: 4,
                    holdSecs: 4,
                    exhaleSecs: 6,
                    bgm: .local(name: "wanderingMeditation", ext: "mp3"),
                    showBibleLink: false,
                    onCompleted: { onCompleted?() },
                    showInlineMuteButton: true,
                    startMuted: false
                )
                .frame(maxHeight: 420)
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .onAppear { playPrompts() }
    }

    private func playPrompts() {
        guard stage == .intro else { return }
        promptIndex = 0
        showPrompt = true

        func step() {
            DispatchQueue.main.asyncAfter(deadline: .now() + promptVisible) {
                withAnimation(.easeInOut(duration: fade)) { showPrompt = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                    promptIndex += 1
                    if promptIndex < prompts.count {
                        withAnimation(.easeInOut(duration: fade)) { showPrompt = true }
                        step()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                stage = .breathing
                            }
                        }
                    }
                }
            }
        }

        step()
    }
}
