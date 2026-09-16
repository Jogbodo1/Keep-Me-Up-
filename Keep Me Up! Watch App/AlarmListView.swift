import SwiftUI
import WatchKit

struct AlarmListView: View {
    // FIXED: alarms now live in the shared AlarmStore (persisted, and reachable
    // from the app-level notification handler) instead of local un-persisted @State.
    @EnvironmentObject private var alarmStore: AlarmStore
    @State private var showingAddAlarm = false
    @State private var isEditing = false
    @State private var selectedAlarms = Set<UUID>()

    @EnvironmentObject private var alarmEngine: AlarmEngine
    @EnvironmentObject private var motionMonitor: MotionMonitor

    var body: some View {
        ZStack {

            // MAIN LIST + EDIT MODE
            VStack {

                if isEditing {
                    Button("Delete Selected") {
                        deleteSelectedAlarms()
                    }
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
                }

                List {
                    ForEach(alarmStore.alarms.indices, id: \.self) { index in

                        if isEditing {
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { selectedAlarms.contains(alarmStore.alarms[index].id) },
                                    set: { isOn in
                                        if isOn {
                                            selectedAlarms.insert(alarmStore.alarms[index].id)
                                        } else {
                                            selectedAlarms.remove(alarmStore.alarms[index].id)
                                        }
                                    }
                                ))
                                .labelsHidden()

                                AlarmRowView(alarm: alarmStore.alarms[index])
                            }

                        } else {
                            NavigationLink(
                                destination: AlarmEditingView(
                                    alarm: $alarmStore.alarms[index],
                                    onSave: { updatedAlarm in
                                        updateAlarm(updatedAlarm)
                                    },
                                    onDelete: { alarmToDelete in
                                        deleteAlarm(alarmToDelete)
                                    }
                                )
                            ) {
                                AlarmRowView(alarm: alarmStore.alarms[index])
                            }
                        }
                    }
                    .onDelete { indexSet in
                        deleteAtOffsets(indexSet)
                    }
                }
            }
            .navigationTitle("Keep Me Up!")
            .toolbar {
                // ADDED: hide all toolbar chrome while an alarm is ringing so it
                // can't bleed through the overlay or be tapped underneath it.
                if !alarmEngine.isRinging {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                            selectedAlarms.removeAll()
                        }
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        if !isEditing {
                            Button("Add") {
                                showingAddAlarm = true
                            }
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button("Test Engine") {
                            if let first = alarmStore.alarms.first {
                                alarmEngine.startRinging(for: first, requireMovement: true, monitoringMinutes: 60)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(
                    onSave: { newAlarm in
                        addAlarm(newAlarm)
                    },
                    onTestAlarm: { testAlarm in
                        // FIXED: this used to call alarmEngine.startRinging(...) here
                        // AND again inside triggerInAppAlarm(), double-subscribing
                        // the motion monitor. Now it's called exactly once.
                        triggerInAppAlarm(testAlarm)
                    }
                )
            }

            // FIXED: overlay is now driven by AlarmEngine's published state
            // (the single source of truth), not a separate local @State that
            // nothing outside the "Test Alarm" button ever touched.
            if alarmEngine.isRinging, let alarm = alarmEngine.activeAlarm {
                AlarmRingingView(alarm: alarm) {
                    alarmEngine.stopRinging()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
            }
        }
    }


    // MARK: - Alarm Actions

    func addAlarm(_ alarm: AlarmSetting) {
        alarmStore.add(alarm)
        scheduleRepeatingAlarm(alarm: alarm)
    }

    func updateAlarm(_ alarm: AlarmSetting) {
        alarmStore.update(alarm)
        rescheduleAlarm(alarm)
    }

    func deleteAlarm(_ alarm: AlarmSetting) {
        alarmStore.remove(alarm)
        cancelAlarm(alarm)
    }

    func deleteSelectedAlarms() {
        let alarmsToDelete = alarmStore.alarms.filter { selectedAlarms.contains($0.id) }

        for alarm in alarmsToDelete {
            cancelAlarm(alarm)
            alarmStore.remove(alarm)
        }

        selectedAlarms.removeAll()
        isEditing = false
    }

    func deleteAtOffsets(_ offsets: IndexSet) {
        let alarmsToDelete = offsets.map { alarmStore.alarms[$0] }
        for alarm in alarmsToDelete {
            cancelAlarm(alarm)
            alarmStore.remove(alarm)
        }
    }


    // MARK: - Custom In-App Alarm Trigger

    func triggerInAppAlarm(_ alarm: AlarmSetting) {
        WKInterfaceDevice.current().play(.notification)
        alarmEngine.startRinging(
            for: alarm,
            requireMovement: alarm.requireMovement || alarm.strictMode,
            monitoringMinutes: alarm.monitoringMinutes
        )
    }
}
