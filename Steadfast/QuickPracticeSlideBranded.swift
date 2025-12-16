import SwiftUI

struct QuickPracticeSlideBranded: View {
    let verse: Verse
    var onCompleted: (() -> Void)? = nil   // advance onboarding

    @State private var stage: Stage = .intro
    @State private var promptIndex = 0
    @State private var showPrompt = false

    // Prompt timings
    private let promptVisible: TimeInterval = 3.0   // visible time per prompt
    private let fade: TimeInterval = 0.6            // fade time

    // Ordered text prompts
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
        GlassCard {
            VStack(spacing: 14) {
                if stage == .intro {
                    Spacer()
                    if showPrompt {
                        Text(prompts[promptIndex])
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: fade), value: showPrompt)
                    }
                    Spacer()
                }

                if stage == .breathing {
                    AnchorBreathView(
                        verse: verse,
                        totalDuration: 60,                 // 👈 now 1 minute
                        inhaleSecs: 4, holdSecs: 4, exhaleSecs: 6,
                        bgm: .local(name: "wanderingMeditation", ext: "mp3"),
                        showBibleLink: false,
                        onCompleted: { onCompleted?() },
                        showInlineMuteButton: true,        // 👈 inline speaker toggle
                        startMuted: false
                    )
                    .frame(height: 360)
                    .padding(12)
                    .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
                }
            }
            .onAppear { playPrompts() }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Prompt sequencing (3s visible + 0.6s fade)
    private func playPrompts() {
        guard stage == .intro else { return }
        promptIndex = 0
        showPrompt = true

        func step() {
            // keep visible for promptVisible seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + promptVisible) {
                withAnimation(.easeInOut(duration: fade)) { showPrompt = false }
                // wait for fade to finish
                DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                    promptIndex += 1
                    if promptIndex < prompts.count {
                        withAnimation(.easeInOut(duration: fade)) { showPrompt = true }
                        step() // next prompt
                    } else {
                        // finished prompts → start breathing after a short settle
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
