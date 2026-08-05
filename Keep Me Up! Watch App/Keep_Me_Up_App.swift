import SwiftUI
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onReceive: ((UNNotification) -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Present alert/sound and also forward to app for in-app alarm handling
        onReceive?(notification)
        return [.banner, .sound]
    }
}

@main
struct Keep_Me_Up__Watch_AppApp: App {
    @StateObject private var motionMonitor = MotionMonitor()
    @StateObject private var alarmEngine = AlarmEngine()

    private let notificationDelegate = NotificationDelegate()

    init() {
        // Request notification authorization early
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notification auth granted: \(granted)")
            }
        }
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AlarmListView()
            }
            .environmentObject(motionMonitor)
            .environmentObject(alarmEngine)
            .onAppear {
                // Forward notifications to the alarm engine when app is active
                notificationDelegate.onReceive = { _ in
                    // If there's a policy to auto-start engine on notification, you can look up the matching alarm here.
                    // For now, simply play a haptic as a cue; integration can be expanded to match identifiers.
                    // alarmEngine.startRinging(for: matchedAlarm, requireMovement: matchedAlarm.requireMovement || matchedAlarm.strictMode, monitoringMinutes: matchedAlarm.monitoringMinutes)
                }
            }
        }
    }
}
