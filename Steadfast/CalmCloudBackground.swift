import SwiftUI

/// Calm drifting "cloud" blobs with noticeable motion (TimelineView-driven).
struct CalmCloudsBackground: View {
    var base: Color = Theme.bg
    var cloudColors: [Color] = [
        Theme.accent.opacity(0.24),
        Theme.accent2.opacity(0.22),
        Theme.support.opacity(0.20)
    ]
    var count: Int = 10            // more blobs = more motion visible
    var speed: Double = 0.10       // 🔹 global drift speed (0.06 subtle → 0.10+ more noticeable)
    var amplitude: CGFloat = 0.20  // 🔹 fraction of screen used for drift radius (0.10 subtle → 0.20+ more noticeable)
    var opacityRange: ClosedRange<Double> = 0.14...0.26 // 🔹 raise for visibility

    var body: some View {
        GeometryReader { geo in
            ZStack {
                base.ignoresSafeArea()
                TimelineView(.animation) { tick in
                    let t = tick.date.timeIntervalSinceReferenceDate * speed
                    ForEach(0..<count, id: \.self) { i in
                        let seed = Double(i) * 37.0
                        CloudBlobFrame(
                            size: geo.size,
                            color: cloudColors[i % cloudColors.count],
                            t: t,
                            seed: seed,
                            amplitude: amplitude,
                            opacityRange: opacityRange
                        )
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct CloudBlobFrame: View {
    let size: CGSize
    let color: Color
    let t: Double
    let seed: Double
    let amplitude: CGFloat
    let opacityRange: ClosedRange<Double>

    // deterministic pseudo-random
    private func rnd(_ k: Double) -> Double {
        let x = sin(k * 127.1 + seed * 311.7) * 43758.5453
        return x - floor(x)
    }

    var body: some View {
        let w = size.width, h = size.height
        let mx = max(w, h)

        // Random center anywhere (more visible across the page)
        let cx = rnd(seed + 11) * w
        let cy = rnd(seed + 12) * h

        // Larger drift radius (amplitude), independently in X/Y
        let ax = (amplitude * (0.7 + rnd(seed + 7) * 0.8)) * w
        let ay = (amplitude * (0.7 + rnd(seed + 8) * 0.8)) * h

        // Lissajous-like path (noticeable but still smooth)
        let px = cx + ax * sin(t + seed * 0.23)
        let py = cy + ay * cos(t * 0.9 + seed * 0.19)

        // Bigger shape with stronger pulse/rotation
        let baseSize = mx * (0.26 + rnd(seed + 9) * 0.36)
        let scalePulse = 1.0 + 0.10 * sin(t * 1.3 + seed * 0.17)
        let rot = Angle.degrees(sin(t * 0.7 + seed) * 15)
        let op = opacityRange.lowerBound + rnd(seed + 10) * (opacityRange.upperBound - opacityRange.lowerBound)

        RoundedRectangle(cornerRadius: baseSize * 0.5, style: .continuous)
            .fill(color)
            .frame(width: baseSize, height: baseSize)
            .blur(radius: baseSize * 0.20)           // slightly sharper for visibility
            .scaleEffect(scalePulse)
            .rotationEffect(rot)
            .opacity(op)
            .position(x: px, y: py)
    }
}
