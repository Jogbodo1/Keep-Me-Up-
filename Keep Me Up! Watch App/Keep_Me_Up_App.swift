import SwiftUI
import UserNotifications

@main
struct Keep_Me_Up__Watch_AppApp: App {
    // CHANGED: notification handling now lives in AppDelegate (see AppDelegate.swift),
    // wired up via applicationDidFinishLaunching() -- the reliable, documented hook
    // for catching a watchOS notification tap, including one that cold-launches the app.
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var motionMonitor = MotionMonitor()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AlarmListView()
            }
            .environmentObject(motionMonitor)
            .environmentObject(appDelegate.alarmEngine)   // CHANGED: sourced from the app delegate now
            .environmentObject(appDelegate.alarmStore)    // CHANGED
            .onAppear {
                checkForActiveAlarmNotification()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkForActiveAlarmNotification()
                }
            }
        }
    }

    // Covers opening the app manually (not via tapping the notification) while
    // an alarm notification is still sitting there delivered.
    private func checkForActiveAlarmNotification() {
        guard !appDelegate.alarmEngine.isRinging else { return }

        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            // Only consider ones delivered recently (last 30 minutes) so an old,
            // already-handled notification can't re-trigger the ringing screen.
            guard let mostRecent = notifications
                .filter({ $0.date.timeIntervalSinceNow > -30 * 60 })
                .sorted(by: { $0.date > $1.date })
                .first
            else { return }

            appDelegate.routeToAlarm(from: mostRecent)
        }
    }
}
