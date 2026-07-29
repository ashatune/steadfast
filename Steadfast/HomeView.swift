import SwiftUI
import Combine
import UIKit

struct HomeView: View {
    @AppStorage("displayName") private var storedDisplayName = ""
    @AppStorage("home.devotionalVerseCompletedDay") private var devotionalVerseCompletedDay = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenHomeTutorial") private var hasSeenHomeTutorial = false

    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject private var streakManager: StreakManager
    @State private var showAnchorFlow = false
    @State private var showAnchorDurationPicker = false
    @State private var selectedAnchorDuration: MeditationDurationOption?
    @EnvironmentObject var flags: FeatureFlags
    @Environment(\.scenePhase) private var scenePhase
    @State private var showProfileSheet = false
    @State private var now = Date()
    @StateObject private var devotionalVM = DailyDevotionalViewModel()
    @State private var showDevotionalDetail = false
    @State private var presentedDevotionalStory: PresentedDevotionalStory?
    @State private var selectedDevotionalForDetail: DailyDevotional?
    @State private var pendingDevotionalDetail: DailyDevotional?
    @State private var devotionalDeepLinkPending = false
    @State private var expandedRhythmCard: ExpandedRhythmCard?
    @State private var rhythmNodeCenters: [Int: CGFloat] = [:]
    @State private var didOpenDevotionalDetail = false
    @State private var previousDevotionalCompletion = false
    @State private var previousAnchorCompletion = false
    @State private var didInitializeCompletionState = false

    enum TopTab { case home, reframe }
    private enum ExpandedRhythmCard { case devotionalVerse, devotional, anchor }
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
        .sheet(isPresented: $showAnchorDurationPicker) {
            MeditationDurationPickerSheet(
                title: "Anchor of the Day",
                prompt: "How long would you like to breathe with today’s verse?",
                selectedDuration: selectedAnchorDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedAnchorDuration = duration
                showAnchorDurationPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showAnchorFlow = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(
            item: $presentedDevotionalStory,
            onDismiss: {
                completeDevotionalVerseCard(advanceToNext: true)
                if let pendingDevotionalDetail {
                    selectedDevotionalForDetail = pendingDevotionalDetail
                    self.pendingDevotionalDetail = nil
                    showDevotionalDetail = true
                }
            }
        ) { presentation in
            DevotionalVerseStoryView(devotional: presentation.devotional) { capturedDevotional in
                pendingDevotionalDetail = capturedDevotional
                presentedDevotionalStory = nil
            }
        }

        // Tick greeting + refresh anchors
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { tick in
            now = tick
            devotionalVM.refreshIfDayChanged(now: tick)
        }
        .onChange(of: vm.pendingDeepLink) { dest in
            guard let dest = dest else { return }
            if dest == .anchor {
                showAnchorDurationPicker = true
                vm.pendingDeepLink = nil
            } else if dest == .devotional {
                devotionalDeepLinkPending = true
                devotionalVM.refresh(now: now)
            }
        }

        // Hidden navigation trigger for deep links
        NavigationLink("", isActive: $showAnchorFlow) {
            AnchorBreathView(
                verse: anchorOfDay,
                totalDuration: selectedAnchorDuration?.seconds ?? MeditationDurationOption.default.seconds,
                inhaleSecs: 4,
                holdSecs: 4,
                exhaleSecs: 6
            )
        }
        .hidden()
        NavigationLink("", isActive: $showDevotionalDetail) {
            if let devotional = selectedDevotionalForDetail {
                DailyDevotionalDetailView(devotional: devotional)
            }
        }
        .hidden()
    }

    // MARK: - Home content
    private var homeContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                // Greeting
                Text("\(greetingPrefix), \(greetingName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.sectionTitle)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)
                    .transition(.opacity)

                streakSection
                    .frame(maxWidth: .infinity)
                    .homeTutorialTarget(.streak)
                    .id(HomeTutorialTarget.streak)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 4)

                // Big SOS button
                SOSButton { vm.showSOS = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(alignment: .center) {
                        Color.clear
                            .frame(width: 188, height: 188)
                            .homeTutorialTarget(.calmNow)
                            .allowsHitTesting(false)
                    }
                    .id(HomeTutorialTarget.calmNow)
                    .padding(.top, 4)


                rhythmHeader
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)

                rhythmCardsSection
                    .frame(maxWidth: .infinity)
                    .homeTutorialTarget(.dailyDevotional)
                    .id(HomeTutorialTarget.dailyDevotional)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 2)

