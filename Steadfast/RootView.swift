import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: AppViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainShell
            } else {
                OnboardingFlowView() // sets hasCompletedOnboarding = true on finish
            }
        }
    }

    // MARK: - Main Tab Shell
    private var mainShell: some View {
        ZStack {
            TabView {
                // HOME
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                
                // LIBRARY
                NavigationStack {
                    LibraryView()
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
                
                // MEDITATE / PRAYERS
                NavigationStack {
                    PrayersView()
                }
                .tabItem { Label("Meditate", systemImage: "hands.sparkles.fill") }
                
                // SETTINGS
                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                
                // SUPPORT (external link to MustardSeedLabs.io)
                NavigationStack {
                    SupportView()
                }
                .tabItem { Label("Support Us", systemImage: "heart.fill") }
            }
        }
        .onAppear {
            AppReviewManager.shared.registerLaunch()
            AppReviewManager.shared.attemptPromptIfEligible()
            // 👇 NEW: consume pending notification route
                if let route = UserDefaults.standard.string(forKey: "steadfast.pendingRoute") {
                    UserDefaults.standard.removeObject(forKey: "steadfast.pendingRoute")

                    switch route {
                    case "morning":
                        vm.pendingDeepLink = .morning
                    case "midday":
                        vm.pendingDeepLink = .midday
                    case "evening":
                        vm.pendingDeepLink = .evening
                    case "anchor":
                        vm.pendingDeepLink = .anchor
                    case "devotional/today":
                        vm.pendingDeepLink = .devotional
                    default:
                        break
                    }
                }
        }
        .tint(Theme.accent)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $vm.showSOS) {
            SOSFlow()
        }
    }
}
