import SwiftUI

enum Weekday: String, CaseIterable, Hashable, Codable {   // ADDED Codable
    case sunday = "Sun"
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
}

struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack {
            ForEach(Weekday.allCases, id: \.self) { day in
                Toggle(day.rawValue, isOn: Binding(
                    get: { selectedDays.contains(day) },
                    set: { isOn in
                        if isOn {
                            selectedDays.insert(day)
                        } else {
                            selectedDays.remove(day)
                        }
                    }
                ))
            }
        }
        .padding()
    }
}
