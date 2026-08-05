import Foundation

struct AlarmSetting: Identifiable {
    var id = UUID()
    var time: Date
    var days: Set<Weekday>
    var strictMode: Bool
    // New: movement compliance settings
    var requireMovement: Bool = false
    var monitoringMinutes: Int = 60
}
