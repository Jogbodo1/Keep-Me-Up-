import SwiftUI
import WatchKit

struct AlarmListView: View {
    @State private var alarms: [AlarmSetting] = []
    @State private var showingAddAlarm = false
    @State private var isEditing = false
    @State private var selectedAlarms = Set<UUID>()
    
    @EnvironmentObject private var alarmEngine: AlarmEngine
    @EnvironmentObject private var motionMonitor: MotionMonitor
    
    // Custom in-app alarm screen
    @State private var activeAlarm: AlarmSetting? = nil
    
    var body: some View {
        ZStack {
            
            // MAIN LIST + EDIT MODE
            VStack {
                
                // Delete Selected button (only in edit mode)
                if isEditing {
                    Button("Delete Selected") {
                        deleteSelectedAlarms()
                    }
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
                }
                
                List {
                    ForEach(alarms.indices, id: \.self) { index in
                        
                        if isEditing {
                            // Checkbox selection row
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { selectedAlarms.contains(alarms[index].id) },
                                    set: { isOn in
                                        if isOn {
                                            selectedAlarms.insert(alarms[index].id)
                                        } else {
                                            selectedAlarms.remove(alarms[index].id)
                                        }
                                    }
                                ))
                                .labelsHidden()
                                
                                AlarmRowView(alarm: alarms[index])
                            }
                            
                        } else {
                            // Normal navigation row
                            NavigationLink(
                                destination: AlarmEditingView(
                                    alarm: $alarms[index],
                                    onSave: { updatedAlarm in
                                        updateAlarm(updatedAlarm)
                                    },
                                    onDelete: { alarmToDelete in
                                        deleteAlarm(alarmToDelete)
                                    }
                                )
                            ) {
                                AlarmRowView(alarm: alarms[index])
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
                
                // Edit / Done button
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                        selectedAlarms.removeAll()
                    }
                }
                
                // Add button (hidden during edit mode)
                ToolbarItem(placement: .topBarLeading) {
                    if !isEditing {
                        Button("Add") {
                            showingAddAlarm = true
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("Test Engine") {
                        if let first = alarms.first {
                            alarmEngine.startRinging(for: first, requireMovement: true, monitoringMinutes: 60)
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
                        // Start in-app engine with movement enforcement according to settings
                        alarmEngine.startRinging(for: testAlarm, requireMovement: testAlarm.requireMovement || testAlarm.strictMode, monitoringMinutes: testAlarm.monitoringMinutes)
                        triggerInAppAlarm(testAlarm)
                    }
                )
            }
            
            
            // CUSTOM IN-APP ALARM SCREEN OVERLAY
            if let alarm = activeAlarm {
                AlarmRingingView(alarm: alarm) {
                    activeAlarm = nil
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
            }
        }
    }
    
    
    // MARK: - Alarm Actions
    
    func addAlarm(_ alarm: AlarmSetting) {
        alarms.append(alarm)
        scheduleRepeatingAlarm(alarm: alarm)
    }
    
    func updateAlarm(_ alarm: AlarmSetting) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            rescheduleAlarm(alarm)
        }
    }
    
    func deleteAlarm(_ alarm: AlarmSetting) {
        alarms.removeAll { $0.id == alarm.id }
        cancelAlarm(alarm)
    }
    
    func deleteSelectedAlarms() {
        let alarmsToDelete = alarms.filter { selectedAlarms.contains($0.id) }
        
        for alarm in alarmsToDelete {
            cancelAlarm(alarm)
        }
        
        alarms.removeAll { selectedAlarms.contains($0.id) }
        selectedAlarms.removeAll()
        isEditing = false
    }
    
    func deleteAtOffsets(_ offsets: IndexSet) {
        for index in offsets {
            let alarm = alarms[index]
            cancelAlarm(alarm)
        }
        alarms.remove(atOffsets: offsets)
    }
    
    
    // MARK: - Custom In-App Alarm Trigger
    
    func triggerInAppAlarm(_ alarm: AlarmSetting) {
        // Haptic vibration
        WKInterfaceDevice.current().play(.notification)
        
        // Show alarm screen
        activeAlarm = alarm
        
        alarmEngine.startRinging(for: alarm, requireMovement: alarm.requireMovement || alarm.strictMode, monitoringMinutes: alarm.monitoringMinutes)
    }
}

