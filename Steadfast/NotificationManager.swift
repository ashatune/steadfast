// NotificationManager.swift
import Foundation
import UserNotifications
import UIKit

// Subclass NSObject so we can be a UNUserNotificationCenterDelegate
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() {}
    
    // Add a new id
    private let anchorId = "steadfast.anchor.verse.11am"


    private let ids = [
        "steadfast.morning.checkin",
        "steadfast.midday.checkin",
        "steadfast.evening.checkin"
    ]

    // Call this once on app launch (e.g., in App.init or first onAppear)
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }

    // Foreground presentation (banner + sound while app open)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // Optional: handle taps to deep-link
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let route = userInfo["route"] as? String {
            // save for RootView / AppViewModel to consume on next appear
            UserDefaults.standard.set(route, forKey: "steadfast.pendingRoute")
        }

        completionHandler()
    }


    func requestAndScheduleDailyCheckins() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                DispatchQueue.main.async { self.scheduleDailyFromSettings() }
            case .denied:
                DispatchQueue.main.async { self.openSystemSettings() }
            case .notDetermined, .ephemeral:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if let error = error { print("🔔 requestAuthorization error:", error) }
                        print("🔔 granted:", granted)
                        if granted { self.scheduleDailyFromSettings() }
                    }
                }
            @unknown default:
                DispatchQueue.main.async { self.scheduleDailyFromSettings() }
            }
        }
    }

    /// Read settings from UserDefaults and (re)schedule

    func scheduleDailyFromSettings() {
        let ud = UserDefaults.standard
        let master   = ud.object(forKey: "notif_enabled")           as? Bool ?? true
        let mEnabled = ud.object(forKey: "notif_morning_enabled")   as? Bool ?? true
        let mdEnabled = ud.object(forKey: "notif_midday_enabled")    as? Bool ?? true
        let eEnabled = ud.object(forKey: "notif_evening_enabled")   as? Bool ?? true

        // explicit fallback times (match your AppViewModel defaults)
        let defaultMorning = AppViewModel.makeTime(8, 0)
        let defaultMidday  = AppViewModel.makeTime(13, 0)
        let defaultEvening = AppViewModel.makeTime(21, 0)

        // ✅ use TimeInterval, not TimeStamp
        let mTime: Date  = (ud.object(forKey: "notif_morning_time") as? TimeInterval)
            .map(Date.init(timeIntervalSince1970:)) ?? defaultMorning

        let mdTime: Date = (ud.object(forKey: "notif_midday_time") as? TimeInterval)
            .map(Date.init(timeIntervalSince1970:)) ?? defaultMidday

        let eTime: Date  = (ud.object(forKey: "notif_evening_time") as? TimeInterval)
            .map(Date.init(timeIntervalSince1970:)) ?? defaultEvening

        scheduleDaily(
            masterEnabled: master,
            morning: (mEnabled, mTime),
            midday:  (mdEnabled, mdTime),
            evening: (eEnabled, eTime)
        )

        // optional debug
        dumpPending()

    }


    func scheduleDaily(masterEnabled: Bool,
                       morning: (enabled: Bool, date: Date),
                       midday:  (enabled: Bool, date: Date),
                       evening: (enabled: Bool, date: Date)) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard masterEnabled else { return }

        func comps(_ date: Date) -> DateComponents {
            var dc = Calendar.current.dateComponents([.hour, .minute], from: date)
            dc.second = 0
            return dc
        }

        func add(_ id: String,
                 _ title: String,
                 _ body: String,
                 _ date: Date,
                 route: String) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["route": route]   // now 'route' is defined

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps(date), repeats: true)
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req) { err in
                if let err = err { print("🔔 add err for \(id):", err) }
            }
        }


        if morning.enabled {
            add(ids[0],
                "Good Morning ☀️",
                "Take a moment with today’s verse and a breath.",
                morning.date,
                route: "morning")
        }
        if midday.enabled {
            add(ids[1],
                "Got a sec for Midday reset?",
                "🙏 Pause, breathe, and cast your cares.",
                midday.date,
                route: "midday")
        }
        if evening.enabled {
            add(ids[2],
                "Evening wind-down 🌜",
                "Lay it down and rest in GOD’s care.",
                evening.date,
                route: "evening")
        }

        // Optional: log what's scheduled
        dumpPending()
    }

    func cancelDailyCheckins() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func fetchAuthorizationStatus(_ cb: @escaping (UNAuthorizationStatus)->Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { cb(settings.authorizationStatus) }
        }
    }
    
    // Public API: schedule today's anchor verse for the next 11:00 AM if notifications are enabled
    func scheduleAnchorVerseAt11IfEnabled(title: String = "Anchor Verse",
                                          body: String,
                                          sound: UNNotificationSound = .default)
    {
        // Honor master toggle
        let masterEnabled = UserDefaults.standard.object(forKey: "notif_enabled") as? Bool ?? true
        guard masterEnabled else {
            // If master disabled, ensure any pending anchor verse is removed
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [anchorId])
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            let center = UNUserNotificationCenter.current()
            // Remove any existing "anchor" so we don't stack duplicates
            center.removePendingNotificationRequests(withIdentifiers: [self.anchorId])

            // Compute next 11:00 AM from "now" in the current calendar/timezone
            let next = self.nextOccurrence(hour: 11, minute: 0)
            var dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: next)
            dc.second = 0

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound
            content.userInfo = ["route": "anchor"]

            // Single-shot (not repeating) so we can refresh content daily
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
            let req = UNNotificationRequest(identifier: self.anchorId, content: content, trigger: trigger)
            center.add(req) { err in
                if let err = err {
                    print("🔔 anchor add err:", err)
                } else {
                    print("🔔 scheduled anchor verse @ \(dc)")
                }
            }
        }
    }

    // Optional: cancel just the anchor-verse notification
    func cancelAnchorVerse() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [anchorId])
    }

    // Helper: next HH:mm (today if still ahead, otherwise tomorrow)
    private func nextOccurrence(hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var today = cal.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        if today <= now {
            // already passed today → add 1 day
            today = cal.date(byAdding: .day, value: 1, to: today) ?? today
        }
        return today
    }

}

// MARK: - Debug helpers

/// Debug: list pending notifications in console
func dumpPending() {
    UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
        print("🔔 Pending count:", reqs.count)
        for r in reqs {
            let dc = (r.trigger as? UNCalendarNotificationTrigger)?.dateComponents
            print("•", r.identifier, "|", dc as Any)
        }
    }
}

/// Quick test: fire one in N seconds (use to validate)
func scheduleTest(in seconds: TimeInterval = 10) {
    let content = UNMutableNotificationContent()
    content.title = "Steadfast Test"
    content.body = "If you see this, notifications are working."
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, seconds), repeats: false)
    let req = UNNotificationRequest(identifier: "steadfast.test.\(Int(Date().timeIntervalSince1970))", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(req) { err in
        if let err = err { print("🔔 test add err:", err) }
    }
}
