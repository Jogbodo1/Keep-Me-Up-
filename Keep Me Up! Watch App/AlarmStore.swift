import Foundation
import SwiftUI

final class AlarmStore: ObservableObject {
    @AppStorage("alarmsData") private var alarmsData: Data = Data()
    @Published var alarms: [AlarmSetting] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    func add(_ alarm: AlarmSetting) {
        alarms.append(alarm)
    }

    func update(_ alarm: AlarmSetting) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx] = alarm
        }
    }

    func remove(_ alarm: AlarmSetting) {
        alarms.removeAll { $0.id == alarm.id }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(alarms)
            alarmsData = data
        } catch {
            print("Failed to save alarms: \(error)")
        }
    }

    private func load() {
        guard !alarmsData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([AlarmSetting].self, from: alarmsData)
            alarms = decoded
        } catch {
            print("Failed to load alarms: \(error)")
        }
    }
}
