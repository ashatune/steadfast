import SwiftUI

struct FinalCalmView: View {
    var totalDuration: Int = 10
    var messages: [String] = []

    @Environment(\.onComplete) private var onComplete

    @State private var countdown: Int = 10
    @State private var scale: CGFloat = 1.05
    @State private var animTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var msgIdx: Int = 0
    @State private var msgVisible: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.thinMaterial, lineWidth: 8)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 2.0), value: scale)
            }
            if !messages.isEmpty {
                Text(messages[msgIdx])
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .opacity(msgVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 2.0), value: msgVisible)
                    .padding(.horizontal)
            }
            Text(timeString(countdown)).font(.footnote).monospacedDigit()
        }
        .onAppear { start() }
        .onDisappear { stop() }
    }

    private func start() {
        stop()
        countdown = totalDuration

        // breathe-like gentle expand/contract
        animTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3.0)) { scale = 1.15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 4.0)) { scale = 0.9 }
            }
        }

        // rotate messages every ~3s
        if !messages.isEmpty {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                msgVisible = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    msgIdx = (msgIdx + 1) % messages.count
                    msgVisible = true
                }
            }
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                stop()
                onComplete?()
            }
        }
    }

    private func stop() {
        animTimer?.invalidate(); animTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
    }

    private func timeString(_ t: Int) -> String {
        let m = max(t,0) / 60, s = max(t,0) % 60
        return String(format: "%01d:%02d", m, s)
    }
}
