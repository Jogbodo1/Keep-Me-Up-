import Foundation

struct AlarmSetting: Identifiable, Codable {   // ADDED Codable — required so AlarmStore can persist it
    var id = UUID()
    var time: Date
    var days: Set<Weekday>
    var strictMode: Bool
    // New: movement compliance settings
    var requireMovement: Bool = false
    var monitoringMinutes: Int = 60
}

