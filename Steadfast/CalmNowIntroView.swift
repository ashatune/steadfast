import SwiftUI
import AVFoundation

struct CalmNowIntroView: View {
    enum BreathPhase {
        case inhale
        case exhale
    }

    @Environment(\.dismiss) private var dismiss

    @State private var breathPhase: BreathPhase = .inhale
    @State private var scale: CGFloat = 0.8
    @State private var currentMessageIndex = 0
    @State private var showOptions = false
    @State private var messageOpacity = 1.0

    @State private var breathTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var introTask: Task<Void, Never>?
    @State private var remainingIntroSeconds = 0

    @State private var backgroundMusicPlayer: AVAudioPlayer?

    private let messages: [String] = [
        "You did the right thing coming here.",
        "God is with you right now.",
        "Take a moment to focus on your breath.",
        "You are safe in this moment.",
        "God is our refuge and strength, an ever-present help in trouble.\nPsalm 46:1"
    ]

    private let fadeOutDuration: Double = 0.35
    private let gapBetweenPrompts: Double = 0.2
    private let fadeInDuration: Double = 0.35
    private let holdDuration: Double = 3.1
    private let finalPromptMinimumHold: Double = 1.0

    private var introDuration: Double {
        guard !messages.isEmpty else { return 0 }
        let transitionDuration = fadeOutDuration + gapBetweenPrompts + fadeInDuration
        let finalHold = max(finalPromptMinimumHold, holdDuration)
        return holdDuration * Double(messages.count - 1)
            + transitionDuration * Double(messages.count - 1)
            + finalHold
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if showOptions {
                    VStack(spacing: 24) {
                        breathingCircle
                            .padding(.top, 24)

                        CalmNowOptionsView(onExerciseSelected: stopBackgroundMusic)

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
                            .frame(maxWidth: 320)
                            .opacity(messageOpacity)

                        breathingCircle

                        Spacer()

                        VStack(spacing: 10) {
                            skipIntroButton
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .overlay(alignment: .bottom) {
                        introFooter
                            .padding(.bottom, 24)
                    }
                    .transition(.opacity)
                }

                if !showOptions {
                    VStack {
                        Spacer()
                        introFooter
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }

                if !showOptions {
                    VStack {
                        Spacer()
                        introFooter
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }

                if !showOptions {
                    VStack {
                        Spacer()
                        introFooter
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }

                if !showOptions {
                    VStack {
                        Spacer()
                        introFooter
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel("Back")
                }
            }
        }
        .onAppear {
            startBreathingLoop()
            startBackgroundMusic()
            startIntroSequence()
        }
        .onDisappear {
            breathTimer?.invalidate()
            introTask?.cancel()
            stopIntroCountdown()
            stopBackgroundMusic()
        }
    }

    private func handleBack() {
        if showOptions {
            introTask?.cancel()
            stopIntroCountdown()
            currentMessageIndex = 0
            messageOpacity = 1
            withAnimation(.easeInOut(duration: 0.6)) {
                showOptions = false
            }
            if backgroundMusicPlayer == nil {
                startBackgroundMusic()
            }
            startIntroSequence()
        } else {
            dismiss()
        }
    }

    private func skipIntro() {
        introTask?.cancel()
        messageOpacity = 1
        withAnimation(.easeInOut(duration: 0.3)) {
            showOptions = true
        }
    }

    private var introFooter: some View {
        skipIntroButton
    }

    private var skipIntroButton: some View {
        Button("Skip Intro") {
            skipIntro()
        }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(Theme.accent)
        .accessibilityLabel("Skip Intro")
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

    private func startIntroSequence() {
        introTask?.cancel()
        startIntroCountdown()
        introTask = Task {
            for idx in 0..<messages.count {
                if idx > 0 {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: fadeOutDuration)) {
                            messageOpacity = 0
                        }
                    }
                    try? await Task.sleep(nanoseconds: UInt64(fadeOutDuration * 1_000_000_000))
                    try? await Task.sleep(nanoseconds: UInt64(gapBetweenPrompts * 1_000_000_000))

                    await MainActor.run {
                        currentMessageIndex = idx
                        withAnimation(.easeInOut(duration: fadeInDuration)) {
                            messageOpacity = 1
                        }
                    }
                    try? await Task.sleep(nanoseconds: UInt64(fadeInDuration * 1_000_000_000))
                }

                let hold = (idx == messages.count - 1) ? max(finalPromptMinimumHold, holdDuration) : holdDuration
                try? await Task.sleep(nanoseconds: UInt64(hold * 1_000_000_000))
                if Task.isCancelled { return }
            }

            await MainActor.run {
                stopIntroCountdown()
                withAnimation(.easeInOut(duration: 0.6)) {
                    showOptions = true
                }
            }
        }
    }

    private func startBackgroundMusic() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Unable to configure SOS background session: \(error.localizedDescription)")
        }

        guard let url = audioURL(named: "SteadfastSOSBackgroundMusic.wav") else {
            print("Audio file not found:", "SteadfastSOSBackgroundMusic.wav")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.25
            player.prepareToPlay()
            player.play()
            backgroundMusicPlayer = player
        } catch {
            print("Unable to play SOS background music: \(error.localizedDescription)")
        }
    }

    private func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }

    private func audioURL(named fileName: String) -> URL? {
        let ns = fileName as NSString
        let base = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? "wav" : ns.pathExtension

        if let url = Bundle.main.url(forResource: base, withExtension: ext) { return url }
        if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "audio") { return url }
        if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Audio") { return url }
        return nil
    }
}
