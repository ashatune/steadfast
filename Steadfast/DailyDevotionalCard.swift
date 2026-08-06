import SwiftUI

struct DailyDevotionalCard: View {
    let devotional: DailyDevotional?
    let isLoading: Bool

    private let cornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topLeading) {
            baseFallbackImage
            remoteImageOverlay
            gradientOverlay
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.line)
        )
        .shadow(color: Theme.line.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isLoading {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Loading today’s devotional…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let devotional {
                Text(devotional.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(devotional.verseReference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(devotional.previewSnippet)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)

                Text(ctaText(for: devotional))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 2)
            } else {
                Text("No devotional available for today.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ctaText(for devotional: DailyDevotional) -> String {
        if let cta = devotional.cta?.trimmingCharacters(in: .whitespacesAndNewlines), !cta.isEmpty {
            return cta
        }
        return "Tap to read today’s devotional"
    }

    @ViewBuilder
    private var remoteImageOverlay: some View {
        if let imageURL = devotional?.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure(_):
                    EmptyView() // fallback still visible underneath
                case .empty:
                    EmptyView() // fallback still visible underneath
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            EmptyView()
        }
    }

    private var baseFallbackImage: some View {
        Image("DefaultDevotionalImage")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.05),
                .black.opacity(0.35),
                .black.opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DailyDevotionalDetailView: View {
    let devotional: DailyDevotional
    @EnvironmentObject private var savedStore: SavedDevotionalsStore
    @EnvironmentObject private var streakManager: StreakManager
    @Environment(\.dismiss) private var dismiss
    @State private var showMeditation = false
    @State private var showReturnTomorrow = false
    @State private var showAnchorFromPrompt = false
    @State private var showMeditationDurationPicker = false
    @State private var showAnchorPromptDurationPicker = false
    @State private var selectedMeditationDuration: MeditationDurationOption?
    @State private var selectedAnchorPromptDuration: MeditationDurationOption?

    private var anchorOfDay: Verse {
        DailyVerseProvider.shared.verse(for: Date(), calendar: Calendar.current)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(devotional.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.cardTitle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(devotional.verseReference)
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                    Text(devotional.verseText)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                }

                Divider()

                Text(devotional.body)
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .lineSpacing(7)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    Button("Meditate on this verse") {
                        showMeditationDurationPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Done") {
                        streakManager.markDevotionalCompleted()
                        StreakNotificationManager.shared.reevaluateReminder(streakManager: streakManager)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReturnTomorrow = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Daily Devotional")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showReturnTomorrow)
        .analyticsScreen("daily_devotional", screenClass: "DailyDevotionalDetailView")
        .onAppear {
            AnalyticsService.log("devotional_opened", parameters: ["content_id": devotional.id])
        }
        .toolbar {
            if !showReturnTomorrow {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let wasSaved = savedStore.isSaved(devotionalID: devotional.id)
                        savedStore.toggleSave(devotional: devotional)
                        if !wasSaved {
                            AnalyticsService.log("devotional_saved", parameters: ["content_id": devotional.id])
                        }
                    } label: {
                        Image(systemName: savedStore.isSaved(devotionalID: devotional.id) ? "bookmark.fill" : "bookmark")
                            .font(.headline)
                    }
                    .accessibilityLabel(savedStore.isSaved(devotionalID: devotional.id) ? "Remove bookmark" : "Save devotional")
                }
            }
        }
        .sheet(isPresented: $showMeditationDurationPicker) {
            MeditationDurationPickerSheet(
                title: "Meditate on this verse",
                prompt: "How long would you like to breathe with this devotional verse?",
                selectedDuration: selectedMeditationDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedMeditationDuration = duration
                showMeditationDurationPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showMeditation = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAnchorPromptDurationPicker) {
            MeditationDurationPickerSheet(
                title: "Anchor of the Day",
                prompt: "How long would you like to breathe with today’s verse?",
                selectedDuration: selectedAnchorPromptDuration ?? MeditationDurationOption.default
            ) { duration in
                selectedAnchorPromptDuration = duration
                showAnchorPromptDurationPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showAnchorFromPrompt = true
                }
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
        .background(
            Group {
                NavigationLink(
                    "",
                    isActive: $showMeditation,
                    destination: {
                        AnchorBreathView(
                            verse: Verse(ref: devotional.verseReference, text: devotional.verseText),
                            totalDuration: selectedMeditationDuration?.seconds ?? MeditationDurationOption.default.seconds,
                            inhaleSecs: 4,
                            holdSecs: 4,
                            exhaleSecs: 6
                        )
                    }
                )
                .hidden()

                NavigationLink("", isActive: $showAnchorFromPrompt) {
                    AnchorBreathView(
                        verse: anchorOfDay,
                        totalDuration: selectedAnchorPromptDuration?.seconds ?? MeditationDurationOption.default.seconds,
                        inhaleSecs: 4,
                        holdSecs: 4,
                        exhaleSecs: 6
                    )
                }
                .hidden()
            }
        )
        .overlay {
            if showReturnTomorrow {
                if let milestone = streakManager.pendingMilestone {
                    StreakMilestoneCelebrationView(milestone: milestone) {
                        streakManager.clearPendingMilestone()
                        dismiss()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    ReturnTomorrowView(
                        onDone: {
                            dismiss()
                        },
                        secondaryPrompt: "Ready for your next step?",
                        secondaryButtonTitle: "Continue to Anchor",
                        onSecondaryAction: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showReturnTomorrow = false
                            }
                            showAnchorPromptDurationPicker = true
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}
