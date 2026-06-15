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
    @State private var showProfileSheet = false
    @State private var now = Date()
    @StateObject private var devotionalVM = DailyDevotionalViewModel()
    @State private var showDevotionalDetail = false
    @State private var showDevotionalVerseStory = false
    @State private var devotionalDeepLinkPending = false
    @State private var expandedRhythmCard: ExpandedRhythmCard?
    @State private var rhythmNodeCenters: [Int: CGFloat] = [:]
    @State private var didOpenDevotionalDetail = false
    @State private var previousDevotionalCompletion = false
    @State private var previousAnchorCompletion = false
    @State private var didInitializeCompletionState = false
    @State private var tutorialFrames: [HomeTutorialTarget: CGRect] = [:]

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

                // Profile icon on the right
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileMonogram(initial: vm.profileInitial)
                        .homeTutorialTarget(.profile)
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
            isPresented: $showDevotionalVerseStory,
            onDismiss: {
                completeDevotionalVerseCard(advanceToNext: true)
            }
        ) {
            if let devotional = devotionalVM.devotional {
                DevotionalVerseStoryView(devotional: devotional) {
                    showDevotionalVerseStory = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showDevotionalDetail = true
                    }
                }
            }
        }

        // Tick greeting + refresh anchors
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        .onChange(of: vm.pendingDeepLink) { dest in
            guard let dest = dest else { return }
            if dest == .anchor {
                showAnchorDurationPicker = true
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
                totalDuration: selectedAnchorDuration?.seconds ?? MeditationDurationOption.default.seconds,
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
                    .homeTutorialTarget(.streak)
                    .id(HomeTutorialTarget.streak)
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 4)

                // Big SOS button
                SOSButton { vm.showSOS = true }
                    .homeTutorialTarget(.calmNow)
                    .id(HomeTutorialTarget.calmNow)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                rhythmHeader
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 8)

                rhythmCardsSection
                    .homeTutorialTarget(.devotional)
                    .id(HomeTutorialTarget.devotional)
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
            .onPreferenceChange(HomeTutorialTargetFramePreferenceKey.self) { tutorialFrames = $0 }
            .overlay {
                if hasCompletedOnboarding && !hasSeenHomeTutorial && topTab == .home {
                    HomeTutorialOverlay(frames: tutorialFrames, onScrollToTarget: { target in
                        withAnimation(.easeInOut(duration: 0.28)) {
                            scrollProxy.scrollTo(target, anchor: target == .meditations ? .center : .top)
                        }
                    }, onComplete: {
                        hasSeenHomeTutorial = true
                    })
                }
            }
        }
        .task {
            devotionalVM.loadDevotionalIfNeeded()
        }
        .onAppear {
            vm.syncProfileNameFromDefaults()
            print("🏠 Home screen reached; triggering devotional fetch")
            devotionalVM.refresh()
            syncCompletionBaselines()
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
                        showDevotionalVerseStory = true
                    } label: {
                        RhythmCTAButtonLabel("Open verse story")
                    }
                    .padding(.top, 4)
                } else {
                    Text("Today’s devotional verse is not available yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
    let onContinueToDevotional: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var savedStore: SavedDevotionalsStore
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSavedConfirmation = false

    private var backgroundName: String {
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
                    backgroundName: backgroundName,
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
            .ignoresSafeArea()
        }
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                DevotionalVerseShareSheet(activityItems: [shareImage])
            }
        }
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
        onContinueToDevotional()
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
        shareImage = DevotionalVerseStoryRenderer.renderImage(
            devotional: devotional,
            backgroundName: backgroundName
        )
        showShareSheet = shareImage != nil
    }
}

private struct DevotionalVerseStoryContent: View {
    let devotional: DailyDevotional
    let backgroundName: String
    var logoSize: CGFloat
    var showsChromeSafePadding: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            DevotionalVerseStoryBackground(imageName: backgroundName)

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
    let imageName: String

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

                Image(imageName)
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
}

private enum DevotionalVerseStoryAssets {
    private static let story1Name = "SteadfastStory1"
    private static let story2Name = "SteadfastStory2"

    static func backgroundName(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return day.isMultiple(of: 2) ? story1Name : story2Name
    }
}

private enum DevotionalVerseStoryRenderer {
    @MainActor
    static func renderImage(devotional: DailyDevotional, backgroundName: String) -> UIImage? {
        let view = DevotionalVerseStoryContent(
            devotional: devotional,
            backgroundName: backgroundName,
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
    case profile
    case streak
    case calmNow
    case devotional
    case dailyRhythm
    case meditations
    case bottomNavigation
}

private struct HomeTutorialStep: Identifiable {
    let id: HomeTutorialTarget
    let title: String
    let description: String
}

private struct HomeTutorialTargetFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HomeTutorialTarget: CGRect] = [:]

