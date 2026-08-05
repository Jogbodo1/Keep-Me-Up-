import SwiftUI

struct AlarmRingingView: View {
    var alarm: AlarmSetting
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Alarm Ringing")
                .font(.title2)
                .bold()
            
            Text(alarm.time.formatted(date: .omitted, time: .shortened))
                .font(.title3)
            
            if alarm.strictMode {
                Text("Strict Mode Active")
                    .foregroundColor(.red)
                    .bold()
                
                Text("You must complete the wake‑up task.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                Button("Dismiss") {
                    onDismiss()
                }
                .padding()
            }
        }
        .padding()
    }
}


