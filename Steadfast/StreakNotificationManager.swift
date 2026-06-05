import Foundation
import UserNotifications

final class StreakNotificationManager {
    static let shared = StreakNotificationManager()
    private init() {}

    private let reminderId = "steadfast.streak.reminder"
    private let scheduledDayKey = "steadfast.streak.reminder.scheduledDay"
    private let eveningProtectionId = "streakProtectionEvening"
    private let eveningProtectionScheduledDayKey = "steadfast.streakProtectionEvening.scheduledDay"

    func reevaluateReminder(streakManager: StreakManager, now: Date = Date()) {
        guard UserDefaults.standard.object(forKey: "notif_enabled") as? Bool ?? true else {
            clearReminder()
            clearEveningProtectionReminder()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                self.clearReminder()
                self.clearEveningProtectionReminder()
                return
            }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)

            guard streakManager.currentStreak > 0 else {
                self.clearReminder()
                self.clearEveningProtectionReminder(for: today)
                return
            }

            let completedToday = streakManager.completionDays.contains(today)
            guard !completedToday else {
                self.clearReminder(for: today)
                self.clearEveningProtectionReminder(for: today)
                return
            }

            self.scheduleEveningProtectionReminderIfNeeded(now: now, today: today, calendar: calendar)

            let reminderTime = self.preferredReminderTime()
            let targetDate = self.nextOccurrence(for: reminderTime, now: now, calendar: calendar)
            let targetDay = calendar.startOfDay(for: targetDate)

            if let scheduledInterval = UserDefaults.standard.object(forKey: self.scheduledDayKey) as? TimeInterval {
                let scheduledDay = calendar.startOfDay(for: Date(timeIntervalSince1970: scheduledInterval))
                if calendar.isDate(scheduledDay, inSameDayAs: targetDay) {
                    return
                }
            }

