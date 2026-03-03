//  OnboardingFlowView.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

import SwiftUI
import UserNotifications

// MARK: - Widget Reminder Slide
fileprivate struct WidgetReminderSlide: View {
    let imageName: String
    var onSkip: () -> Void

    var body: some View {
        GlassCard(maxWidth: .infinity) {
            VStack(spacing: 16) {
                Text("Add Steadfast to your Home Screen")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)

                Text("Keep your daily anchor within sight.\nLong-press your Home Screen, tap the ➕ button, and search for “Steadfast”.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Image(self.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
                    .padding(.vertical, 8)

                Button {
                    self.onSkip()
                } label: {
                    Label("Skip for now", systemImage: "arrow.right")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Begin Meditation Slide
fileprivate struct BeginMeditationSlide: View {
    var onBegin: () -> Void
    var onSkip: () -> Void

    var body: some View {
        GlassCard(maxWidth: .infinity) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onSkip()
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(Theme.accent)
                }

                Text("Begin Your First Meditation")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)

                Text("Take a quiet moment to settle in. We’ll guide you with Scripture and breath.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button("Begin") {
                    onBegin()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
    }
}

struct OnboardingFlowView: View {
    enum Page: Int, CaseIterable {
        case intro1, intro2, intro3, nameConsent, welcomeUser, morningReminder, widgetReminder, beginMeditation, quickPractice, done
    }

    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("didCompleteOnboardingMeditation") private var didCompleteOnboardingMeditation = false

    private let defaultVerse = Verse(
        ref: "Philippians 4:13",
        breathIn: "I can do all things through Christ",
        breathOut: "who strengthens me."
    ) // uses default 4/6s


    var body: some View {
        OnboardingBackground(imageName: "OnboardingBG", darken: 0.28) {
            GeometryReader { proxy in
                VStack(spacing: 18) {
                    Spacer(minLength: 0)

                    TabView(selection: $viewModel.page) {
                        OnboardSlideBranded(
                            title: "Welcome to Steadfast",
                            subtitle: "A calm, Bible-centered companion.\nFind peace in God’s Word, anytime.",
                            icon: "icon",
                            iconShape: .roundedSquare
                        ).tag(Page.intro1)

                        OnboardSlideBranded(
                            title: "Meditations & Scripture",
                            subtitle: "Explore short, guided practices with verses to steady heart and mind.",
                            icon: "icon"
                        ).tag(Page.intro2)

                        OnboardSlideBranded(
                            title: "Breathing Exercises",
                            subtitle: "Gentle breathing patterns with scripture to settle your nervous system and calm anxiety.",
                            icon: "icon"
                        ).tag(Page.intro3)

                        NameConsentSlideBranded(
                            displayName: $displayName,
                            hasAcceptedTerms: $hasAcceptedTerms
                        ).tag(Page.nameConsent)

                        WelcomeUserSlide()
                            .tag(Page.welcomeUser)

                        MorningReminderSlide(
                            enable: $viewModel.enableMorningReminder,
                            time: $viewModel.morningReminderTime
                        )
                        .tag(Page.morningReminder)

                        WidgetReminderSlide(
                            imageName: "widget-preview",
                            onSkip: { goForward() }
                        )
                        .tag(Page.widgetReminder)

                        BeginMeditationSlide(
                            onBegin: { viewModel.showBeginMeditation = true },
                            onSkip: { finishIntroMeditationStep() }
                        )
                        .tag(Page.beginMeditation)

                        QuickPracticeSlideBranded(verse: defaultVerse, onCompleted: {
                            if let next = Page(rawValue: Page.quickPractice.rawValue + 1) {
                                viewModel.page = next
                            }
                        })
                        .tag(Page.quickPractice)

                        DoneSlideBranded {
                            hasCompletedOnboarding = true
                        }
                        .tag(Page.done)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .frame(maxWidth: .infinity, maxHeight: proxy.size.height * 0.88)

                    if viewModel.page != .done {
                        HStack(spacing: 12) {
                            if viewModel.page != .intro1 {
                                Button("Back") { goBack() }
                                    .buttonStyle(SubtleButtonStyle())
                            }
                            Spacer()
                            Button(nextLabel) { goForward() }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(nextDisabled)
                                .opacity(nextDisabled ? 0.6 : 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16))
                    }
                }
                .padding(.top, max(proxy.safeAreaInsets.top, 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $viewModel.showBeginMeditation) {
            NavigationStack {
                AnchorBreathView(
                    verse: defaultVerse,
                    totalDuration: 60,
                    inhaleSecs: 4,
                    holdSecs: 4,
                    exhaleSecs: 6,
                    showBibleLink: false,
                    launchSource: .onboarding,
                    onCompleted: {
                        finishIntroMeditationStep()
                    },
                    showInlineMuteButton: true,
                    startMuted: false
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var nextLabel: String {
        switch viewModel.page {
        case .intro1, .intro2: return "Next"
        case .intro3:          return "Continue"
        case .nameConsent:     return "Next"
        case .welcomeUser:     return "Continue"
        case .morningReminder: return viewModel.enableMorningReminder ? "Enable & Continue" : "Skip"
        case .widgetReminder:  return "Continue"
        case .beginMeditation: return didCompleteOnboardingMeditation ? "Continue" : "Begin"
        case .quickPractice:   return "Skip"
        case .done:            return "Enter Steadfast"
        }
    }

    private var nextDisabled: Bool {
        if viewModel.page == .nameConsent {
            return displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasAcceptedTerms
        }
        return false
    }

    private func goBack() {
        if let prev = Page(rawValue: viewModel.page.rawValue - 1) { viewModel.page = prev }
    }

    private func goForward() {
        if viewModel.page == .nameConsent {
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let persistedName = trimmedName.isEmpty ? "Friend" : trimmedName
            displayName = persistedName
            appViewModel.profileFirstName = persistedName
        }
        if viewModel.page == .morningReminder { viewModel.commitMorningReminder() }
        if viewModel.page == .beginMeditation {
            if didCompleteOnboardingMeditation {
                advance(from: .beginMeditation)
            } else {
                viewModel.showBeginMeditation = true
            }
            return
        }
        if viewModel.page == .quickPractice {
            advance(from: .quickPractice)
            return
        }
        advance(from: viewModel.page)
    }

    private func finishIntroMeditationStep() {
        didCompleteOnboardingMeditation = true
        viewModel.showBeginMeditation = false
        if viewModel.page == .beginMeditation {
            advance(from: .beginMeditation)
        }
    }

    private func advance(from page: Page) {
        if let next = Page(rawValue: page.rawValue + 1), page != .done {
            viewModel.page = next
        }
    }
}

// MARK: - Morning Reminder Slide
struct MorningReminderSlide: View {
    @Binding var enable: Bool
    @Binding var time: Date
    @State private var showTimePicker = false

    var body: some View {
        GlassCard(maxWidth: .infinity) {
            VStack(spacing: 18) {
                Text("Set a Morning Reminder?")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)

                Text("We can nudge you once each morning to pause for a verse and a calming breath.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                VStack(spacing: 12) {
                    Toggle(isOn: $enable) {
                        Text("Enable Morning Reminder")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .tint(Theme.accent)
                    .padding(.top, 6)

                    Button {
                        showTimePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Morning time")
                                    .font(.subheadline.weight(.semibold))
                                Text(time.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                                    .foregroundStyle(enable ? .primary : .secondary)
                            }
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundColor(enable ? Theme.accent : Theme.line)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line.opacity(0.45)))
                    }
                    .disabled(!enable)
                    .opacity(enable ? 1 : 0.55)
                }

                Text(enable ? "We’ll send one reminder at the time you choose."
                            : "You can always turn this on later in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
        .sheet(isPresented: $showTimePicker) {
            reminderPickerSheet
        }
        .accessibilityElement(children: .contain)
    }

    private var reminderPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                DatePicker(
                    "Morning Time",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 8)

                Text("Pick a time that best fits your routine.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
            .presentationDetents([.fraction(0.35), .medium])
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showTimePicker = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Onboarding View Model
final class OnboardingViewModel: ObservableObject {
    @Published var page: OnboardingFlowView.Page = .intro1
    @Published var enableMorningReminder: Bool
    @Published var morningReminderTime: Date
    @Published var showBeginMeditation = false

    init() {
        let defaultTime = Calendar.current.date(
            bySettingHour: 8, minute: 0, second: 0, of: Date()
        ) ?? Date()

        let ud = UserDefaults.standard
        if let ts = ud.object(forKey: "notif_morning_time") as? TimeInterval {
            morningReminderTime = Date(timeIntervalSince1970: ts)
        } else {
            morningReminderTime = defaultTime
        }
        enableMorningReminder = ud.object(forKey: "notif_morning_enabled") as? Bool ?? false
    }

    func commitMorningReminder() {
        guard enableMorningReminder else { return }
        let ud = UserDefaults.standard
        ud.set(true, forKey: "notif_enabled")
        ud.set(true, forKey: "notif_morning_enabled")
        ud.set(morningReminderTime.timeIntervalSince1970, forKey: "notif_morning_time")

        // ✅ Seed midday/evening if not set yet
        if ud.object(forKey: "notif_midday_time") == nil {
            ud.set(AppViewModel.makeTime(13, 0).timeIntervalSince1970, forKey: "notif_midday_time")
        }
        if ud.object(forKey: "notif_evening_time") == nil {
            ud.set(AppViewModel.makeTime(21, 0).timeIntervalSince1970, forKey: "notif_evening_time")
        }
        if ud.object(forKey: "notif_midday_enabled") == nil { ud.set(true, forKey: "notif_midday_enabled") }
        if ud.object(forKey: "notif_evening_enabled") == nil { ud.set(true, forKey: "notif_evening_enabled") }

        ud.synchronize()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    NotificationManager.shared.requestAndScheduleDailyCheckins()
                    NotificationManager.shared.scheduleDailyFromSettings()
                } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    NotificationManager.shared.scheduleDailyFromSettings()
                } // else .denied → no-op or open settings
            }
        }
    }
}
