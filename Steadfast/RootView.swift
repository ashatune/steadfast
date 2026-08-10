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
            TabView(selection: $vm.selectedTab) {
                // HOME
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppViewModel.AppTab.home)
                
                // LIBRARY
                NavigationStack {
                    LibraryView()
                }
                .tabItem { Label("Library", systemImage: "book.fill") }
                .tag(AppViewModel.AppTab.library)
                
                // MEDITATE / PRAYERS
                NavigationStack {
                    PrayersView()
                }
                .tabItem { Label("Meditate", systemImage: "hands.sparkles.fill") }
                .tag(AppViewModel.AppTab.meditate)
                
                // SETTINGS
                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppViewModel.AppTab.settings)
                
            }
        }
        .onAppear {
            vm.consumePendingRouteFromDefaults()
        }
        .tint(Theme.accent)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $vm.showSOS) {
            CalmNowIntroView()
        }
    }
}
