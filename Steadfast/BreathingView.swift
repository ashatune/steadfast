import SwiftUI

struct BreathingView: View {
    enum Pattern { case fourSevenEight, box }

    let pattern: Pattern
    var totalDuration: Int = 120
    var verses: [String] = []
    var showTitle: Bool = true   // ← NEW

    @Environment(\.onComplete) private var onComplete

    @State private var phase: String = ""
    @State private var phaseSecondsRemaining: Int = 0
    @State private var countdown: Int = 120
    @State private var scale: CGFloat = 0.95

    @State private var phaseTimer: Timer?
    @State private var countdownTimer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            // ▼ NEW: only show title when requested
                        if showTitle {
                            Text(pattern == .fourSevenEight ? "4–7–8" : "Box Breathing")
                                .font(.title2).bold()
                        }
            ZStack {
                Circle()
                    .stroke(.thinMaterial, lineWidth: 8)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)  // ← no .animation modifier here
                VStack(spacing: 6) {
                    Text(phase).font(.title2)
                    Text(timeString(countdown)).font(.footnote).monospacedDigit()
                }
            }

            VerseTicker(lines: verses).padding(.top, 8)
        }
        .onAppear { start() }
        .onDisappear { stop() }
    }

    private var patternTitle: String { pattern == .fourSevenEight ? "4–7–8" : "Box Breathing" }

    private func start() {
        stop()
        countdown = totalDuration
        scheduleCountdown()
        startPhaseCycle()
    }

    private func stop() {
        phaseTimer?.invalidate(); phaseTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        phase = ""; phaseSecondsRemaining = 0
    }

    private func scheduleCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdown -= 1
            if countdown <= 0 {
                stop()
                onComplete?()
            }
        }
    }

    private func startPhaseCycle() {
        // label, seconds, targetScale (nil = no animation)
        let seq: [(String, Int, CGFloat?)] = {
            switch pattern {
            case .fourSevenEight:
                return [("Inhale", 4, 1.15), ("Hold", 7, nil), ("Exhale", 8, 0.85)]
            case .box:
                return [("Inhale", 4, 1.15), ("Hold", 4, nil), ("Exhale", 4, 0.85), ("Hold", 4, nil)]
            }
        }()

        var i = 0

        func advance() {
            let (label, secs, target) = seq[i]
            phase = label
            phaseSecondsRemaining = secs
            Haptics.bump()

            // Animate scale over the FULL phase duration if inhale/exhale.
            if let target = target {
                animateScale(to: target, duration: Double(secs))
            }

            phaseTimer?.invalidate()
            phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                phaseSecondsRemaining -= 1
                if phaseSecondsRemaining <= 0 {
                    i = (i + 1) % seq.count
                    if countdown > 0 { advance() } // stop when global countdown ends
                }
            }
        }

        // Start from a neutral scale
        scale = 0.95
        advance()
    }

    private func animateScale(to target: CGFloat, duration: Double) {
        withAnimation(.easeInOut(duration: duration)) {
            scale = target
        }
    }


    private func timeString(_ t: Int) -> String {
        let m = max(t,0) / 60, s = max(t,0) % 60
        return String(format: "%01d:%02d", m, s)
    }
}

