import SwiftUI
import WatchKit

struct BreathingSessionView: View {
    enum Phase { case inhale, hold, exhale }

    // MARK: - Config
    private let inhaleDur: Double = 4
    private let holdDur: Double   = 3
    private let exhaleDur: Double = 7
    private let totalSeconds = 90

    // Replace with your Anchor Verse lines
    private let verseLines: [String] = [
        "GOD is near",
        "GOD is near",
        "I am not alone"
    ]

    // MARK: - State
    @Environment(\.colorScheme) private var scheme
    @State private var phase: Phase = .inhale
    @State private var remaining = 90
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var isFinished = false
    @State private var scale: CGFloat = 1.0
    @State private var verseIndex = 0

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
                                Text(currentVerse)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(3)
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2, x: 0, y: 1)
                                    .padding(.horizontal, 8)

                                Text(phaseLabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        } else {
                            Button(action: { start() }) {
                                VStack(spacing: 3) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 22, weight: .bold))
                                    Text("Start session")
                                        .font(.caption2.weight(.semibold))
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

                if isRunning || isPaused {
                    Text("\(remaining)s")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
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
            .onAppear { remaining = totalSeconds }
            .onAppear { remaining = totalSeconds }
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

    private var currentVerse: String {
        verseLines[safe: verseIndex] ?? verseLines.first ?? ""
    }

    // MARK: - Core Controls
    private func handleTap() {
        guard isRunning, !isFinished else { return }
        isPaused.toggle()
        if isPaused {
            //WKInterfaceDevice.current().play(.stop)
        } else {
            resume()
        }
    }

    private func start() {
        remaining = totalSeconds
        phase = .inhale
        verseIndex = 0
        isFinished = false
        isPaused = false
        isRunning = true
        animateForCurrentPhase()
        advancePhaseLoop()
        startCountdown()
        //WKInterfaceDevice.current().play(.start)
    }

    private func resume() {
        isPaused = false
        isRunning = true
        animateForCurrentPhase()
        advancePhaseLoop()
        startCountdown()
        //WKInterfaceDevice.current().play(.start)
    }

    private func restart() {
        isPaused = false
        isFinished = false
        isRunning = false
        scale = 1.0
        start()
    }

    private func finish() {
        isRunning = false
        isFinished = true
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
        isPaused = true
        //WKInterfaceDevice.current().play(.stop)
    }

    private func advancePhaseLoop() {
        guard isRunning, !isPaused else { return }
        let delay: Double
        switch phase {
        case .inhale: delay = inhaleDur
        case .hold:   delay = holdDur
        case .exhale: delay = exhaleDur
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isRunning, !isPaused else { return }

            verseIndex = (verseIndex + 1) % max(verseLines.count, 1)

            switch phase {
            case .inhale: phase = .hold
            case .hold:   phase = .exhale
            case .exhale: phase = .inhale
            }
            animateForCurrentPhase()
            advancePhaseLoop()
        }
    }

    private func startCountdown() {
        guard isRunning, !isPaused else { return }
        if remaining <= 0 {
            finish()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard isRunning, !isPaused else { return }
            remaining -= 1
            startCountdown()
        }
    }
}

// Safe index helper
fileprivate extension Array {
    subscript (safe i: Index) -> Element? { indices.contains(i) ? self[i] : nil }
}
