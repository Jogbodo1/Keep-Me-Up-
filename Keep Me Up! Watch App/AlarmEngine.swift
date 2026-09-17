import Foundation
import Combine
import WatchKit
import AVFoundation

final class AlarmEngine: ObservableObject {
    @Published private(set) var isRinging: Bool = false
    @Published private(set) var activeAlarm: AlarmSetting? = nil
    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var timeExpired: Bool = false
    @Published private(set) var giveMeFiveUsed: Bool = false

    private var giveMeFiveUntil: Date? = nil
    private var audioPlayer: AVAudioPlayer?
    private var movementDetectionCount = 0
    private var isCurrentlyComplying: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var complianceDeadline: Date? = nil
    private var countdownTimer: AnyCancellable? = nil

    let motionMonitor: MotionMonitor

    init(motionMonitor: MotionMonitor = MotionMonitor()) {
        self.motionMonitor = motionMonitor
    }

    var giveMeFiveAvailable: Bool {
        guard let alarm = activeAlarm else { return false }
        return !alarm.strictMode && alarm.requireMovement && !giveMeFiveUsed
    }

    func activateGiveMeFive() {
        guard giveMeFiveAvailable else { return }
        giveMeFiveUsed = true
        giveMeFiveUntil = Date().addingTimeInterval(5 * 60)
    }

    func startRinging(for alarm: AlarmSetting, requireMovement: Bool = false, monitoringMinutes: Int = 60) {
        activeAlarm = alarm
        isRinging = true
        timeExpired = false
        giveMeFiveUsed = false
        giveMeFiveUntil = nil
        movementDetectionCount = 0
        isCurrentlyComplying = false
        playHaptic()

        guard requireMovement else {
            timeRemaining = 0
            return
        }

        let deadline = Date().addingTimeInterval(TimeInterval(monitoringMinutes * 60))
        complianceDeadline = deadline
        timeRemaining = monitoringMinutes * 60

        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickCountdown()
            }

        let requiredConsecutiveDetections = 3
       
        motionMonitor.$isStandingAndMoving
            .receive(on: RunLoop.main)
            .sink { [weak self] moving in
                guard let self = self else { return }
               
                if moving {
                    self.movementDetectionCount += 1
                    print("Movement detected: \(self.movementDetectionCount)/\(requiredConsecutiveDetections)")
                   
                    if self.movementDetectionCount >= requiredConsecutiveDetections {
                        print("Sustained movement confirmed - user is awake")
                        self.isCurrentlyComplying = true
                        self.stopAudio()
                    }
                } else {
                    if self.movementDetectionCount > 0 {
                        print("Movement ended, resetting counter")
                    }
                    self.movementDetectionCount = 0
                   
                    if self.isCurrentlyComplying {
                        print("User laid back down - resuming alarm")
                        self.isCurrentlyComplying = false
                        self.playHaptic()
                    }
                   
                    if self.isRinging {
                        self.repromptIfNeeded()
                    }
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
            timeExpired = true
            countdownTimer?.cancel()
        }
    }

    func stopRinging() {
        isRinging = false
        activeAlarm = nil
        timeRemaining = 0
        timeExpired = false
        giveMeFiveUsed = false
        giveMeFiveUntil = nil
        complianceDeadline = nil
        movementDetectionCount = 0
        isCurrentlyComplying = false
        motionMonitor.stopMonitoring()
        cancellables.removeAll()
        countdownTimer?.cancel()
        countdownTimer = nil
        stopAudio()
    }

    private func repromptIfNeeded() {
        guard let deadline = complianceDeadline else { return }
        if let pausedUntil = giveMeFiveUntil, Date() < pausedUntil {
            return
        }
        if Date() < deadline {
            playHaptic()
        }
    }

    private func playHaptic() {
        WKInterfaceDevice.current().play(.notification)
        playSound()
    }

    private func playSound() {
        let soundNames = ["alarm_sound", "alarm", "bell", "chime"]
        let fileExtensions = ["wav", "m4a", "mp3", "caf"]
       
        for soundName in soundNames {
            for ext in fileExtensions {
                if let soundPath = Bundle.main.path(forResource: soundName, ofType: ext) {
                    playAudioFile(at: soundPath)
                    return
                }
            }
        }
       
        print("Warning: No alarm sound file found in bundle")
    }

    private func playAudioFile(at path: String) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            print("Audio playback started")
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    private func stopAudio() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.stop()
        }
        audioPlayer = nil
    }
}
