import Foundation
import SwiftUI
import Combine

final class AlarmStore: ObservableObject {

    @AppStorage("alarmsData")
    private var alarmsData: Data = Data()

    @Published var alarms: [AlarmSetting] = []

    init() {
        load()
    }

    func add(_ alarm: AlarmSetting) {
        alarms.append(alarm)
        save()
    }

    func update(_ alarm: AlarmSetting) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx] = alarm
            save()
        }
    }

    func remove(_ alarm: AlarmSetting) {
        alarms.removeAll { $0.id == alarm.id }
        save()
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
            alarms = try JSONDecoder().decode(
                [AlarmSetting].self,
                from: alarmsData
            )
        } catch {
            print("Failed to load alarms: \(error)")
        }
    }
}
