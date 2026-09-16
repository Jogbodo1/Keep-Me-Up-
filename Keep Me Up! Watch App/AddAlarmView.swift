import SwiftUI
struct AddAlarmView: View {
    @Environment(\.dismiss) var dismiss

    @State private var alarmTime = Date()
    @State private var selectedDays: Set<Weekday> = []
    @State private var strictMode = false
    @State private var requireMovement = false          // ADDED
    @State private var monitoringMinutes = 60            // ADDED

    var onSave: (AlarmSetting) -> Void
    var onTestAlarm: (AlarmSetting) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                DatePicker(
                    "Alarm Time",
                    selection: $alarmTime,
                    displayedComponents: .hourAndMinute
                )

                DayOfWeekSelector(selectedDays: $selectedDays)

                Toggle("Strict Mode", isOn: $strictMode)

                // ADDED: same controls AlarmEditingView already has
                Toggle("Require Movement After Alarm", isOn: $requireMovement)

                if requireMovement {
                    HStack {
                        Text("Monitor for")
                        Spacer()
                        Picker("Duration", selection: $monitoringMinutes) {
                            ForEach([15, 30, 45, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Button("Test Alarm") {
                    let testAlarm = AlarmSetting(
                        time: alarmTime,
                        days: selectedDays,
                        strictMode: strictMode,
                        requireMovement: requireMovement,   // ADDED
                        monitoringMinutes: monitoringMinutes // ADDED
                    )
                    onTestAlarm(testAlarm)
                }
                .padding(.top, 6)

                Button("Save Alarm") {
                    let newAlarm = AlarmSetting(
                        time: alarmTime,
                        days: selectedDays,
                        strictMode: strictMode,
                        requireMovement: requireMovement,   // ADDED
                        monitoringMinutes: monitoringMinutes // ADDED
                    )
                    onSave(newAlarm)
                    dismiss()
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }
}


