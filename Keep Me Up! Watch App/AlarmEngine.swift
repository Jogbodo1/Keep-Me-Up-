import Foundation
import Combine
import WatchKit

final class AlarmEngine: ObservableObject {
    @Published private(set) var isRinging: Bool = false
    @Published private(set) var activeAlarm: AlarmSetting? = nil
    @Published private(set) var timeRemaining: Int = 0     // ADDED: seconds left in the compliance window
    @Published private(set) var timeExpired: Bool = false  // ADDED: true once the window has run out
    @Published private(set) var giveMeFiveUsed: Bool = false  // ADDED: tracks the one-time "Give me 5" use

    private var giveMeFiveUntil: Date? = nil                  // ADDED: vibrations paused until this time

    private var cancellables = Set<AnyCancellable>()
    private var complianceDeadline: Date? = nil
    private var countdownTimer: AnyCancellable? = nil

    let motionMonitor: MotionMonitor

    init(motionMonitor: MotionMonitor = MotionMonitor()) {
        self.motionMonitor = motionMonitor
    }

    // ADDED: only true when Strict Mode is off and Movement Required is on — that's
    // the one combination that otherwise has no way to exit before time runs out.
    var giveMeFiveAvailable: Bool {
        guard let alarm = activeAlarm else { return false }
        return !alarm.strictMode && alarm.requireMovement && !giveMeFiveUsed
    }

    // ADDED: pauses reprompt vibrations for 5 minutes of the countdown. One-time use per alarm.
    func activateGiveMeFive() {
        guard giveMeFiveAvailable else { return }
        giveMeFiveUsed = true
        giveMeFiveUntil = Date().addingTimeInterval(5 * 60)
    }

    func startRinging(for alarm: AlarmSetting, requireMovement: Bool = false, monitoringMinutes: Int = 60) {
        activeAlarm = alarm
        isRinging = true
        timeExpired = false
        giveMeFiveUsed = false   // ADDED: fresh allowance for this alarm
        giveMeFiveUntil = nil    // ADDED
        playHaptic()

        guard requireMovement else {
            timeRemaining = 0
            return
        }

        let deadline = Date().addingTimeInterval(TimeInterval(monitoringMinutes * 60))
        complianceDeadline = deadline
        timeRemaining = monitoringMinutes * 60

        // ADDED: ticks every second so the ringing view can show a live countdown
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickCountdown()
            }

        motionMonitor.$isStandingAndMoving
            .receive(on: RunLoop.main)
            .sink { [weak self] moving in
                guard let self = self else { return }
                if moving {
                    self.stopRinging()
                } else {
                    self.repromptIfNeeded()
                }
            }
            .store(in: &cancellables)

        motionMonitor.startMonitoring()
    }

    private func tickCountdown() {
        guard let deadline = complianceDeadline else { return }
        let remaining = Int(deadline.timeIntervalSinceNow.rounded(.up))
        timeRemaining = max(0, remaining)
        if timeRemaining == 0 {
            timeExpired = true      // ADDED: view watches this to reveal the Exit button
            countdownTimer?.cancel()
        }
    }

    func stopRinging() {
        isRinging = false
        activeAlarm = nil
        timeRemaining = 0
        timeExpired = false
        giveMeFiveUsed = false     // ADDED: reset so it's available again for the next alarm
        giveMeFiveUntil = nil      // ADDED
        complianceDeadline = nil
        motionMonitor.stopMonitoring()
        cancellables.removeAll()
        countdownTimer?.cancel()
        countdownTimer = nil
    }

    private func repromptIfNeeded() {
        guard let deadline = complianceDeadline else { return }
        // ADDED: if "Give me 5" is active, skip the vibration entirely — the
        // countdown itself keeps running as normal, only the reprompt is silenced.
        if let pausedUntil = giveMeFiveUntil, Date() < pausedUntil {
            return
        }
        if Date() < deadline {
            playHaptic()
        }
        // CHANGED: this used to auto-call stopRinging() once the deadline passed.
        // Now the countdown timer flips timeExpired instead, and the person exits
        // manually via the button in AlarmRingingView — that's the behavior you asked for.
    }

    private func playHaptic() {
        WKInterfaceDevice.current().play(.notification)
    }
}
