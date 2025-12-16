//  OnboardingFlowView.swift
//  Steadfast
//
//  Created by Asha Redmon on 10/28/25.
//

import SwiftUI
import UserNotifications

struct OnboardingFlowView: View {
    enum Page: Int, CaseIterable {
        case intro1, intro2, intro3, nameConsent, welcomeUser, morningReminder, widgetReminder, quickPractice, done
    }

    @State private var page: Page = .intro1
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Morning reminder state
    @State private var enableMorningReminder: Bool = false
    @State private var morningReminderTime: Date = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()
    ) ?? Date()

    private let defaultVerse = Verse(
        ref: "Philippians 4:13",
        breathIn: "I can do all things through Christ",
        breathOut: "who strengthens me."
    ) // uses default 4/6s


    var body: some View {
        OnboardingBackground(imageName: "OnboardingBG", darken: 0.28) {
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                TabView(selection: $page) {
                    OnboardSlideBranded(
                        title: "Welcome to Steadfast",
                        subtitle: "A calm, Bible-centered companion.\nFind peace in God’s Word, anytime.",
                        icon: "icon"
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
                        enable: $enableMorningReminder,
                        time: $morningReminderTime
                    )
                    .tag(Page.morningReminder)

                    // 🆕 Widget reminder slide
                    WidgetReminderSlide(
                        imageName: "widget-preview", // 👈 put your image asset name here
                        onSkip: { goForward() }
                    )
                    .tag(Page.widgetReminder)

                    QuickPracticeSlideBranded(verse: defaultVerse, onCompleted: {
                        if let next = Page(rawValue: Page.quickPractice.rawValue + 1) {
                            page = next
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

                if page != .done {
                    HStack {
                        if page != .intro1 {
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
                    .padding(.bottom, 24)
                }
            }
            .foregroundStyle(.white)
            .navigationBarHidden(true)
            .onChange(of: page) { newPage in
                if newPage == .morningReminder {
                    let ud = UserDefaults.standard
                    if let ts = ud.object(forKey: "notif_morning_time") as? TimeInterval {
                        morningReminderTime = Date(timeIntervalSince1970: ts)
                    }
                    if let en = ud.object(forKey: "notif_morning_enabled") as? Bool {
                        enableMorningReminder = en
                    }
                }
            }
        }
    }

    private var nextLabel: String {
        switch page {
        case .intro1, .intro2: return "Next"
        case .intro3:          return "Continue"
        case .nameConsent:     return "Next"
        case .welcomeUser:     return "Continue"
        case .morningReminder: return enableMorningReminder ? "Enable & Continue" : "Skip"
        case .widgetReminder:  return "Continue"
        case .quickPractice:   return "Skip"
        case .done:            return "Enter Steadfast"
        }
    }

    private var nextDisabled: Bool {
        if page == .nameConsent {
            return displayName.trimmed().isEmpty || !hasAcceptedTerms
        }
        return false
    }

    private func goBack() {
        if let prev = Page(rawValue: page.rawValue - 1) { page = prev }
    }

    private func goForward() {
        if page == .morningReminder { commitMorningReminder() }
        if let next = Page(rawValue: page.rawValue + 1), page != .done { page = next }
    }

    private func commitMorningReminder() {
        let ud = UserDefaults.standard
        // In OnboardingFlowView.swift, inside commitMorningReminder()

        if enableMorningReminder {
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
}

// MARK: - Widget Reminder Slide
private struct WidgetReminderSlide: View {
    let imageName: String
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Add Steadfast to your Home Screen")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Keep your daily anchor within sight.\nLong-press your Home Screen, tap the ➕ button, and search for “Steadfast”.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
                .padding(.vertical, 8)

            Button {
                onSkip()
            } label: {
                Label("Skip for now", systemImage: "arrow.right")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.8))
            .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Morning Reminder Slide
struct MorningReminderSlide: View {
    @Binding var enable: Bool
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Set a Morning Reminder?")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("We can nudge you once each morning to pause for a verse and a calming breath.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Toggle(isOn: $enable) {
                    Text("Enable Morning Reminder")
                        .font(.headline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .white))
                .padding(.top, 6)

                HStack {
                    Text("Time")
                    Spacer()
                    DatePicker("",
                               selection: $time,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .disabled(!enable)
                        .opacity(enable ? 1 : 0.6)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 1))
            }
            .padding(.horizontal)

            Text(enable ? "We’ll send one reminder at the time you choose."
                        : "You can always turn this on later in Settings.")
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.top, 4)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }
}


private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
