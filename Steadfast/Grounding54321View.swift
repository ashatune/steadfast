import SwiftUI

struct Grounding54321View: View {
    /// Total time for the exercise (also used for countdown).
    var totalDuration: Int = 55
    /// Optional per-prompt durations in seconds: 5 entries for 5→1.
    /// If nil, the time is split evenly across steps.
    var perStepDurations: [Double]? = nil
    var verses: [String] = []
    /// Show/hide the big title at the top
    var showTitle: Bool = true   // ← NEW

    @Environment(\.onComplete) private var onComplete

    @State private var step = 5                // 5 → 1
    @State private var countdown: Int = 55
    @State private var schedule: [Double] = [] // seconds for each step
    @State private var stepIndex: Int = 0

    @State private var stepTimer: Timer?
    @State private var countdownTimer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            if showTitle { // ← NEW
                Text("5–4–3–2–1 Grounding")
                    .font(.title2).bold()
            }

            Text(timeString(countdown))
                .font(.footnote)
                .monospacedDigit()

            Text(instruction)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VerseTicker(lines: verses)
        }
        .onAppear { start() }
        .onDisappear { stop() }
    }

    private func start() {
        stop()

        // Build the schedule (5 items for steps 5,4,3,2,1)
        if let custom = perStepDurations, custom.count == 5 {
            schedule = custom
        } else {
            let even = Double(totalDuration) / 5.0
            schedule = Array(repeating: even, count: 5)
        }

        // Start countdown
        countdown = totalDuration
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                stop()
                onComplete?()
            }
        }

        // Start step rotation
        step = 5
        stepIndex = 0
        runCurrentStep()
    }

    private func runCurrentStep() {
        guard stepIndex < schedule.count else { return }
        let delay = schedule[stepIndex]

        stepTimer?.invalidate()
        stepTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            // Move to next step (5→4→3→2→1)
            if step > 1 { step -= 1 }
            stepIndex += 1

            if stepIndex < schedule.count {
                runCurrentStep()
            }
        }
    }

    private func stop() {
        stepTimer?.invalidate(); stepTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
    }

    private var instruction: String {
        switch step {
        case 5: return "Notice FIVE things you can see."
        case 4: return "Notice FOUR things you can touch."
        case 3: return "Notice THREE things you can hear."
        case 2: return "Notice TWO things you can smell."
        default: return "Notice ONE thing you can taste."
        }
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0) / 60, s = max(t,0) % 60
        return String(format: "%01d:%02d", m, s)
    }
}
