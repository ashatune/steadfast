import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingDeniedAlert = false

    // Onboarding controls
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = true
    @AppStorage("displayName") private var displayName = ""
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                // Notifications
                Section {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        statusBadge
                    }

                    Toggle("Enable daily reminders", isOn: $vm.notifEnabled)
                        .onChange(of: vm.notifEnabled) { _ in apply() }

                    // Morning
                    HStack {
                        Toggle("Morning", isOn: $vm.morningEnabled)
                        Spacer()
                        DatePicker("", selection: $vm.morningTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .disabled(!vm.notifEnabled || !vm.morningEnabled)
                            .onChange(of: vm.morningTime) { _ in apply() }
                    }
                    // Midday
                    HStack {
                        Toggle("Midday", isOn: $vm.middayEnabled)
                        Spacer()
                        DatePicker("", selection: $vm.middayTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .disabled(!vm.notifEnabled || !vm.middayEnabled)
                            .onChange(of: vm.middayTime) { _ in apply() }
                    }
                    // Evening
                    HStack {
                        Toggle("Evening", isOn: $vm.eveningEnabled)
                        Spacer()
                        DatePicker("", selection: $vm.eveningTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .disabled(!vm.notifEnabled || !vm.eveningEnabled)
                            .onChange(of: vm.eveningTime) { _ in apply() }
                    }

                    Button {
                        requestAndApply()
                    } label: {
                        Label("Save & Schedule", systemImage: "bell.badge")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                /*Button {
                    scheduleTest(in: 10) // fires once in ~10s even in foreground (banner shows due to delegate)
                } label: {
                    Label("Schedule test in 10s", systemImage: "alarm")
                }
                .buttonStyle(.bordered)*/


                // Voice guidance (TTS)
                Section {
                    Toggle("Enable text-to-speech guidance", isOn: $vm.voiceGuidanceEnabled)
                        .onChange(of: vm.voiceGuidanceEnabled) { on in
                            TTSManager.shared.enabled = on
                        }

                    Button {
                        TTSManager.shared.speak(
                            "This is Steadfast voice guidance. You can turn me off any time in Settings.",
                            rate: 0.46, pitch: 1.0
                        )
                    } label: {
                        Label("Play sample", systemImage: "speaker.wave.2.fill")
                    }
                    .disabled(!vm.voiceGuidanceEnabled)
                } header: {
                    Text("Voice guidance")
                }

                // Onboarding controls (cleaned up)
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your first name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 220)
                    }

                    Button {
                        confirmReset = true
                    } label: {
                        Label("Re-run Onboarding", systemImage: "arrow.counterclockwise")
                    }
                    .tint(.orange)
                    .buttonStyle(.bordered)
                } header: {
                    Text("Onboarding")
                } footer: {
                    Text("Re-running onboarding will show the intro slides and 30-second practice again on next open.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }

                // System settings
                Section {
                    Button {
                        NotificationManager.shared.openSystemSettings()
                    } label: {
                        Label("Open iOS Notification Settings", systemImage: "gearshape")
                    }
                } footer: {
                    Text("If notifications are Off or set to Deliver Quietly in iOS Settings, reminders may not appear.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSecondary)
                }
                // About & Contact
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Steadfast")
                            Spacer()
                            Text(appVersionString)
                                .font(.footnote)
                                .foregroundStyle(Theme.inkSecondary)
                        }

                        Text("Built with care by Mustard Seed Labs.")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSecondary)

                        // Opens your contact page
                        Link(destination: URL(string: "https://www.mustardseedlabs.io/contact")!) {
                            Label("Contact Mustard Seed Labs", systemImage: "paperplane.fill")
                        }
                    }
                } header: {
                    Text("About & Contact")
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Theme.accent)
            .foregroundStyle(Theme.ink)
            .background(Theme.bg.ignoresSafeArea())
            .onAppear { refreshAuth() }

            // Alerts
            .alert("Notifications are disabled", isPresented: $showingDeniedAlert) {
                Button("Open Settings") { NotificationManager.shared.openSystemSettings() }
                Button("OK", role: .cancel) { }
            } message: {
                Text("To receive reminders, allow notifications for Steadfast in iOS Settings.")
            }

            .alert("Re-run onboarding?", isPresented: $confirmReset) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("You’ll see onboarding the next time you return to the app.")
            }
        }
    }

    private var statusBadge: some View {
        Group {
            switch authStatus {
            case .authorized, .provisional, .ephemeral:
                Label("On", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            case .denied:
                Label("Off", systemImage: "xmark.circle.fill").foregroundStyle(.red)
            case .notDetermined:
                Label("Ask", systemImage: "questionmark.circle.fill").foregroundStyle(.orange)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle").foregroundStyle(.orange)
            }
        }
        .font(.footnote.weight(.semibold))
    }

    private func refreshAuth() {
        NotificationManager.shared.fetchAuthorizationStatus { status in
            authStatus = status
        }
    }

    private func requestAndApply() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    showingDeniedAlert = true
                } else if settings.authorizationStatus == .notDetermined {
                    NotificationManager.shared.requestAndScheduleDailyCheckins()
                    apply()
                } else {
                    apply()
                }
                refreshAuth()
            }
        }
    }

    private func apply() {
        let ud = UserDefaults.standard
        ud.set(vm.notifEnabled, forKey: "notif_enabled")
        ud.set(vm.morningEnabled, forKey: "notif_morning_enabled")
        ud.set(vm.middayEnabled, forKey: "notif_midday_enabled")
        ud.set(vm.eveningEnabled, forKey: "notif_evening_enabled")

        ud.set(vm.morningTime.timeIntervalSince1970, forKey: "notif_morning_time")
        ud.set(vm.middayTime.timeIntervalSince1970, forKey: "notif_midday_time")
        ud.set(vm.eveningTime.timeIntervalSince1970, forKey: "notif_evening_time")

        ud.synchronize()

        NotificationManager.shared.scheduleDailyFromSettings()
        dumpPending() // optional debug print
    }
}

private var appVersionString: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "—"
    let build = info?["CFBundleVersion"] as? String ?? "—"
    return "v\(version) (\(build))"
}
