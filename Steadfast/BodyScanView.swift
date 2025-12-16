import SwiftUI

/// A safe, cancellation-aware body scan: fades each line in/out, then calls onComplete.
struct BodyScanView: View {
    let lines: [String]
    var perStepSeconds: TimeInterval = 9.0   // hold time per line
    var fade: TimeInterval = 0.6             // fade duration

    @Environment(\.onComplete) private var onComplete

    @State private var index: Int = 0
    @State private var visible: Bool = false
    @State private var task: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 14) {
            if let line = currentLine {
                Text(line)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: fade), value: visible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            // If there are no lines, finish immediately
            guard !lines.isEmpty else { onComplete?(); return }
            // Prevent double starts
            guard task == nil else { return }
            startSequence()
        }
        // in .onDisappear:
        .onDisappear {
            task?.cancel(); task = nil
            TTSManager.shared.stop()                          // ← stop any speech
        }
    }

    private var currentLine: String? {
        guard lines.indices.contains(index) else { return nil }
        return lines[index]
    }

    private func startSequence() {
        task = Task {
            // Iterate safely over indices
            for i in lines.indices {
                // Update the line and fade in
                await MainActor.run {
                    index = i
                    withAnimation(.easeInOut(duration: fade)) { visible = true }
                }
                // inside startSequence() after setting `index = i` and `visible = true`:
                await MainActor.run {
                    index = i
                    withAnimation(.easeInOut(duration: fade)) { visible = true }
                    TTSManager.shared.speak(lines[i])                 // ← speak this step
                }



                // Hold the line
                try? await Task.sleep(nanoseconds: UInt64(perStepSeconds * 1_000_000_000))

                // Fade out
                await MainActor.run {
                    withAnimation(.easeInOut(duration: fade)) { visible = false }
                }

                // Wait for fade to complete (and allow cancellation)
                try? await Task.sleep(nanoseconds: UInt64(fade * 1_000_000_000))
                if Task.isCancelled { return }
            }

            // Done → advance flow once
            await MainActor.run { onComplete?() }
        }
    }
}
