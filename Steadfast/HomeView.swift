import SwiftUI
import Combine

struct HomeView: View {
    @AppStorage("displayName") private var storedDisplayName = ""

    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject private var streakManager: StreakManager
    @State private var showAnchorFlow = false
    @EnvironmentObject var flags: FeatureFlags
    @State private var showProfileSheet = false
    @State private var now = Date()
    @StateObject private var devotionalVM = DailyDevotionalViewModel()
    @State private var showDevotionalDetail = false
    @State private var devotionalDeepLinkPending = false

    enum TopTab { case home, reframe }
    @State private var topTab: TopTab = .home

    // Reframe feature state (in-memory while testing)
    @State private var reframes: [ReframeEntry] = []
    @State private var showReframeComposer = false

    private let sidePadding: CGFloat = 16
    private let sectionSpacing: CGFloat = 6

    // Single, canonical anchor of the day used across the home screen
    private var anchorOfDay: Verse {
        vm.anchorOfDay ?? DailyVerseProvider.shared.verse(for: Date(), calendar: Calendar.current)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch topTab {
                case .home:
                    homeContent

                case .reframe:
                    // Always present the Reframe page (it self-blocks with the overlay)
                    ReframeLandingView(
                        reframes: $reframes,
                        onStart: { showReframeComposer = true }
                    )
                    .background(Theme.bg.ignoresSafeArea())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered top tabs with underline
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 40) {
                        tabButton(label: "Home", isActive: topTab == .home) {
                            withAnimation(.easeInOut) { topTab = .home }
                        }
                        tabButton(label: "Reframe", isActive: topTab == .reframe) {
                            withAnimation(.easeInOut) { topTab = .reframe }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Profile icon on the right
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileMonogram(initial: vm.profileInitial)
                        .onTapGesture { showProfileSheet = true }
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.ink)

        // Sheets
        .sheet(isPresented: $showProfileSheet) {
            NavigationStack { ProfileSheetView().environmentObject(vm) }
        }
        .sheet(isPresented: $showReframeComposer) {
            ReframeGuidedFlow { entry in
                reframes.insert(entry, at: 0)
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
            .presentationDragIndicator(.visible)
        }

        // Tick greeting + refresh anchors
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        .onChange(of: vm.pendingDeepLink) { dest in
            guard let dest = dest else { return }
            if dest == .anchor {
                showAnchorFlow = true
                vm.pendingDeepLink = nil
            } else if dest == .devotional {
                devotionalDeepLinkPending = true
                devotionalVM.refresh()
            }
        }

        // Hidden navigation trigger for deep links
        NavigationLink("", isActive: $showAnchorFlow) {
            AnchorBreathView(
                verse: anchorOfDay,
                totalDuration: 90,
                inhaleSecs: 4,
                holdSecs: 4,
                exhaleSecs: 6
            )
        }
        .hidden()
        NavigationLink("", isActive: $showDevotionalDetail) {
            if let devotional = devotionalVM.devotional {
                DailyDevotionalDetailView(devotional: devotional)
            }
        }
        .hidden()
    }

    // MARK: - Home content
    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                // Greeting
                Text("\(greetingPrefix), \(greetingName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)
                    .transition(.opacity)

                streakSection
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 4)

                // Big SOS button
                SOSButton { vm.showSOS = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                rhythmHeader
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)

                FlowStepCard(
                    stepNumber: 1,
                    label: "Devotional",
                    isComplete: streakManager.hasDevotionalCompletion(on: now),
                    showsConnector: true
                ) {
                    devotionalSection
                }
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 2)

                FlowStepCard(
                    stepNumber: 2,
                    label: "Anchor Exercise",
                    isComplete: streakManager.hasAnchorCompletion(on: now),
                    showsConnector: false
                ) {
                    VerseOfDayStrip(verse: anchorOfDay)
                }
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)

