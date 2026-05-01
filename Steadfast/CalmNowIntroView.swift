import SwiftUI

struct CalmNowIntroView: View {
    enum BreathPhase {
        case inhale
        case exhale
    }

    @State private var breathPhase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var currentMessageIndex = 0
    @State private var showOptions = false

    @State private var breathTimer: Timer?
    @State private var messageTimer: Timer?

    private let messages: [String] = [
        "You did the right thing coming here.",
        "God is with you right now.",
        "Take a moment to focus on your breath.",
        "You are safe in this moment.",
        "God is our refuge and strength, an ever-present help in trouble.\nPsalm 46:1"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if showOptions {
                    VStack(spacing: 20) {
                        breathingCircle
                            .padding(.top, 24)
                        CalmNowOptionsView()
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: 22) {
                        Spacer()

                        Text(messages[currentMessageIndex])
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .id(currentMessageIndex)
                            .transition(.opacity)
                            .frame(maxWidth: 320)
                            .animation(.easeInOut(duration: 0.7), value: currentMessageIndex)

                        breathingCircle

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Calm Now")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .onAppear {
            startBreathingLoop()
            startMessageRotation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showOptions = true
                }
            }
        }
        .onDisappear {
            breathTimer?.invalidate()
            messageTimer?.invalidate()
        }
    }

    private var breathingCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.accent.opacity(0.9), Theme.accent2.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 120, height: 120)
            .scaleEffect(scale)
            .shadow(color: Theme.accent.opacity(0.22), radius: 18, x: 0, y: 8)
    }

    private func startBreathingLoop() {
        animateBreath(to: .inhale)
        breathTimer?.invalidate()
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            let nextPhase: BreathPhase = breathPhase == .inhale ? .exhale : .inhale
            animateBreath(to: nextPhase)
        }
    }

    private func animateBreath(to phase: BreathPhase) {
        breathPhase = phase
        let targetScale: CGFloat
        if showOptions {
            targetScale = phase == .inhale ? 1.05 : 0.95
        } else {
            targetScale = phase == .inhale ? 1.2 : 0.8
        }

        withAnimation(.easeInOut(duration: 4)) {
            scale = targetScale
        }
    }

    private func startMessageRotation() {
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.7)) {
                currentMessageIndex = min(currentMessageIndex + 1, messages.count - 1)
            }
        }
    }
}
