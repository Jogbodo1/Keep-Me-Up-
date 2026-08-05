import SwiftUI
struct AddAlarmView: View {
    @Environment(\.dismiss) var dismiss

    @State private var alarmTime = Date()
    @State private var selectedDays: Set<Weekday> = []
    @State private var strictMode = false
    
    var onSave: (AlarmSetting) -> Void
    var onTestAlarm: (AlarmSetting) -> Void   // ← ADD THIS
    
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

                Button("Test Alarm") {
                    let testAlarm = AlarmSetting(
                        time: alarmTime,
                        days: selectedDays,
                        strictMode: strictMode
                    )
                    onTestAlarm(testAlarm)   // ← CALL IT HERE
                }
                .padding(.top, 6)

                Button("Save Alarm") {
                    let newAlarm = AlarmSetting(
                        time: alarmTime,
                        days: selectedDays,
                        strictMode: strictMode
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



