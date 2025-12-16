// VerseTicker.swift
import SwiftUI

struct VerseTicker: View {
    let lines: [String]
    var interval: TimeInterval = 14.0      // ← seconds each verse is shown
    var fade: TimeInterval = 0.8

    @State private var idx: Int = 0
    @State private var visible: Bool = true

    var body: some View {
        ZStack {
            if !lines.isEmpty {
                Text(lines[idx])
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .opacity(visible ? 1 : 0)
                    .animation(.easeInOut(duration: fade), value: visible)
                    .onAppear { run() }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(lines.isEmpty ? "" : lines[idx])
    }

    private func run() {
        guard !lines.isEmpty else { return }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            visible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
                idx = (idx + 1) % lines.count
                visible = true
            }
        }
    }
}


