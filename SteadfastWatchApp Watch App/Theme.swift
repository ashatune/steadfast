//
//  Theme.swift
//  Steadfast
//
//  Created by Asha Redmon on 11/6/25.
//

// Theme.swift (watchOS target)
import SwiftUI

enum Theme {
    // Brand colors (example lavender gradient—replace with your hexes)
    static let purpleStart = Color(hex: 0x8C7BFF)  // light lavender
    static let purpleEnd   = Color(hex: 0xC7B7FF)  // softer lilac
    static let ink         = Color(hex: 0x1C1B22)  // text color if needed
    static let surface     = Color.black.opacity(0.10) // subtle card bg

    // Primary gradient used for the breathing ring
    static var anchorGradient: LinearGradient {
        LinearGradient(
            colors: [purpleStart, purpleEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // If you want a darker variant for .dark mode (optional)
    static func anchorGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    purpleStart.opacity(0.9),
                    purpleEnd.opacity(0.9)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            return anchorGradient
        }
    }
}

extension Color {
    /// Create a Color from a hex like 0xRRGGBB
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