                // Daily Rhythm
                DailyRhythmView()
                    .homeTutorialTarget(.dailyRhythm)
                    .id(HomeTutorialTarget.dailyRhythm)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 14)

                HomeMeditationsCarouselView()
                    .homeTutorialTarget(.meditations)
                    .id(HomeTutorialTarget.meditations)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 14)

                libraryFooterSection
            }
            }
            .background(Theme.bg.ignoresSafeArea())
            .overlayPreferenceValue(HomeTutorialTargetAnchorPreferenceKey.self) { tutorialAnchors in
                if hasCompletedOnboarding && !hasSeenHomeTutorial && topTab == .home {
                    HomeTutorialOverlay(anchors: tutorialAnchors, onScrollToTarget: { target in
                        switch target {
                        case .explore:
                            scrollProxy.scrollTo(target, anchor: .bottom)
                        default:
                            scrollProxy.scrollTo(target, anchor: .center)
                        }
                    }, onComplete: {
                        hasSeenHomeTutorial = true
                    })
                }
            }
        }
        .task {
            devotionalVM.loadDevotionalIfNeeded(now: now)
        }
        .onAppear {
            vm.syncProfileNameFromDefaults()
            print("🏠 Home screen reached; checking devotional day")
            devotionalVM.loadDevotionalIfNeeded(now: now)
            syncCompletionBaselines()
        }
        .onChange(of: storedDisplayName) { _ in
            vm.syncProfileNameFromDefaults()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            devotionalVM.refreshIfDayChanged(now: Date())
        }
        .onChange(of: devotionalVM.devotional?.id) { _ in
            guard devotionalDeepLinkPending else { return }
            if let devotional = devotionalVM.devotional {
                selectedDevotionalForDetail = devotional
                showDevotionalDetail = true
                devotionalDeepLinkPending = false
                vm.pendingDeepLink = nil
            }
        }
        .onChange(of: showDevotionalDetail) { isPresented in
            if isPresented {
                didOpenDevotionalDetail = true
            } else if didOpenDevotionalDetail {
                didOpenDevotionalDetail = false
                completeDevotionalCard(advanceToNext: true)
            }
        }
        .onReceive(streakManager.$devotionalCompletionDays) { _ in
            handleDevotionalCompletionChange()
        }
        .onReceive(streakManager.$anchorCompletionDays) { _ in
            handleAnchorCompletionChange()
        }
        .onChange(of: now) { _ in
            syncCompletionBaselines()
        }
    }

    // MARK: - Tab button (underline style)
    private func tabButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Theme.sectionTitle : Theme.inkSecondary)
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

    private var todayCompletionKey: String {
        Self.devotionalVerseCompletionFormatter.string(from: now)
    }

    private var hasDevotionalVerseCompletion: Bool {
        devotionalVerseCompletedDay == todayCompletionKey
    }

    private func completeDevotionalVerseCard(advanceToNext: Bool) {
        let wasComplete = hasDevotionalVerseCompletion
        if !wasComplete {
            devotionalVerseCompletedDay = todayCompletionKey
            playCompletionFeedback()
        }

        guard advanceToNext else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            expandedRhythmCard = .devotional
        }
    }

    private func completeDevotionalCard(advanceToNext: Bool) {
        let wasComplete = streakManager.hasDevotionalCompletion(on: now)
        if !wasComplete {
            streakManager.markDevotionalCompleted(on: now)
            StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
            playCompletionFeedback()
        }
        previousDevotionalCompletion = true

        guard advanceToNext else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            expandedRhythmCard = .anchor
        }
    }

    private func handleDevotionalCompletionChange() {
        let isComplete = streakManager.hasDevotionalCompletion(on: now)
        guard didInitializeCompletionState else {
            previousDevotionalCompletion = isComplete
            return
        }

        if isComplete, !previousDevotionalCompletion {
            playCompletionFeedback()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                expandedRhythmCard = .anchor
            }
        }
        previousDevotionalCompletion = isComplete
    }

    private func handleAnchorCompletionChange() {
        let isComplete = streakManager.hasAnchorCompletion(on: now)
        guard didInitializeCompletionState else {
            previousAnchorCompletion = isComplete
            return
        }

        if isComplete, !previousAnchorCompletion {
            playCompletionFeedback()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                expandedRhythmCard = nil
            }
        }
        previousAnchorCompletion = isComplete
    }

    private func syncCompletionBaselines() {
        previousDevotionalCompletion = streakManager.hasDevotionalCompletion(on: now)
        previousAnchorCompletion = streakManager.hasAnchorCompletion(on: now)
        didInitializeCompletionState = true
    }

    private func playCompletionFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private static let devotionalVerseCompletionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var rhythmCardsSection: some View {
        ZStack(alignment: .leading) {
            rhythmTimelineLine

            VStack(spacing: 8) {
                RhythmTimelineRow(stepNumber: 1) {
                    devotionalVerseRhythmCard
                }

                RhythmTimelineRow(stepNumber: 2) {
                    devotionalRhythmCard
                }

                RhythmTimelineRow(stepNumber: 3) {
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
        if let firstCenter = rhythmNodeCenters[1], let lastCenter = rhythmNodeCenters[3] {
            Rectangle()
                .fill(Theme.line.opacity(0.65))
                .frame(width: 1.5, height: max(0, lastCenter - firstCenter))
                .position(x: RhythmTimelineMetrics.nodeCenterX, y: (firstCenter + lastCenter) / 2)
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

    private var devotionalVerseRhythmCard: some View {
        CollapsibleRhythmCard(
            isExpanded: rhythmExpansionBinding(for: .devotionalVerse),
            isComplete: hasDevotionalVerseCompletion,
            accessibilityLabel: "Today’s Devotional Verse"
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today’s Devotional Verse")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.cardTitle)

                if let devotional = devotionalVM.devotional, expandedRhythmCard != .devotionalVerse {
                    Text(devotional.verseReference)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        } expandedContent: {
            VStack(alignment: .leading, spacing: 8) {
                if devotionalVM.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Theme.accent)
                        Text("Preparing today’s verse…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                    }

                    Button {
                        presentDevotionalStory()
                    } label: {
                        RhythmCTAButtonLabel("Open verse story")
                    }
                    .padding(.top, 4)
                } else if let devotional = devotionalVM.devotional {
                    Text(devotional.verseReference)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)

                    Text(devotional.verseText)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Button {
                        presentDevotionalStory(with: devotional)
                    } label: {
                        RhythmCTAButtonLabel("Open verse story")
                    }
                    .padding(.top, 4)
                } else {
                    Text("Today’s devotional verse is not available yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)

                    Button {
                        presentDevotionalStory()
                    } label: {
                        RhythmCTAButtonLabel("Open verse story")
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func presentDevotionalStory(with devotional: DailyDevotional? = nil) {
        presentedDevotionalStory = DevotionalStoryPresentationResolver.presentation(
            for: devotional ?? devotionalVM.devotional,
            now: Date()
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
                .foregroundStyle(Theme.cardTitle)
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.cardTitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(devotional.verseReference)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)

                    Button {
                        selectedDevotionalForDetail = devotional
                        showDevotionalDetail = true
                    } label: {
                        RhythmCTAButtonLabel("Read")
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
        .homeTutorialTarget(.dailyDevotional)
        .id(HomeTutorialTarget.dailyDevotional)
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
                    .foregroundStyle(Theme.cardTitle)

                if expandedRhythmCard != .anchor {
                    Text(anchorOfDay.ref)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        } expandedContent: {
            VStack(alignment: .leading, spacing: 8) {
                Text(anchorOfDay.ref)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text("Breathe with today’s verse.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)

                Button {
                    showAnchorDurationPicker = true
                } label: {
                    RhythmCTAButtonLabel("Begin exercise")
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rhythmHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Devotional")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.sectionTitle)

            if hasDevotionalVerseCompletion,
               streakManager.hasDevotionalCompletion(on: now),
               streakManager.hasAnchorCompletion(on: now) {
                Text("You’ve completed today’s devotional steps")
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
        .homeTutorialTarget(.explore)
        .id(HomeTutorialTarget.explore)
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

// MARK: - File-scope helper views

private struct LibraryShortcutCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Image("BibleCard")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 154)

                LinearGradient(
                    colors: [
                        .black.opacity(0.08),
                        .black.opacity(0.32),
                        .black.opacity(0.68)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Explore Verse Library")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Find scripture for what you’re feeling")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .multilineTextAlignment(.leading)

                    Spacer(minLength: 12)

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 154)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Explore Verse Library. Find scripture for what you’re feeling")
        .accessibilityHint("Opens the verse library")
    }
}

private struct DevotionalVerseStoryView: View {
    let devotional: DailyDevotional
    let imageLoader: any DevotionalVerseRemoteImageLoading
    let onContinueToDevotional: (DailyDevotional) -> Void

    init(
        devotional: DailyDevotional,
        imageLoader: any DevotionalVerseRemoteImageLoading = DevotionalVerseRemoteImageLoader.shared,
        onContinueToDevotional: @escaping (DailyDevotional) -> Void
    ) {
        self.devotional = devotional
        self.imageLoader = imageLoader
        self.onContinueToDevotional = onContinueToDevotional
        _resolvedBackground = State(initialValue: DevotionalVerseStoryBackgroundSnapshot.initial(for: devotional))
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var savedStore: SavedDevotionalsStore
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSavedConfirmation = false
    @State private var resolvedBackground: DevotionalVerseStoryBackgroundSnapshot

    private var fallbackBackgroundName: String {
        DevotionalVerseStoryAssets.backgroundName(for: devotional.date)
    }

    private var isSaved: Bool {
        savedStore.isSaved(devotionalID: devotional.id)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                DevotionalVerseStoryContent(
                    devotional: devotional,
                    background: resolvedBackground,
                    logoSize: 72,
                    showsChromeSafePadding: true
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Button {
                                saveDevotionalVerse()
                            } label: {
                                storyActionLabel(
                                    title: isSaved ? "Saved" : "Save",
                                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                                )
                            }
                            .disabled(isSaved)
                            .accessibilityLabel(isSaved ? "Verse story saved" : "Save verse story")

                            Button {
                                shareDevotionalVerse()
                            } label: {
                                storyActionLabel(title: "Share", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share verse story")
                        }

                        Button {
                            continueToDevotional()
                        } label: {
                            Text("Continue to Devotional")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .underline()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .accessibilityLabel("Continue to Devotional")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 12)
                }

                if showSavedConfirmation {
                    VStack {
                        Spacer()
                        Text("Saved to Devotionals")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.38), in: Capsule(style: .continuous))
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 118)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, 12)
                .padding(.trailing, 18)
        }
        .task(id: devotional.id) {
            await resolveRemoteBackgroundIfNeeded(for: devotional)
        }
        .onChange(of: devotional.id) { _ in
            resolvedBackground = DevotionalVerseStoryBackgroundSnapshot(fallbackAssetName: fallbackBackgroundName)
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                DevotionalVerseShareSheet(activityItems: [shareImage])
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.32), in: Circle())
                .overlay(
                    Circle().stroke(.white.opacity(0.22), lineWidth: 1)
                )
        }
        .accessibilityLabel("Close devotional story")
    }

    private func storyActionLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(.black.opacity(0.28), in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }

    private func continueToDevotional() {
        dismiss()
        onContinueToDevotional(devotional)
    }

    private func saveDevotionalVerse() {
        guard !isSaved else { return }
        savedStore.toggleSave(devotional: devotional)
        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSavedConfirmation = false
            }
        }
    }

    @MainActor
    private func shareDevotionalVerse() {
        let backgroundSnapshot = resolvedBackground
        shareImage = DevotionalVerseStoryRenderer.renderImage(
            devotional: devotional,
            background: backgroundSnapshot
        )
        showShareSheet = shareImage != nil
    }

    @MainActor
    private func resolveRemoteBackgroundIfNeeded(for devotional: DailyDevotional) async {
        let fallback = DevotionalVerseStoryBackgroundSnapshot.initial(for: devotional)
        resolvedBackground = fallback

        let requestedDevotionalID = devotional.id
        let resolved = await DevotionalVerseStoryBackgroundResolver.resolve(
            devotional: devotional,
            fallbackAssetName: fallback.fallbackAssetName,
            imageLoader: imageLoader
        )
        guard requestedDevotionalID == self.devotional.id else { return }
        resolvedBackground = resolved
    }
}

private struct DevotionalVerseStoryContent: View {
    let devotional: DailyDevotional
    let background: DevotionalVerseStoryBackgroundSnapshot
    var logoSize: CGFloat
    var showsChromeSafePadding: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            DevotionalVerseStoryBackground(background: background)

            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .black.opacity(0.08),
                    .black.opacity(0.36)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: showsChromeSafePadding ? 96 : 72)

                VStack(spacing: 18) {
                    Text("“\(devotional.verseText)”")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .lineSpacing(8)
                        .lineLimit(10)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.36), radius: 10, x: 0, y: 5)

                    Text(devotional.verseReference)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)

                Spacer()

                Image("SteadfastCROSS1024")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .opacity(0.92)
                    .shadow(color: .black.opacity(0.26), radius: 8, x: 0, y: 4)
                    .padding(.bottom, showsChromeSafePadding ? 116 : 56)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

private struct DevotionalVerseStoryBackground: View {
    let background: DevotionalVerseStoryBackgroundSnapshot

    var body: some View {
        GeometryReader { geo in
            let screenSize = UIScreen.main.bounds.size
            let fullWidth = max(
                geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                screenSize.width
            )
            let fullHeight = max(
                geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom,
                screenSize.height
            )
            let centerX = geo.size.width / 2 + (geo.safeAreaInsets.trailing - geo.safeAreaInsets.leading) / 2
            let centerY = geo.size.height / 2 + (geo.safeAreaInsets.bottom - geo.safeAreaInsets.top) / 2

            ZStack {
                Color.black
                    .ignoresSafeArea()

                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: fullWidth, height: fullHeight)
                    .position(x: centerX, y: centerY)
                    .clipped()
            }
            .frame(width: fullWidth, height: fullHeight)
            .position(x: centerX, y: centerY)
        }
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
    }

    private var backgroundImage: Image {
        if let remoteImage = background.remoteImage {
            return Image(uiImage: remoteImage)
        }
        return Image(background.fallbackAssetName)
    }
}

struct DevotionalVerseStoryBackgroundSnapshot {
    let fallbackAssetName: String
    let remoteImage: UIImage?

    init(fallbackAssetName: String, remoteImage: UIImage? = nil) {
        self.fallbackAssetName = fallbackAssetName
        self.remoteImage = remoteImage
    }

    static func initial(for devotional: DailyDevotional) -> DevotionalVerseStoryBackgroundSnapshot {
        DevotionalVerseStoryBackgroundSnapshot(
            fallbackAssetName: DevotionalVerseStoryAssets.backgroundName(for: devotional.date)
        )
    }

    var usesRemoteImage: Bool { remoteImage != nil }
}

struct PresentedDevotionalStory: Identifiable {
    let id = UUID()
    let devotional: DailyDevotional
}

enum DevotionalStoryPresentationResolver {
    static func presentation(for devotional: DailyDevotional?, now: Date = Date()) -> PresentedDevotionalStory {
        PresentedDevotionalStory(devotional: devotional ?? DailyDevotional.fallback(for: now))
    }
}

protocol DevotionalVerseRemoteImageLoading {
    func loadImage(from url: URL) async -> UIImage?
}

enum DevotionalVerseStoryBackgroundResolver {
    static func resolve(
        devotional: DailyDevotional,
        fallbackAssetName: String,
        imageLoader: any DevotionalVerseRemoteImageLoading
    ) async -> DevotionalVerseStoryBackgroundSnapshot {
        guard let imageURL = devotional.imageURL,
              let image = await imageLoader.loadImage(from: imageURL)
        else {
            return DevotionalVerseStoryBackgroundSnapshot(fallbackAssetName: fallbackAssetName)
        }

        return DevotionalVerseStoryBackgroundSnapshot(
            fallbackAssetName: fallbackAssetName,
            remoteImage: image
        )
    }
}

final class DevotionalVerseRemoteImageLoader: DevotionalVerseRemoteImageLoading {
    static let shared = DevotionalVerseRemoteImageLoader()

    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadImage(from url: URL) async -> UIImage? {
        let cacheKey = url as NSURL
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        do {
            let (data, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                return nil
            }
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: cacheKey)
            return image
        } catch {
            return nil
        }
    }
}

enum DevotionalVerseStoryAssets {
    private static let story1Name = "SteadfastStory1"
    private static let story2Name = "SteadfastStory2"

    static func backgroundName(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return day.isMultiple(of: 2) ? story1Name : story2Name
    }
}

enum DevotionalVerseStoryRenderer {
    @MainActor
    static func renderImage(devotional: DailyDevotional, background: DevotionalVerseStoryBackgroundSnapshot) -> UIImage? {
        let view = DevotionalVerseStoryContent(
            devotional: devotional,
            background: background,
            logoSize: 112,
            showsChromeSafePadding: false
        )
        .frame(width: 1080, height: 1920)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage
    }
}

private struct DevotionalVerseShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    private let stepNumber: Int
    private let content: () -> Content

    init(stepNumber: Int, @ViewBuilder content: @escaping () -> Content) {
        self.stepNumber = stepNumber
        self.content = content
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RhythmStepNode(stepNumber: stepNumber)
                .frame(width: RhythmTimelineMetrics.columnWidth)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
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

private struct RhythmCTAButtonLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
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
    @State private var animateCompletion = false
    private let isComplete: Bool
    private let showsCompletionIndicator: Bool
    private let accessibilityLabel: String
    private let collapsedBody: () -> CollapsedContent
    private let expandedBody: () -> ExpandedContent

    init(
        isExpanded: Binding<Bool>,
        isComplete: Bool,
        showsCompletionIndicator: Bool = true,
        accessibilityLabel: String,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) {
        _isExpanded = isExpanded
        self.isComplete = isComplete
        self.showsCompletionIndicator = showsCompletionIndicator
        self.accessibilityLabel = accessibilityLabel
        collapsedBody = collapsedContent
        expandedBody = expandedContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
            HStack(alignment: .center, spacing: 12) {
                collapsedBody()
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showsCompletionIndicator {
                    completionIndicator
                }
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
        .onChange(of: isComplete) { completed in
            guard completed else { return }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
                animateCompletion = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.25)) {
                    animateCompletion = false
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
    }

    private var completionIndicator: some View {
        ZStack {
            if isComplete, animateCompletion {
                Circle()
                    .stroke(Theme.accent.opacity(0.28), lineWidth: 2)
                    .frame(width: 38, height: 38)
                    .scaleEffect(animateCompletion ? 1.08 : 0.72)
                    .opacity(animateCompletion ? 0 : 1)
            }

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
                    .scaleEffect(animateCompletion ? 1.12 : 1)
            }
        }
        .scaleEffect(animateCompletion ? 1.04 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Home tutorial overlay

enum HomeTutorialTarget: String, CaseIterable, Hashable {
    case streak
    case calmNow
    case dailyDevotional
    case dailyRhythm
    case meditations
    case explore
}

private struct HomeTutorialStep: Identifiable {
    let id: HomeTutorialTarget
    let title: String
    let description: String
}

private struct ResolvedHomeTutorialLayout {
    let stepIndex: Int
    let targetFrame: CGRect
}

private struct HomeTutorialTargetAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [HomeTutorialTarget: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [HomeTutorialTarget: Anchor<CGRect>],
        nextValue: () -> [HomeTutorialTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private extension View {
    func homeTutorialTarget(_ target: HomeTutorialTarget) -> some View {
        anchorPreference(
            key: HomeTutorialTargetAnchorPreferenceKey.self,
            value: .bounds
        ) { anchor in
            [target: anchor]
        }
    }
}

private struct HomeTutorialOverlay: View {
    let anchors: [HomeTutorialTarget: Anchor<CGRect>]
    let onScrollToTarget: (HomeTutorialTarget) -> Void
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var resolvedLayout: ResolvedHomeTutorialLayout?
    @State private var frames: [HomeTutorialTarget: CGRect] = [:]
    @State private var pendingStepIndex: Int?
    @State private var resolutionTask: Task<Void, Never>?
    @State private var calloutSize = CGSize(width: 340, height: 220)

    private let steps: [HomeTutorialStep] = [
        HomeTutorialStep(id: .streak, title: "Track your journey", description: "Keep an eye on your streak as you build a steady rhythm of mindfulness, scripture, and calm."),
        HomeTutorialStep(id: .calmNow, title: "Need calm right now?", description: "Tap here when you need quick relief from anxiety, a calming breath, or a peaceful reset."),
        HomeTutorialStep(id: .dailyDevotional, title: "Your daily devotional", description: "Start here for daily encouragement, scripture, reflection, and a simple path to grow in faith."),
        HomeTutorialStep(id: .dailyRhythm, title: "Find calm throughout your day", description: "Use Daily Rhythm to meet each part of your day with a moment of peace, prayer, and grounding."),
        HomeTutorialStep(id: .meditations, title: "Explore meditations", description: "Find guided meditations for different needs, emotions, and moments when you want to slow down."),
        HomeTutorialStep(id: .explore, title: "Explore more", description: "Use the menu to find verses, more meditations, settings, and other parts of your journey.")
    ]

    var body: some View {
        GeometryReader { proxy in
            let viewportFrames = anchors.mapValues { proxy[$0] }

            ZStack {
                if let layout = resolvedLayout {
                    let step = steps[layout.stepIndex]
                    let highlightFrame = layout.targetFrame.insetBy(dx: -8, dy: -8)

                    Color.black.opacity(0.48)
                        .ignoresSafeArea()
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .frame(width: highlightFrame.width, height: highlightFrame.height)
                                .position(x: highlightFrame.midX, y: highlightFrame.midY)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                        .allowsHitTesting(false)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.accent, lineWidth: 3)
                        .frame(width: highlightFrame.width, height: highlightFrame.height)
                        .shadow(color: Theme.accent.opacity(0.35), radius: 12)
                        .position(x: highlightFrame.midX, y: highlightFrame.midY)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)

                    tooltip(
                        for: step,
                        stepIndex: layout.stepIndex,
                        screenSize: proxy.size,
                        safeAreaInsets: proxy.safeAreaInsets,
                        highlightFrame: highlightFrame,
                        onBack: { requestStep(layout.stepIndex - 1, proxy: proxy) },
                        onNext: { requestStep(layout.stepIndex + 1, proxy: proxy) }
                    )
                } else {
                    Color.black.opacity(0.48)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onAppear {
                receiveFrames(viewportFrames, visibleSize: proxy.size)
            }
            .onChange(of: viewportFrames) { updatedFrames in
                receiveFrames(updatedFrames, visibleSize: proxy.size)
            }
            .onDisappear { cancelPendingResolution() }
        }
        .transition(.opacity)
        .zIndex(20)
    }

    private func receiveFrames(_ updatedFrames: [HomeTutorialTarget: CGRect], visibleSize: CGSize) {
        frames = updatedFrames

        if let pendingStepIndex {
            resolveStepIfPossible(
                pendingStepIndex,
                visibleSize: visibleSize,
                animated: true,
                allowPartialVisibility: true
            )
        } else if resolvedLayout == nil {
            resolveStepIfPossible(
                0,
                visibleSize: visibleSize,
                animated: false,
                allowPartialVisibility: false
            )
        } else {
            refreshResolvedFrameIfNeeded(visibleSize: visibleSize)
        }
    }

    private func frame(for target: HomeTutorialTarget) -> CGRect? {
        guard let frame = frames[target], isValid(frame) else { return nil }
        return frame
    }

    private func tooltip(
        for step: HomeTutorialStep,
        stepIndex: Int,
        screenSize: CGSize,
        safeAreaInsets: EdgeInsets,
        highlightFrame: CGRect,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) -> some View {
        let isLastStep = stepIndex == steps.count - 1
        let cardWidth = min(screenSize.width - 32, 340)
        let appearsBelow = highlightFrame.midY < screenSize.height * 0.56
        let halfHeight = calloutSize.height / 2
        let topBound = safeAreaInsets.top + halfHeight + 16
        let bottomBound = screenSize.height - safeAreaInsets.bottom - halfHeight - 16
        let yPosition = appearsBelow
            ? min(highlightFrame.maxY + halfHeight + 16, bottomBound)
            : max(highlightFrame.minY - halfHeight - 16, topBound)
        let xPosition = min(max(highlightFrame.midX, cardWidth / 2 + 16), screenSize.width - cardWidth / 2 - 16)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.cardTitle)
                Spacer()
                Text("\(stepIndex + 1)/\(steps.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }

            Text(step.description)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("Skip") {
                    completeTutorial()
                }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)

                Spacer()

                if stepIndex > 0 {
                    Button("Back", action: onBack)
                        .buttonStyle(HomeTutorialSecondaryButtonStyle())
                        .disabled(pendingStepIndex != nil)
                }

                Button(isLastStep ? "Done" : "Next") {
                    guard !isLastStep else {
                        completeTutorial()
                        return
                    }
                    onNext()
                }
                .buttonStyle(HomeTutorialPrimaryButtonStyle())
                .disabled(pendingStepIndex != nil)
            }
        }
        .padding(16)
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.line.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .onGeometryChange(for: CGSize.self, of: { $0.size }) { calloutSize = $0 }
        .position(x: xPosition, y: yPosition)
    }

    private func completeTutorial() {
        cancelPendingResolution()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { onComplete() }
    }

    private func requestStep(_ index: Int, proxy: GeometryProxy) {
        #if DEBUG
        let currentIndex = resolvedLayout?.stepIndex
        let requestedID = steps.indices.contains(index) ? steps[index].id.rawValue : "outOfBounds"
        print("[HomeTutorial] advance current=\(String(describing: currentIndex)) requested=\(index) target=\(requestedID) total=\(steps.count)")
        #endif

        guard steps.indices.contains(index), pendingStepIndex == nil else { return }

        pendingStepIndex = index
        let requestedTarget = steps[index].id

        if let targetFrame = frame(for: requestedTarget),
           isVisibleBeforeScroll(targetFrame, visibleSize: proxy.size) {
            logScrollDecision(for: requestedTarget, skippedScroll: true)
            commitResolvedStep(index, targetFrame: targetFrame, animated: true)
            return
        }

        logScrollDecision(for: requestedTarget, skippedScroll: false)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { onScrollToTarget(requestedTarget) }
        guard pendingStepIndex == index else { return }
        scheduleResolution(for: index, target: requestedTarget, visibleSize: proxy.size)
    }

    @discardableResult
    private func resolveStepIfPossible(
        _ index: Int,
        visibleSize: CGSize,
        animated: Bool,
        allowPartialVisibility: Bool
    ) -> Bool {
        guard steps.indices.contains(index) else {
            cancelPendingResolution()
            return false
        }

        if let pendingStepIndex, pendingStepIndex != index { return false }

        let requestedTarget = steps[index].id
        guard let targetFrame = frame(for: requestedTarget) else {
            logFrameResolution(
                for: requestedTarget,
                targetFrame: frames[requestedTarget],
                passedValidation: false
            )
            return false
        }

        let isVisible = allowPartialVisibility
            ? hasEnteredViewport(targetFrame, visibleSize: visibleSize)
            : isVisibleBeforeScroll(targetFrame, visibleSize: visibleSize)
        guard isVisible else { return false }

        commitResolvedStep(index, targetFrame: targetFrame, animated: animated)
        logFrameResolution(for: requestedTarget, targetFrame: targetFrame, passedValidation: true)
        return true
    }

    private func commitResolvedStep(_ stepIndex: Int, targetFrame: CGRect, animated: Bool) {
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.25)) {
                applyResolvedStep(stepIndex, targetFrame: targetFrame)
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                applyResolvedStep(stepIndex, targetFrame: targetFrame)
            }
        }
    }

    private func applyResolvedStep(_ stepIndex: Int, targetFrame: CGRect) {
        resolvedLayout = ResolvedHomeTutorialLayout(
            stepIndex: stepIndex,
            targetFrame: targetFrame
        )
        pendingStepIndex = nil
        resolutionTask?.cancel()
        resolutionTask = nil
    }

    private func isValid(_ frame: CGRect) -> Bool {
        frame.minX.isFinite && frame.minY.isFinite &&
            frame.width.isFinite && frame.height.isFinite &&
            frame.width > 1 && frame.height > 1
    }

    private func isVisibleBeforeScroll(_ frame: CGRect, visibleSize: CGSize) -> Bool {
        guard isValid(frame) else { return false }
        let visibleBounds = CGRect(origin: .zero, size: visibleSize)
        let intersection = visibleBounds.intersection(frame)
        return !intersection.isNull &&
            intersection.width > 1 &&
            intersection.height >= min(frame.height, 44)
    }

    private func hasEnteredViewport(_ frame: CGRect, visibleSize: CGSize) -> Bool {
        guard isValid(frame) else { return false }
        let intersection = CGRect(origin: .zero, size: visibleSize).intersection(frame)
        return !intersection.isNull && intersection.width > 1 && intersection.height > 1
    }

    private func scheduleResolution(for index: Int, target: HomeTutorialTarget, visibleSize: CGSize) {
        resolutionTask?.cancel()
        resolutionTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            if resolveStepIfPossible(
                index,
                visibleSize: visibleSize,
                animated: true,
                allowPartialVisibility: true
            ) { return }

            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            if resolveStepIfPossible(
                index,
                visibleSize: visibleSize,
                animated: true,
                allowPartialVisibility: true
            ) { return }

            guard pendingStepIndex == index else { return }
            pendingStepIndex = nil
            resolutionTask = nil
            #if DEBUG
            print("[HomeTutorial] unable to resolve target=\(target.rawValue); keeping committed step visible")
            #endif
        }
    }

    private func cancelPendingResolution() {
        resolutionTask?.cancel()
        resolutionTask = nil
        pendingStepIndex = nil
    }

    private func refreshResolvedFrameIfNeeded(visibleSize: CGSize) {
        guard let layout = resolvedLayout else { return }
        let resolvedTarget = steps[layout.stepIndex].id
        guard let targetFrame = frame(for: resolvedTarget),
              hasEnteredViewport(targetFrame, visibleSize: visibleSize),
              targetFrame != layout.targetFrame else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            resolvedLayout = ResolvedHomeTutorialLayout(
                stepIndex: layout.stepIndex,
                targetFrame: targetFrame
            )
        }
    }

    private func logFrameResolution(
        for target: HomeTutorialTarget,
        targetFrame: CGRect?,
        passedValidation: Bool
    ) {
        #if DEBUG
        print("[HomeTutorial] target=\(target.rawValue) frame=\(String(describing: targetFrame)) valid=\(passedValidation)")
        #endif
    }

    private func logScrollDecision(for target: HomeTutorialTarget, skippedScroll: Bool) {
        #if DEBUG
        print("[HomeTutorial] target=\(target.rawValue) skippedScroll=\(skippedScroll)")
        #endif
    }
}

private struct HomeTutorialPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(Theme.accent.opacity(configuration.isPressed ? 0.78 : 1)))
    }
}

private struct HomeTutorialSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.accent.opacity(configuration.isPressed ? 0.18 : 0.1)))
    }
}
