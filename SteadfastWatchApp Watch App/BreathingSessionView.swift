import OSLog
import SwiftUI
import WatchKit

struct WatchBreathingPrompts: Equatable {
    let inhale: String
    let hold: String
    let exhale: String

    func text(for phase: BreathingSessionView.Phase) -> String {
        switch phase {
        case .inhale: return inhale
        case .hold: return hold
        case .exhale: return exhale
        }
    }
}

struct BreathingSessionView: View {
    enum Phase { case inhale, hold, exhale }

    // MARK: - Config
    private let inhaleDur: Double = 4
    private let holdDur: Double   = 3
    private let exhaleDur: Double = 7
    let title: String
    let duration: WatchMeditationDuration
    let prompts: WatchBreathingPrompts
    let reference: String?

    private var totalSeconds: Int { duration.seconds }

    // MARK: - State
    @Environment(\.colorScheme) private var scheme
    @State private var phase: Phase = .inhale
    @State private var remaining: Int
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var isFinished = false
    @State private var scale: CGFloat = 1.0
    @State private var phaseTask: Task<Void, Never>?
    @State private var countdownTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "ashatune.Steadfast.watchkitapp", category: "BreathingSession")

    init(
        title: String = "Quick Start Meditation",
        duration: WatchMeditationDuration = .init(seconds: 90, title: "90 seconds"),
        prompts: WatchBreathingPrompts = .init(
            inhale: "GOD is near",
            hold: "GOD is near",
            exhale: "I am not alone"
        ),
        reference: String? = nil
    ) {
        self.title = title
        self.duration = duration
        self.prompts = prompts
        self.reference = reference
        _remaining = State(initialValue: duration.seconds)
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let ringDiameter = side * 0.82
            let ringLineWidth = max(8, ringDiameter * 0.07)

            VStack(spacing: 10) {
                Spacer(minLength: side * 0.03)

                ZStack {
                    // Breathing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0xA8CFFF), // light blue
                                    Color(hex: 0xC7B7FF)  // lilac
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .scaleEffect(scale)
                        .animation(.easeInOut(duration: currentPhaseDuration), value: scale)
                        //.onTapGesture { handleTap() } // 👈 tap to pause/resume

                    // Center content
                    Group {
                        if isFinished {
                            VStack(spacing: 6) {
                                Text("Session complete")
                                    .font(.headline.weight(.semibold))
                                Text("Peace be with you.")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        } else if isPaused {
                            VStack(spacing: 8) {
                                Text("Paused")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                HStack(spacing: 14) {
                                    Button("Resume") { resume() }
                                        .font(.caption2.weight(.semibold))
                                        .buttonStyle(.borderedProminent)
                                    Button("Restart") { restart() }
                                        .font(.caption2.weight(.semibold))
                                        .buttonStyle(.bordered)
                                }
                            }
                        } else if isRunning {
                            VStack(spacing: 4) {
                                Text(currentPrompt)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(3)
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2, x: 0, y: 1)
                                    .padding(.horizontal, 8)
                                    .id(phase)

                                Text(phaseLabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        } else {
                            Button(action: { start() }) {
                                VStack(spacing: 3) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 22, weight: .bold))
                                    Text("Start")
                                        .font(.caption2.weight(.semibold))
                                    Text(duration.title)
                                        .font(.caption2)
                                        .opacity(0.9)
                                }
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.25)))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: 2) {
                    if isRunning || isPaused {
                        Text(formattedRemainingTime(remaining))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.85))
                    } else if !isFinished {
                        Text(duration.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if let reference, !reference.isEmpty {
                        Text(reference)
                            .font(.caption2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.72))
                            .padding(.horizontal, 8)
                    }
                }

                Spacer(minLength: side * 0.02)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 6)
            .background(Color.black.opacity(0.12))
            .overlay(
                // 👇 Full-screen tap catcher only while running
                Group {
                    if isRunning && !isPaused && !isFinished {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { pause() }
                    }
                }
            )
            .task {
                if remaining != totalSeconds {
                    remaining = totalSeconds
                }
                logger.info("Breathing session view ready. Remaining: \(self.remaining)")
            }
            .onDisappear {
                cancelSessionTasks()
            }
        }
    }

    // MARK: - Derived
    private var currentPhaseDuration: Double {
        switch phase {
        case .inhale: return inhaleDur
        case .hold:   return holdDur
        case .exhale: return exhaleDur
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .inhale: return "Breathe In"
        case .hold:   return "Hold"
        case .exhale: return "Breathe Out"
        }
    }

    private var currentPrompt: String {
        prompts.text(for: phase)
    }

    private func formattedRemainingTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        if remainder == 0 { return "\(minutes)m" }
        return "\(minutes):" + String(format: "%02d", remainder)
    }

    // MARK: - Core Controls
    private func handleTap() {
        guard isRunning, !isFinished else { return }
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    private func start() {
        cancelSessionTasks()
        remaining = totalSeconds
        phase = .inhale
        isFinished = false
        isPaused = false
        isRunning = true
        logger.info("Session started for \(self.totalSeconds)s.")
        animateForCurrentPhase()
        startPhaseLoop()
        startCountdownLoop()
        //WKInterfaceDevice.current().play(.start)
    }

    private func resume() {
        cancelSessionTasks()
        isPaused = false
        isRunning = true
        logger.info("Session resumed at \(self.remaining)s remaining.")
        animateForCurrentPhase()
        startPhaseLoop()
        startCountdownLoop()
        //WKInterfaceDevice.current().play(.start)
    }

    private func restart() {
        cancelSessionTasks()
        isPaused = false
        isFinished = false
        isRunning = false
        scale = 1.0
        logger.info("Session restarted.")
        start()
    }

    private func finish() {
        cancelSessionTasks()
        isRunning = false
        isFinished = true
        logger.info("Session finished.")
        //WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut) {
                isFinished = false
                scale = 1.0
                remaining = totalSeconds
            }
        }
    }

    private func animateForCurrentPhase() {
        let device = WKInterfaceDevice.current()

        switch phase {
        case .inhale:
            scale = 1.32            // expand
            device.play(.directionUp)   // or .click for the quietest cue
        case .hold:
            // no movement or haptic on hold
            break
        case .exhale:
            scale = 1.0             // contract
            device.play(.directionDown) // or .click for the quietest cue
        }
    }

    private func pause() {
        guard isRunning, !isPaused else { return }
        cancelSessionTasks()
        isPaused = true
        logger.info("Session paused at \(self.remaining)s remaining.")
        //WKInterfaceDevice.current().play(.stop)
    }

    private func startPhaseLoop() {
        phaseTask?.cancel()
        phaseTask = Task { @MainActor in
            while !Task.isCancelled, isRunning, !isPaused, !isFinished {
                let delay = currentPhaseDuration
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }

                guard !Task.isCancelled, isRunning, !isPaused, !isFinished, remaining > 0 else { return }
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale: phase = .hold
        case .hold:   phase = .exhale
        case .exhale: phase = .inhale
        }
        animateForCurrentPhase()
    }

    private func startCountdownLoop() {
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            while !Task.isCancelled, isRunning, !isPaused, !isFinished {
                guard remaining > 0 else {
                    finish()
                    return
                }

                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }

                guard !Task.isCancelled, isRunning, !isPaused, !isFinished else { return }
                remaining -= 1
            }
        }
    }

    private func cancelSessionTasks() {
        phaseTask?.cancel()
        countdownTask?.cancel()
        phaseTask = nil
        countdownTask = nil
    }
}
