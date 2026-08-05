import Foundation
import Combine
import WatchKit

final class AlarmEngine: ObservableObject {
    @Published private(set) var isRinging: Bool = false
    @Published private(set) var activeAlarm: AlarmSetting? = nil

    private var cancellables = Set<AnyCancellable>()
    private var complianceDeadline: Date? = nil

    let motionMonitor: MotionMonitor

    init(motionMonitor: MotionMonitor = MotionMonitor()) {
        self.motionMonitor = motionMonitor
    }

    func startRinging(for alarm: AlarmSetting, requireMovement: Bool = false, monitoringMinutes: Int = 60) {
        activeAlarm = alarm
        isRinging = true
        playHaptic()

        guard requireMovement else { return }

        complianceDeadline = Date().addingTimeInterval(TimeInterval(monitoringMinutes * 60))

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

    func stopRinging() {
        isRinging = false
        activeAlarm = nil
        motionMonitor.stopMonitoring()
        cancellables.removeAll()
    }

    private func repromptIfNeeded() {
        guard let deadline = complianceDeadline else { return }
        if Date() < deadline {
            playHaptic()
        } else {
            stopRinging()
        }
    }

    private func playHaptic() {
        WKInterfaceDevice.current().play(.notification)
    }
}