            self.scheduleReminder(at: targetDate, day: targetDay)
        }
    }

    private func scheduleReminder(at date: Date, day: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.second = 0

        let reminder = DailyDevotionalNotificationProvider.shared.cachedContent(for: day, moment: .streak)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.subtitle = reminder.subtitle ?? ""
        content.body = reminder.preview
        content.sound = .default
        content.categoryIdentifier = reminder.category
        content.userInfo = [
            "route": DeepLinkRoute.anchorExerciseURL()?.absoluteString ?? "anchor",
            "notificationType": reminder.category,
            "notificationTimeOfDay": timeOfDay(for: date),
            "notificationTone": reminder.isQuestionBased ? "question_based" : "reminder_based"
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                print("🔔 streak reminder add err:", error)
            } else {
                UserDefaults.standard.set(day.timeIntervalSince1970, forKey: self.scheduledDayKey)
            }
        }
    }

    private func scheduleEveningProtectionReminderIfNeeded(now: Date, today: Date, calendar: Calendar) {
        guard isAfterEveningProtectionWindow(now, calendar: calendar) else { return }

        if let scheduledInterval = UserDefaults.standard.object(forKey: eveningProtectionScheduledDayKey) as? TimeInterval {
            let scheduledDay = calendar.startOfDay(for: Date(timeIntervalSince1970: scheduledInterval))
            if calendar.isDate(scheduledDay, inSameDayAs: today) {
                return
            }
        }

        let targetDate = eveningProtectionTargetDate(now: now, calendar: calendar)
        scheduleEveningProtectionReminder(at: targetDate, day: today)
    }

    private func scheduleEveningProtectionReminder(at date: Date, day: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [eveningProtectionId])

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.second = 0

        let copy = eveningProtectionCopy(for: day)
        let routeString = DeepLinkRoute.quickStartMeditationURL()?.absoluteString
        ?? DeepLinkRoute.quickStartMeditationRouteToken

        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = "streak_protection_evening"
        content.userInfo = [
            "route": routeString,
            "deepLink": routeString,
            "deepLinkRoute": DeepLinkRoute.streakProtectionRouteToken,
            "notificationType": "streak_protection_evening",
            "notificationTimeOfDay": "evening",
            "notificationTone": "streak_protection"
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: eveningProtectionId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                print("🔔 streak protection add err:", error)
            } else {
                UserDefaults.standard.set(day.timeIntervalSince1970, forKey: self.eveningProtectionScheduledDayKey)
            }
        }
    }

    func clearReminder(for day: Date? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])

        guard let day else {
            UserDefaults.standard.removeObject(forKey: scheduledDayKey)
            return
        }

        let calendar = Calendar.current
        if let scheduledInterval = UserDefaults.standard.object(forKey: scheduledDayKey) as? TimeInterval {
            let scheduledDay = calendar.startOfDay(for: Date(timeIntervalSince1970: scheduledInterval))
            if calendar.isDate(scheduledDay, inSameDayAs: day) {
                UserDefaults.standard.removeObject(forKey: scheduledDayKey)
            }
        }
    }

    func clearEveningProtectionReminder(for day: Date? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [eveningProtectionId])

        guard let day else {
            UserDefaults.standard.removeObject(forKey: eveningProtectionScheduledDayKey)
            return
        }

        let calendar = Calendar.current
        if let scheduledInterval = UserDefaults.standard.object(forKey: eveningProtectionScheduledDayKey) as? TimeInterval {
            let scheduledDay = calendar.startOfDay(for: Date(timeIntervalSince1970: scheduledInterval))
            if calendar.isDate(scheduledDay, inSameDayAs: day) {
                UserDefaults.standard.removeObject(forKey: eveningProtectionScheduledDayKey)
            }
        }
    }

    private func preferredReminderTime() -> Date {
        let ud = UserDefaults.standard
        let defaultMorning = AppViewModel.makeTime(8, 0)
        let defaultMidday = AppViewModel.makeTime(13, 0)
        let defaultEvening = AppViewModel.makeTime(21, 0)

        let morningEnabled = ud.object(forKey: "notif_morning_enabled") as? Bool ?? false
        let middayEnabled = ud.object(forKey: "notif_midday_enabled") as? Bool ?? false
        let eveningEnabled = ud.object(forKey: "notif_evening_enabled") as? Bool ?? false

        let morningTime = (ud.object(forKey: "notif_morning_time") as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? defaultMorning
        let middayTime = (ud.object(forKey: "notif_midday_time") as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? defaultMidday
        let eveningTime = (ud.object(forKey: "notif_evening_time") as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? defaultEvening

        if morningEnabled { return morningTime }
        if middayEnabled { return middayTime }
        if eveningEnabled { return eveningTime }
        return morningTime
    }

    private func nextOccurrence(for time: Date, now: Date, calendar: Calendar) -> Date {
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)
        var target = calendar.date(bySettingHour: timeComps.hour ?? 8, minute: timeComps.minute ?? 0, second: 0, of: now) ?? now
        if target <= now {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target
    }

    private func isAfterEveningProtectionWindow(_ date: Date, calendar: Calendar) -> Bool {
        let protectionStart = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? date
        return date >= protectionStart
    }

    private func eveningProtectionTargetDate(now: Date, calendar: Calendar) -> Date {
        let suggestedTime = calendar.date(bySettingHour: 19, minute: 15, second: 0, of: now) ?? now
        if now < suggestedTime { return suggestedTime }
        return calendar.date(byAdding: .minute, value: 1, to: now) ?? now
    }

    private func eveningProtectionCopy(for day: Date) -> (title: String, body: String) {
        let options = [
            (
                title: "Keep your rhythm going",
                body: "You still have time to complete a short exercise today."
            ),
            (
                title: "Don’t lose your streak",
                body: "A quick meditation or devotional can keep your rhythm going."
            ),
            (
                title: "One small moment can keep your streak alive",
                body: "Before the day ends, take one small moment with God."
            )
        ]
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: day) ?? 0
        return options[dayIndex % options.count]
    }

    private func timeOfDay(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 12 { return "morning" }
        if hour < 17 { return "afternoon" }
        return "evening"
    }
}