    static func reduce(value: inout [HomeTutorialTarget: CGRect], nextValue: () -> [HomeTutorialTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private extension View {
    func homeTutorialTarget(_ target: HomeTutorialTarget) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: HomeTutorialTargetFramePreferenceKey.self,
                    value: [target: proxy.frame(in: .global)]
                )
            }
        )
    }
}

private struct HomeTutorialOverlay: View {
    let frames: [HomeTutorialTarget: CGRect]
    let onScrollToTarget: (HomeTutorialTarget) -> Void
    let onComplete: () -> Void

    @State private var stepIndex = 0

    private let steps: [HomeTutorialStep] = [
        HomeTutorialStep(id: .profile, title: "Your profile", description: "Update your profile information, preferences, and account details here."),
        HomeTutorialStep(id: .streak, title: "Track your journey", description: "Keep an eye on your streak as you build a steady rhythm of mindfulness, scripture, and calm."),
        HomeTutorialStep(id: .calmNow, title: "Need calm right now?", description: "Tap here when you need quick relief from anxiety, a calming breath, or a peaceful reset."),
        HomeTutorialStep(id: .devotional, title: "Your daily devotional", description: "Start here for daily encouragement, scripture, reflection, and a simple path to grow in faith."),
        HomeTutorialStep(id: .dailyRhythm, title: "Find calm throughout your day", description: "Use Daily Rhythm to meet each part of your day with a moment of peace, prayer, and grounding."),
        HomeTutorialStep(id: .meditations, title: "Explore meditations", description: "Find guided meditations for different needs, emotions, and moments when you want to slow down."),
        HomeTutorialStep(id: .bottomNavigation, title: "Explore more", description: "Use the menu to find verses, more meditations, settings, and other parts of your journey.")
    ]

    var body: some View {
        GeometryReader { proxy in
            let step = steps[stepIndex]
            let targetFrame = frame(for: step.id, in: proxy)
            let highlightFrame = targetFrame.insetBy(dx: -8, dy: -8)

            ZStack {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .frame(width: highlightFrame.width, height: highlightFrame.height)
                            .position(x: highlightFrame.midX, y: highlightFrame.midY)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.accent, lineWidth: 3)
                    .frame(width: highlightFrame.width, height: highlightFrame.height)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 12)
                    .position(x: highlightFrame.midX, y: highlightFrame.midY)
                    .accessibilityHidden(true)

                tooltip(for: step, screenSize: proxy.size, highlightFrame: highlightFrame)
            }
            .contentShape(Rectangle())
            .onAppear { prepareCurrentStep() }
            .onChange(of: stepIndex) { _ in prepareCurrentStep() }
        }
        .transition(.opacity)
        .zIndex(20)
    }

    private func frame(for target: HomeTutorialTarget, in proxy: GeometryProxy) -> CGRect {
        if target == .bottomNavigation {
            let bottomInset = max(proxy.safeAreaInsets.bottom, 8)
            return CGRect(x: 8, y: proxy.size.height - bottomInset - 62, width: proxy.size.width - 16, height: 58)
        }

        if let frame = frames[target], frame.width > 1, frame.height > 1 {
            return frame
        }

        return CGRect(x: proxy.size.width - 64, y: max(proxy.safeAreaInsets.top, 12) + 8, width: 44, height: 44)
    }

    private func tooltip(for step: HomeTutorialStep, screenSize: CGSize, highlightFrame: CGRect) -> some View {
        let cardWidth = min(screenSize.width - 32, 340)
        let appearsBelow = highlightFrame.midY < screenSize.height * 0.56
        let yPosition = appearsBelow
            ? min(highlightFrame.maxY + 112, screenSize.height - 126)
            : max(highlightFrame.minY - 112, 126)
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
                Button("Skip", action: onComplete)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)

                Spacer()

                if stepIndex > 0 {
                    Button("Back") { stepIndex -= 1 }
                        .buttonStyle(HomeTutorialSecondaryButtonStyle())
                }

                Button(stepIndex == steps.count - 1 ? "Done" : "Next") {
                    if stepIndex == steps.count - 1 {
                        onComplete()
                    } else {
                        stepIndex += 1
                    }
                }
                .buttonStyle(HomeTutorialPrimaryButtonStyle())
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
        .position(x: xPosition, y: yPosition)
    }

    private func prepareCurrentStep() {
        let target = steps[stepIndex].id
        guard target != .profile, target != .bottomNavigation else { return }
        onScrollToTarget(target)
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
