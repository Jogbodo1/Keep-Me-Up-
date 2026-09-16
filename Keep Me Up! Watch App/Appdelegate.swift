import WatchKit
import UserNotifications

// This owns AlarmEngine and AlarmStore directly (not the SwiftUI App struct).
// That matters: this object, and these two properties, exist the moment the
// process launches -- before any SwiftUI view has appeared -- so a notification
// tap that cold-launches the app from the lock screen or from another app
// always has somewhere ready to route to. Setting the delegate in
// applicationDidFinishLaunching() is also the documented, reliable way to
// register for notification taps on watchOS; doing it later (e.g. in the
// SwiftUI App's init(), or a view's onAppear) can lose the very tap that
// caused the app to launch.
final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    let alarmEngine = AlarmEngine()
    let alarmStore = AlarmStore()

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notification auth granted: \(granted)")
            }
        }
    }

    // Notification arrives while the app is already open.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        routeToAlarm(from: notification)
        return [.banner, .sound]
    }

    // Notification is tapped -- app backgrounded, suspended, or launching fresh from a tap.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        routeToAlarm(from: response.notification)
    }

    // Matches a notification's identifier back to the alarm that fired it
    // (identifiers are "<alarm.id.uuidString><day.rawValue>") and starts the
    // ringing engine for it. Also callable from outside (see
    // Keep_Me_Up_App.swift's "opened the app manually" check).
    func routeToAlarm(from notification: UNNotification) {
        let identifier = notification.request.identifier
        guard let matchedAlarm = alarmStore.alarms.first(where: { identifier.hasPrefix($0.id.uuidString) }) else { return }

        DispatchQueue.main.async { [self] in
            alarmEngine.startRinging(
                for: matchedAlarm,
                requireMovement: matchedAlarm.requireMovement || matchedAlarm.strictMode,
                monitoringMinutes: matchedAlarm.monitoringMinutes
            )
        }

        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

