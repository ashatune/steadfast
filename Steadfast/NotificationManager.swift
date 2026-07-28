// NotificationManager.swift
import Foundation
import UserNotifications
import UIKit

// Subclass NSObject so we can be a UNUserNotificationCenterDelegate
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() {}

    static let dailyPeaceReminderIdentifier = "steadfast.peacePractice.daily"
    static let dailyPeaceReminderEnabledKey = "peace_practice_reminder_enabled"
    static let dailyPeaceReminderHourKey = "peace_practice_reminder_hour"
    static let dailyPeaceReminderMinuteKey = "peace_practice_reminder_minute"

    enum RhythmType: String {
        case morning
        case midday
        case evening
    }
    
    // Add a new id
    private let anchorId = "steadfast.anchor.verse.11am"
    private let morningDevotionalId = "steadfast.devotional.8am"


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

        if let rhythmToken = userInfo["rhythmType"] as? String,
           let rhythmType = RhythmType(rawValue: rhythmToken.lowercased()) {
            UserDefaults.standard.set(rhythmType.rawValue, forKey: DeepLinkRoute.pendingRouteDefaultsKey)
            NotificationCenter.default.post(name: .steadfastPendingRoute, object: rhythmType.rawValue)
            completionHandler()
            return
        }

        if let route = userInfo["route"] as? String {
            // save for RootView / AppViewModel to consume on next appear
            UserDefaults.standard.set(route, forKey: DeepLinkRoute.pendingRouteDefaultsKey)
            NotificationCenter.default.post(name: .steadfastPendingRoute, object: route)
        } else if let routeURL = userInfo["route"] as? URL {
            let routeString = routeURL.absoluteString
            UserDefaults.standard.set(routeString, forKey: DeepLinkRoute.pendingRouteDefaultsKey)
            NotificationCenter.default.post(name: .steadfastPendingRoute, object: routeURL)
        } else if let deepLink = userInfo["deepLink"] as? String {
            UserDefaults.standard.set(deepLink, forKey: DeepLinkRoute.pendingRouteDefaultsKey)
            NotificationCenter.default.post(name: .steadfastPendingRoute, object: deepLink)
        } else if let deepLinkRoute = userInfo["deepLinkRoute"] as? String {
            UserDefaults.standard.set(deepLinkRoute, forKey: DeepLinkRoute.pendingRouteDefaultsKey)
            NotificationCenter.default.post(name: .steadfastPendingRoute, object: deepLinkRoute)
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

    /// Refreshes notifications that the user has already authorized without ever
    /// presenting the system permission prompt. Safe to call during app launch.
    func scheduleAuthorizedNotificationsFromSettings() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral else { return }

            DispatchQueue.main.async {
                self.scheduleDailyFromSettings()
                self.scheduleStoredDailyPeaceReminderIfEnabled()
            }
        }
    }

    /// Requests permission only when necessary, then replaces the single daily
    /// peace-practice reminder. Completion is always delivered on the main queue.
    func enableDailyPeaceReminder(
        hour: Int,
        minute: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: Self.dailyPeaceReminderEnabledKey)
        defaults.set(max(0, min(hour, 23)), forKey: Self.dailyPeaceReminderHourKey)
        defaults.set(max(0, min(minute, 59)), forKey: Self.dailyPeaceReminderMinuteKey)
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyPeaceReminderIdentifier])
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.scheduleDailyPeaceReminder(hour: hour, minute: minute, completion: completion)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error { print("🔔 peace reminder authorization error:", error) }
                    guard granted else {
                        DispatchQueue.main.async { completion(false) }
                        return
                    }
                    self.scheduleDailyPeaceReminder(hour: hour, minute: minute, completion: completion)
                }
            case .denied:
                DispatchQueue.main.async { completion(false) }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    func disableDailyPeaceReminder() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: Self.dailyPeaceReminderEnabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyPeaceReminderIdentifier]
        )
    }

    private func scheduleStoredDailyPeaceReminderIfEnabled() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.dailyPeaceReminderEnabledKey) else { return }
        let hour = defaults.integer(forKey: Self.dailyPeaceReminderHourKey)
        let minute = defaults.integer(forKey: Self.dailyPeaceReminderMinuteKey)
        scheduleDailyPeaceReminder(hour: hour, minute: minute) { _ in }
    }

    private func scheduleDailyPeaceReminder(
        hour: Int,
        minute: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyPeaceReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Your moment of peace"
        content.body = "Take 5 minutes to breathe, pray, and reconnect with God."
        content.sound = .default
        content.userInfo = ["notificationType": "daily_peace_practice"]

        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = .autoupdatingCurrent
        components.hour = max(0, min(hour, 23))
        components.minute = max(0, min(minute, 59))
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyPeaceReminderIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            let succeeded = error == nil
            if let error { print("🔔 peace reminder add error:", error) }
            if succeeded {
                let defaults = UserDefaults.standard
                defaults.set(true, forKey: Self.dailyPeaceReminderEnabledKey)
                defaults.set(components.hour, forKey: Self.dailyPeaceReminderHourKey)
                defaults.set(components.minute, forKey: Self.dailyPeaceReminderMinuteKey)
                defaults.set(true, forKey: "notif_enabled")
            }
            DispatchQueue.main.async { completion(succeeded) }
        }
    }

    /// Read settings from UserDefaults and (re)schedule

    func scheduleDailyFromSettings() {
        let ud = UserDefaults.standard
        let master   = ud.object(forKey: "notif_enabled")           as? Bool ?? true
        let mEnabled = ud.object(forKey: "notif_morning_enabled")   as? Bool ?? false
        let mdEnabled = ud.object(forKey: "notif_midday_enabled")    as? Bool ?? false
        let eEnabled = ud.object(forKey: "notif_evening_enabled")   as? Bool ?? false

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
        center.removePendingNotificationRequests(withIdentifiers: [morningDevotionalId])

        guard masterEnabled else { return }

        func comps(_ date: Date) -> DateComponents {
            var dc = Calendar.current.dateComponents([.hour, .minute], from: date)
            dc.second = 0
            return dc
        }

        func add(_ id: String,
                 _ devotionalContent: DailyDevotionalNotificationContent,
                 _ date: Date,
                 rhythmType: RhythmType,
                 timeOfDay: String) {
            let content = UNMutableNotificationContent()
            content.title = devotionalContent.title
            content.subtitle = devotionalContent.subtitle ?? ""
            content.body = devotionalContent.preview
            content.sound = .default
            content.categoryIdentifier = devotionalContent.category
            content.userInfo = [
                "route": rhythmType.rawValue,
                "rhythmType": rhythmType.rawValue,
                "notificationType": devotionalContent.category,
                "notificationTimeOfDay": timeOfDay,
                "notificationTone": devotionalContent.isQuestionBased ? "question_based" : "reminder_based"
            ]

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps(date), repeats: true)
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req) { err in
                if let err = err { print("🔔 add err for \(id):", err) }
            }
        }

        let notificationProvider = DailyDevotionalNotificationProvider.shared

        if morning.enabled {
            add(ids[0],
                notificationProvider.cachedContent(moment: .morning),
                morning.date,
                rhythmType: .morning,
                timeOfDay: "morning")
        }
        if midday.enabled {
            add(ids[1],
                notificationProvider.cachedContent(moment: .afternoon),
                midday.date,
                rhythmType: .midday,
                timeOfDay: "afternoon")
        }
        if evening.enabled {
            add(ids[2],
                notificationProvider.cachedContent(moment: .evening),
                evening.date,
                rhythmType: .evening,
                timeOfDay: "evening")
        }

        // Morning devotional (fixed 8:00 AM local)
        scheduleMorningDevotional()

        // Optional: log what's scheduled
        dumpPending()
    }

    func cancelDailyCheckins() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids + [morningDevotionalId])
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
    func scheduleAnchorVerseAt11IfEnabled(sound: UNNotificationSound = .default)
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
            let anchorVerse = DailyVerseProvider.shared.verse(for: next, calendar: Calendar.current)
            let (title, body) = DailyVerseProvider.shared.anchorBannerLine(for: anchorVerse)
            var dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: next)
            dc.second = 0

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound
            let routeString = DeepLinkRoute.anchorExerciseURL(anchorID: anchorVerse.ref)?.absoluteString
            ?? DeepLinkRoute.anchorExerciseURL()?.absoluteString
            ?? "anchor"
            content.userInfo = ["route": routeString]

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

    // 8:00 AM Daily Devotional notification (fixed time, repeats daily)
    func scheduleMorningDevotional() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningDevotionalId])

        let masterEnabled = UserDefaults.standard.object(forKey: "notif_enabled") as? Bool ?? true
        guard masterEnabled else { return }

        let comps = DateComponents(hour: 8, minute: 0, second: 0)
        let cached = DailyDevotionalNotificationProvider.shared.cachedContent(for: Date(), moment: .morning)
        let routeString = DeepLinkRoute.dailyDevotionalURL()?.absoluteString
        ?? DeepLinkRoute.dailyDevotionalRouteToken

        let content = UNMutableNotificationContent()
        content.title = cached.title
        content.subtitle = cached.subtitle ?? "Daily Devotional"
        content.body = cached.preview
        content.sound = .default
        content.categoryIdentifier = cached.category
        content.userInfo = [
            "route": routeString,
            "deepLink": routeString,
            "deepLinkRoute": "dailyDevotional",
            "notificationType": cached.category,
            "notificationTimeOfDay": "morning",
            "notificationTone": cached.isQuestionBased ? "question_based" : "reminder_based"
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: morningDevotionalId, content: content, trigger: trigger)
        center.add(req) { err in
            if let err = err { print("🔔 devotional add err:", err) }
        }
    }

    func cancelMorningDevotional() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningDevotionalId])
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
