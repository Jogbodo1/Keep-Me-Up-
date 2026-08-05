import SwiftUI

struct AlarmRowView: View {
    var alarm: AlarmSetting
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(formattedTime(alarm.time))
                .font(.headline)
            
            Text(formattedDays(alarm.days))
                .font(.caption)
                .foregroundColor(.gray)
            
            if alarm.strictMode {
                Text("Strict Mode")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formattedDays(_ days: Set<Weekday>) -> String {
        days.map { $0.rawValue }.joined(separator: ", ")
    }
}

