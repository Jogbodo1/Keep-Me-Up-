import SwiftUI

struct AlarmEditingView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var alarm: AlarmSetting
    var onSave: (AlarmSetting) -> Void
    var onDelete: (AlarmSetting) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                DatePicker(
                    "Alarm Time",
                    selection: $alarm.time,
                    displayedComponents: .hourAndMinute
                )
                
                DayOfWeekSelector(selectedDays: $alarm.days)
                
                Toggle("Strict Mode", isOn: $alarm.strictMode)

                Toggle("Require Movement After Alarm", isOn: $alarm.requireMovement)

                if alarm.requireMovement {
                    HStack {
                        Text("Monitor for")
                        Spacer()
                        Picker("Duration", selection: $alarm.monitoringMinutes) {
                            ForEach([15, 30, 45, 60], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Button("Test Alarm") {
                    // Consider routing through AlarmEngine to enforce movement with current settings
                    triggerTestAlarm()
                }
                .padding(.top, 6)

                Button("Save Changes") {
                    onSave(alarm)
                    dismiss()
                }
                .padding(.top, 10)
                
                Button("Delete Alarm") {
                    onDelete(alarm)
                    dismiss()
                }
                .foregroundColor(.red)
                .padding(.top, 6)
            }
            .padding()
        }
    }
}
