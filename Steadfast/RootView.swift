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
                
            }
        }
        .onAppear {
            AppReviewManager.shared.registerLaunch()
            AppReviewManager.shared.attemptPromptIfEligible(reason: "app launch")
            vm.consumePendingRouteFromDefaults()
        }
        .tint(Theme.accent)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $vm.showSOS) {
            SOSFlow()
        }
    }
}
