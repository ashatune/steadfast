import SwiftUI

struct ReflectionPulseView: View {
    let reflections: [Reflection]
    var interval: TimeInterval = 6.0
    var fade: TimeInterval = 0.6
    var useBodyKeywords: Bool = false
    var subtitle: String? = "Pause here for a moment."   // NEW
    var customTokens: [String]? = nil                     // NEW

    @State private var idx = 0
    @State private var visible = true
    @State private var pulse = false

    private var tokens: [String] {
        if let customTokens, !customTokens.isEmpty { return customTokens }
        var acc: [String] = []
        let texts = reflections.map { useBodyKeywords ? $0.body : $0.title }
        for t in texts { for w in keywords(from: t) where !acc.contains(w) { acc.append(w) } }
        return acc.isEmpty ? ["Breathe","Release","Trust","Rest"] : acc
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(tokens[idx])
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.thinMaterial))
                .opacity(visible ? 1 : 0)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                .animation(.easeInOut(duration: fade), value: visible)

            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .onAppear { pulse = true; startTicker() }
    }

    private func startTicker() {
        guard !tokens.isEmpty else { return }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            visible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                idx = (idx + 1) % tokens.count
                visible = true
            }
        }
    }

    private func keywords(from text: String) -> [String] {
        let stop: Set<String> = ["the","and","to","of","a","an","is","in","on","for","with","your","you","be","not",
                                 "my","me","i","it","this","that","are","am","as","at","by","from","or","but","if",
                                 "then","so","will","shall","have","has","had","do","does","did","let","into","over"]
        let raw = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.map { $0.lowercased() }
        var out: [String] = []
        for w in raw where w.count >= 3 && !stop.contains(w) {
            let cap = w.capitalized
            if !out.contains(cap) { out.append(cap) }
        }
        return out
    }
}
