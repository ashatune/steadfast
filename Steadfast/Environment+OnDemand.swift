import SwiftUI

// Make this globally available (not private)
struct OnCompleteKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var onComplete: (() -> Void)? {
        get { self[OnCompleteKey.self] }
        set { self[OnCompleteKey.self] = newValue }
    }
}

extension View {
    /// Attach a completion callback into the environment for child views to call.
    func onComplete(_ action: @escaping () -> Void) -> some View {
        environment(\.onComplete, action)
    }
}