                // Daily Rhythm
                DailyRhythmView()
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 14)

                libraryFooterSection
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            devotionalVM.loadDevotionalIfNeeded()
        }
        .onAppear {
            vm.syncProfileNameFromDefaults()
            print("🏠 Home screen reached; triggering devotional fetch")
            devotionalVM.refresh()
        }
        .onChange(of: storedDisplayName) { _ in
            vm.syncProfileNameFromDefaults()
        }
        .onChange(of: devotionalVM.devotional?.id) { _ in
            guard devotionalDeepLinkPending else { return }
            if devotionalVM.devotional != nil {
                showDevotionalDetail = true
                devotionalDeepLinkPending = false
                vm.pendingDeepLink = nil
            }
        }
    }

    // MARK: - Tab button (underline style)
    private func tabButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Theme.ink : Theme.inkSecondary)
                    .contentTransition(.identity)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear).frame(height: 2)
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: isActive ? nil : 0, height: 2)
                        .animation(.easeInOut(duration: 0.22), value: isActive)
                }
                .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2)
                .clipShape(RoundedRectangle(cornerRadius: 1))
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 64)
    }

    // MARK: - Greeting helpers
    private var greetingName: String {
        let fromStorage = storedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = firstWord(fromStorage), !first.isEmpty { return first.capitalized }

        let fromVM = vm.profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = firstWord(fromVM), !first.isEmpty { return first.capitalized }

        return "Friend"
    }

    private func firstWord(_ s: String) -> String? {
        guard !s.isEmpty else { return nil }
        return s.split(separator: " ").first.map(String.init)
    }

    private var devotionalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sunrise.fill")
                    .foregroundStyle(Theme.accent)
                Text("Daily Devotional")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Group {
                if let devotional = devotionalVM.devotional {
                    NavigationLink(destination: DailyDevotionalDetailView(devotional: devotional)) {
                        DailyDevotionalCard(devotional: devotional, isLoading: devotionalVM.isLoading)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    DailyDevotionalCard(devotional: nil, isLoading: devotionalVM.isLoading)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var rhythmHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today’s rhythm 🙏")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)

            if streakManager.hasDevotionalCompletion(on: now), streakManager.hasAnchorCompletion(on: now) {
                Text("You’ve completed your rhythm for today 🙏")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private var streakSection: some View {
        let days = streakManager.statusForLast7Days()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(streakManager.streakText())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text("This week")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
            }

            HStack(spacing: 10) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        Text(day.label)
                            .font(.caption.weight(day.isToday ? .semibold : .regular))
                            .foregroundStyle(day.isToday ? Theme.ink : Theme.inkSecondary)

                        Circle()
                            .fill(day.isCompleted ? Theme.accent.opacity(day.isToday ? 0.55 : 0.35) : Theme.line)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(day.isToday ? Theme.accent.opacity(0.45) : Color.clear, lineWidth: 2)
                                    .frame(width: 18, height: 18)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line)
        )
    }

    private var libraryFooterSection: some View {
        LibraryShortcutCard {
            vm.selectedTab = .library
        }
        .padding(.horizontal, sidePadding)
        .padding(.top, 2)
        .padding(.bottom, 16)
    }

    private var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        default:      return "Good evening"
        }
    }

}

private struct LibraryShortcutCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Looking for something specific?")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)

            Button(action: action) {
                HStack(spacing: 8) {
                    Text("Explore Verse Library")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}

struct FlowStepCard<Content: View>: View {
    let stepNumber: Int
    let label: String
    let isComplete: Bool
    var showsConnector: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                indicator

                if showsConnector {
                    Rectangle()
                        .fill(Theme.line.opacity(0.9))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }
            .frame(width: 32)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step \(stepNumber): \(label)")
    }

    private var indicator: some View {
        ZStack {
            Circle()
                .fill(isComplete ? Theme.accent.opacity(0.14) : Theme.surface)
                .frame(width: 28, height: 28)
            Circle()
                .stroke(isComplete ? Theme.accent.opacity(0.45) : Theme.line, lineWidth: 1)
                .frame(width: 28, height: 28)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("\(stepNumber)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
