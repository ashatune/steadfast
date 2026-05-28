import SwiftUI
import UIKit

enum OnboardingPalette {
    static let primaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.98)
            : UIColor.label
    })

    static let secondaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.86)
            : UIColor.secondaryLabel
    })

    static let cardFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.10, blue: 0.30, alpha: 0.72)
            : UIColor(white: 1.0, alpha: 0.58)
    })

    static let selectedCardFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.15, blue: 0.42, alpha: 0.78)
            : UIColor.systemBackground.withAlphaComponent(0.72)
    })

    static let controlFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.12, blue: 0.34, alpha: 0.86)
            : UIColor.secondarySystemBackground
    })

    static let backgroundVeil = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.04, blue: 0.18, alpha: 0.10)
            : UIColor(white: 1.0, alpha: 0.18)
    })

    static let subtleStroke = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.22)
            : UIColor(white: 0.0, alpha: 0.12)
    })
}
