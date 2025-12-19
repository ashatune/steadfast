import SwiftUI
import WidgetKit   // optional, for reloads/logs

@main
struct SteadfastApp: App {
    // Existing app VM + scene phase
    @StateObject private var appVM = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

    // Splash
    @AppStorage("hasShownSplash") private var hasShownSplash = false
    @State private var showSplash: Bool

    // Remote config + gating state
    @StateObject private var remote = RemoteConfigService()
    @State private var showBlock = false
    @State private var storeUrl = ""

    // Feature flags available app-wide
    @StateObject private var flags = FeatureFlags()

    init() {
        // ✅ sensible first-launch defaults
        UserDefaults.standard.register(defaults: [
            "hasShownSplash": false,
            "hasCompletedOnboarding": false,
            "hasAcceptedTerms": false,
            "displayName": "",
            "ttsGuidanceEnabled": false
        ])
        _showSplash = State(initialValue: !UserDefaults.standard.bool(forKey: "hasShownSplash"))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(appVM)
                    .environmentObject(flags) // 👈 expose flags to the tree
                    .overlay { if showSplash { SplashView().transition(.opacity) } }

                // Hard block overlay (no dismissal)
                if showBlock {
                    UpdateRequiredView(storeUrl: storeUrl)
                }
            }
            // Splash timing
            .task {
                if showSplash {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation { showSplash = false }
                    hasShownSplash = true
                }
            }
            // One-time startup setup
            .onAppear {
                NotificationManager.shared.configure()
                NotificationManager.shared.requestAndScheduleDailyCheckins()
                SoundManager.shared.configureAudioSession(playThroughSilentSwitch: true)
                TTSManager.shared.preparePreferredVoice(languages: ["en-US","en-GB"])

                appVM.refreshToday()
            }
            // Fetch remote config on launch + evaluate
            .task { await remote.fetch(); evaluateGate() }
            // Fetch again when app returns to foreground
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    Task {
                        await remote.fetch()
                        evaluateGate()
                        appVM.refreshToday()
                    }
                }
            }
            // Keep flags & gate in sync when config changes
            .onReceive(remote.$config.compactMap { $0 }) { cfg in
                flags.update(from: cfg)
                evaluateGate()
            }
            // Handle deep links from widget / URL scheme
            .onOpenURL { url in
                appVM.handleDeepLink(url)
            }
        }
    }

    // MARK: - Gate evaluation
    private func evaluateGate() {
        guard let c = remote.config else { return }
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        storeUrl = c.storeUrl
        showBlock = isOutdated(current, comparedTo: c.minVersion)
    }
}
