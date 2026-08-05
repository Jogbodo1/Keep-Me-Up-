import UserNotifications
import WatchKit

func weekdayNumber(for day: Weekday) -> Int {
    switch day {
    case .sunday: return 1
    case .monday: return 2
    case .tuesday: return 3
    case .wednesday: return 4
    case .thursday: return 5
    case .friday: return 6
    case .saturday: return 7
    }
}

func scheduleRepeatingAlarm(alarm: AlarmSetting) {
    let content = UNMutableNotificationContent()
    content.title = "Keep Me Up!"
    content.body = "Time to get up!"
    content.sound = UNNotificationSound.default

    for day in alarm.days {
        var components = DateComponents()
        components.hour = Calendar.current.component(.hour, from: alarm.time)
        components.minute = Calendar.current.component(.minute, from: alarm.time)
        components.weekday = weekdayNumber(for: day)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString + day.rawValue,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

func cancelAlarm(_ alarm: AlarmSetting) {
    let center = UNUserNotificationCenter.current()
    let identifiers = alarm.days.map { day in
        alarm.id.uuidString + day.rawValue
    }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
    center.removeDeliveredNotifications(withIdentifiers: identifiers)
}

func rescheduleAlarm(_ alarm: AlarmSetting) {
    cancelAlarm(alarm)
    scheduleRepeatingAlarm(alarm: alarm)
}
func triggerTestAlarm() {
    let content = UNMutableNotificationContent()
    content.title = "Keep Me Up!"
    content.body = "Test Alarm Triggered"
    content.sound = UNNotificationSound.default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

    let request = UNNotificationRequest(
        identifier: "testAlarm",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
    
    // Note: When the notification fires and the app is active, route to AlarmEngine to enforce movement
}
