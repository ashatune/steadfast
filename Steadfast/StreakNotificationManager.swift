import Foundation
import UserNotifications

final class StreakNotificationManager {
    static let shared = StreakNotificationManager()
    private init() {}

    private let reminderId = "steadfast.streak.reminder"
    private let scheduledDayKey = "steadfast.streak.reminder.scheduledDay"

    func reevaluateReminder(streakManager: StreakManager, now: Date = Date()) {
        guard UserDefaults.standard.object(forKey: "notif_enabled") as? Bool ?? true else {
            clearReminder()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                self.clearReminder()
                return
            }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)

            guard streakManager.currentStreak > 0 else {
                self.clearReminder()
                return
            }

            guard !streakManager.hasCompletion(on: now) else {
                self.clearReminder(for: today)
                return
            }

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

        let content = UNMutableNotificationContent()
        content.title = reminderTitle()
        content.body = reminderBody(for: day)
        content.sound = .default
        content.userInfo = ["route": DeepLinkRoute.anchorExerciseURL()?.absoluteString ?? "anchor"]

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

    private func reminderTitle() -> String {
        "Keep your rhythm going 🙏"
    }

    private func reminderBody(for day: Date) -> String {
        let options = [
            "Take a moment with Steadfast today.",
            "Your streak is still here for you. Come back for a moment of peace.",
            "Come back for a breath and a verse when you're ready."
        ]
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: day) ?? 0
        return options[dayIndex % options.count]
    }
}
