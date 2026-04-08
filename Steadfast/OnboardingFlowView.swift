//  OnboardingFlowView.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

import SwiftUI
import UserNotifications
import UIKit

fileprivate struct WidgetReminderSlide: View {
    let imageName: String
    var onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 20)

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

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct BeginMeditationSlide: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                Text("Begin Your First Meditation")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)

                Text("Take a quiet moment to settle in. We’ll guide you with Scripture and breath.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


fileprivate struct AppleWatchOnboardingSlide: View {
    private var usesAppleWatchSymbol: Bool {
        UIImage(systemName: "applewatch") != nil
    }

    private var symbolName: String {
        usesAppleWatchSymbol ? "applewatch" : "applelogo"
    }

    private var symbolSize: CGFloat {
        usesAppleWatchSymbol ? 60 : 34
    }

    private var symbolColor: Color {
        usesAppleWatchSymbol ? .secondary : .primary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 88, height: 88)

                    Image(systemName: symbolName)
                        .font(.system(size: symbolSize))
                        .foregroundStyle(symbolColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 14)

                Text("Take Steadfast with you")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)

                Text("Steadfast is also available on Apple Watch, so you can stay grounded wherever you are.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Set it up in a minute")
                        .font(.headline)

                    Text("1. Open the Watch app on your iPhone")
                    Text("2. Scroll to Available Apps")
                    Text("3. Find Steadfast and tap Install")
                    Text("4. Open Steadfast on your Apple Watch")
                }
                .frame(maxWidth: 360, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                Text("Once it’s installed, you can access Steadfast right from your wrist.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct OnboardingFlowView: View {
    enum Page: Int, CaseIterable {
        case intro1, intro2, intro3, nameConsent, welcomeUser, morningReminder, widgetReminder, appleWatchInfo, beginMeditation, quickPractice, done
    }

    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("didCompleteOnboardingMeditation") private var didCompleteOnboardingMeditation = false
    @State private var shouldSkipMeditation = false

    private let defaultVerse = Verse(
        ref: "Philippians 4:13",
        breathIn: "I can do all things through Christ",
        breathOut: "who strengthens me."
    )

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
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
                        hasAcceptedTerms: $hasAcceptedTerms,
                        onContinue: { goForward() }
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

                    AppleWatchOnboardingSlide()
                        .tag(Page.appleWatchInfo)

                    BeginMeditationSlide()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if viewModel.page != .done && viewModel.page != .nameConsent {
                    onboardingControls
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 18))
                }
            }
            .padding(.top, max(proxy.safeAreaInsets.top, 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemBackground).ignoresSafeArea())
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
                    shouldSkipOnAppear: shouldSkipMeditation,
                    onSkip: {
                        skipMeditationAndAdvance()
                    },
                    onCompleted: {
                        finishIntroMeditationStep()
                    },
                    showInlineMuteButton: true,
                    startMuted: false
                )
            }
        }
    }

    private var onboardingControls: some View {
        VStack(spacing: 10) {
            Button(nextLabel) { goForward() }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .disabled(nextDisabled)
                .opacity(nextDisabled ? 0.6 : 1)

            if viewModel.page != .intro1 {
                Button("Back") { goBack() }
                    .buttonStyle(OnboardingSecondaryButtonStyle())
            }

            if viewModel.page == .beginMeditation && !didCompleteOnboardingMeditation {
                Button("Skip") { skipMeditationAndAdvance() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
    }

    private var nextLabel: String {
        switch viewModel.page {
        case .intro1, .intro2: return "Next"
        case .intro3:          return "Continue"
        case .nameConsent:     return "Next"
        case .welcomeUser:     return "Continue"
        case .morningReminder: return viewModel.enableMorningReminder ? "Enable & Continue" : "Skip"
        case .widgetReminder:  return "Continue"
        case .appleWatchInfo:  return "Continue"
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
            if didCompleteOnboardingMeditation || shouldSkipMeditation {
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

    private func skipMeditationAndAdvance() {
        shouldSkipMeditation = true
        finishIntroMeditationStep()
    }

    private func advance(from page: Page) {
        if let next = Page(rawValue: page.rawValue + 1), page != .done {
            viewModel.page = next
        }
    }
}

struct MorningReminderSlide: View {
    @Binding var enable: Bool
    @Binding var time: Date
    @State private var showTimePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 20)

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

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
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

        if ud.object(forKey: "notif_midday_time") == nil {
            ud.set(AppViewModel.makeTime(13, 0).timeIntervalSince1970, forKey: "notif_midday_time")
        }
        if ud.object(forKey: "notif_evening_time") == nil {
            ud.set(AppViewModel.makeTime(21, 0).timeIntervalSince1970, forKey: "notif_evening_time")
        }

        ud.synchronize()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    NotificationManager.shared.requestAndScheduleDailyCheckins()
                    NotificationManager.shared.scheduleDailyFromSettings()
                } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    NotificationManager.shared.scheduleDailyFromSettings()
                }
            }
        }
    }
}

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
