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
    @State private var expandedRhythmCard: ExpandedRhythmCard?
    @State private var rhythmNodeCenters: [Int: CGFloat] = [:]

    enum TopTab { case home, reframe }
    private enum ExpandedRhythmCard { case devotional, anchor }
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

                rhythmCardsSection
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 2)

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

    private var rhythmCardsSection: some View {
        ZStack(alignment: .leading) {
            rhythmTimelineLine

            VStack(spacing: 8) {
                RhythmTimelineRow(stepNumber: 1) {
                    devotionalRhythmCard
                }

                RhythmTimelineRow(stepNumber: 2) {
                    anchorRhythmCard
                }
            }
        }
        .coordinateSpace(name: "rhythmTimeline")
        .onPreferenceChange(RhythmNodeCenterPreferenceKey.self) { centers in
            rhythmNodeCenters = centers
        }
    }

    @ViewBuilder
    private var rhythmTimelineLine: some View {
        if let firstCenter = rhythmNodeCenters[1], let secondCenter = rhythmNodeCenters[2] {
            Rectangle()
                .fill(Theme.line.opacity(0.65))
                .frame(width: 1.5, height: max(0, secondCenter - firstCenter))
                .position(x: RhythmTimelineMetrics.nodeCenterX, y: (firstCenter + secondCenter) / 2)
                .accessibilityHidden(true)
        }
    }

    private func rhythmExpansionBinding(for card: ExpandedRhythmCard) -> Binding<Bool> {
        Binding(
            get: { expandedRhythmCard == card },
            set: { isExpanded in
                if isExpanded {
                    expandedRhythmCard = card
                } else if expandedRhythmCard == card {
                    expandedRhythmCard = nil
                }
            }
        )
    }

    private var devotionalRhythmCard: some View {
        CollapsibleRhythmCard(
            isExpanded: rhythmExpansionBinding(for: .devotional),
            isComplete: streakManager.hasDevotionalCompletion(on: now),
            accessibilityLabel: "Daily Devotional"
        ) {
            Text("Daily Devotional")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.ink)
        } expandedContent: {
            VStack(alignment: .leading, spacing: 8) {
                if devotionalVM.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Theme.accent)
                        Text("Loading today’s devotional…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                } else if let devotional = devotionalVM.devotional {
                    Text(devotional.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(devotional.verseReference)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)

                    Button {
                        showDevotionalDetail = true
                    } label: {
                        Text("Read")
                            .rhythmCTALabelStyle()
                    }
                    .padding(.top, 4)
                } else {
                    Text("No devotional available for today.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var anchorRhythmCard: some View {
        CollapsibleRhythmCard(
            isExpanded: rhythmExpansionBinding(for: .anchor),
            isComplete: streakManager.hasAnchorCompletion(on: now),
            accessibilityLabel: "Anchor of the Day"
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Anchor of the Day")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                if expandedRhythmCard != .anchor {
                    Text(anchorOfDay.ref)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        } expandedContent: {
            VStack(alignment: .leading, spacing: 8) {
                Text(anchorOfDay.ref)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text("Breathe with today’s verse.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)

                Button {
                    showAnchorFlow = true
                } label: {
                    Text("Start anchor verse")
                        .rhythmCTALabelStyle()
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rhythmHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today’s rhythm")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)

            if streakManager.hasDevotionalCompletion(on: now), streakManager.hasAnchorCompletion(on: now) {
                Text("You’ve completed your rhythm for today")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private var streakSection: some View {
        let days = streakManager.statusForLast7Days()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(streakManager.streakText(prefix: ""))
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
        }
    }
}

private enum RhythmTimelineMetrics {
    static let columnWidth: CGFloat = 32
    static let nodeSize: CGFloat = 26
    static let nodeCenterX = columnWidth / 2
}

private struct RhythmNodeCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct RhythmTimelineRow<Content: View>: View {
    let stepNumber: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RhythmStepNode(stepNumber: stepNumber)
                .frame(width: RhythmTimelineMetrics.columnWidth)

private struct RhythmStepNode: View {
    let stepNumber: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.bg)
                .frame(width: RhythmTimelineMetrics.nodeSize, height: RhythmTimelineMetrics.nodeSize)

            Circle()
                .stroke(Theme.line.opacity(0.8), lineWidth: 1)
                .frame(width: RhythmTimelineMetrics.nodeSize, height: RhythmTimelineMetrics.nodeSize)

            Text("\(stepNumber)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
    }
}

private struct RhythmStepNode: View {
    let stepNumber: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.bg)
                .frame(width: RhythmTimelineMetrics.nodeSize, height: RhythmTimelineMetrics.nodeSize)

            Circle()
                .stroke(Theme.line.opacity(0.8), lineWidth: 1)
                .frame(width: RhythmTimelineMetrics.nodeSize, height: RhythmTimelineMetrics.nodeSize)

            Text("\(stepNumber)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(width: RhythmTimelineMetrics.columnWidth, height: RhythmTimelineMetrics.nodeSize)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: RhythmNodeCenterPreferenceKey.self,
                    value: [stepNumber: proxy.frame(in: .named("rhythmTimeline")).midY]
                )
            }
        )
        .accessibilityHidden(true)
    }
}

private extension View {
    func rhythmCTALabelStyle() -> some View {
        font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.accent.opacity(0.92))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }
}

private struct CollapsibleRhythmCard<CollapsedContent: View, ExpandedContent: View>: View {
    @Binding private var isExpanded: Bool
    private let isComplete: Bool
    private let accessibilityLabel: String
    private let collapsedBody: () -> CollapsedContent
    private let expandedBody: () -> ExpandedContent

    init(
        isExpanded: Binding<Bool>,
        isComplete: Bool,
        accessibilityLabel: String,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        _isExpanded = isExpanded
        self.isComplete = isComplete
        self.accessibilityLabel = accessibilityLabel
        collapsedBody = collapsedContent
        expandedBody = expandedContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
            HStack(alignment: .center, spacing: 12) {
                collapsedBody()
                    .frame(maxWidth: .infinity, alignment: .leading)

                completionIndicator
            }

            if isExpanded {
                expandedBody()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.line.opacity(0.55), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                isExpanded.toggle()
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
    }

    private var completionIndicator: some View {
        ZStack {
            Circle()
                .fill(isComplete ? Theme.accent.opacity(0.14) : Theme.surface.opacity(0.8))
                .frame(width: 28, height: 28)

            Circle()
                .stroke(isComplete ? Theme.accent.opacity(0.45) : Theme.line, lineWidth: 1)
                .frame(width: 28, height: 28)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .accessibilityHidden(true)
    }
}
