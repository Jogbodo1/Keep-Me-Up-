import SwiftUI

struct AlarmRingingView: View {
    @EnvironmentObject private var alarmEngine: AlarmEngine
    var alarm: AlarmSetting
    var onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Alarm Ringing")
                    .font(.title2)
                    .bold()

                Text(alarm.time.formatted(date: .omitted, time: .shortened))
                    .font(.title3)

                if alarm.requireMovement {
                    VStack(spacing: 2) {
                        Text("TIME REMAINING")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formattedTime(alarmEngine.timeRemaining))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                }

                if alarm.strictMode {
                    Text("STRICT MODE ACTIVE")
                        .foregroundColor(.red)
                        .bold()

                    Text("Complete your wake-up task")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                if alarm.requireMovement {
                    if alarmEngine.timeExpired {
                        Text("TIME'S UP")
                            .foregroundColor(.green)
                            .bold()
                    } else {
                        Text("MOVEMENT REQUIRED")
                            .foregroundColor(.green)
                            .bold()
                        Text("Keep moving to stay awake")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }

                // ADDED: this is the exit path you were missing.
                // - A plain alarm (no strict mode, no movement requirement) can always be dismissed.
                // - A strict/movement alarm only offers an exit once the compliance window
                //   has actually run out, so "strict" still means something while it's counting down.
                // - ADDED: Strict Mode off + Movement Required on gets a one-time
                //   "Give me 5" button instead of being stuck with no options at all.
                if !alarm.strictMode && !alarm.requireMovement {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .padding(.top, 6)
                } else if alarmEngine.timeExpired {
                    Button("Exit") {
                        onDismiss()
                    }
                    .padding(.top, 6)
                } else if alarmEngine.giveMeFiveAvailable {
                    Button("Give me 5") {
                        alarmEngine.activateGiveMeFive()
                    }
                    .padding(.top, 6)
                }
            }
            .padding()
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
