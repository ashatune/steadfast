import SwiftUI
import Combine

struct HomeView: View {
    @AppStorage("displayName") private var storedDisplayName = ""

    @EnvironmentObject var vm: AppViewModel
    @State private var showAnchorFlow = false
    @EnvironmentObject var flags: FeatureFlags
    @State private var showProfileSheet = false
    @State private var now = Date()

    enum TopTab { case home, reframe }
    @State private var topTab: TopTab = .home

    // Reframe feature state (in-memory while testing)
    @State private var reframes: [ReframeEntry] = []
    @State private var showReframeComposer = false

    private let sidePadding: CGFloat = 16
    private let sectionSpacing: CGFloat = 6

    // Single, canonical anchor of the day used across the home screen
    private var anchorOfDay: Verse {
        vm.anchorOfDay ?? AnchorService.shared.anchorsForToday(count: 1).first ?? Verse(ref: "Psalm 56:3")
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
            }
        }

        // Hidden navigation trigger for deep links
        NavigationLink("", isActive: $showAnchorFlow) {
            AnchorBreathView(
                verse: anchorOfDay,
                totalDuration: 90,
                inhaleSecs: 4,
                holdSecs: 4,
                exhaleSecs: 6,
                bgm: .local(name: "wanderingMeditation", ext: "mp3")
            )
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

                // Big SOS button
                SOSButton { vm.showSOS = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)


                // Daily Rhythm
                DailyRhythmView()
                    .padding(.horizontal, sidePadding)

                // Today’s Anchor
                VerseOfDayStrip(verse: anchorOfDay)
                    .padding(.horizontal, sidePadding)
                    .padding(.bottom, 16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
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

    private var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}
