import Foundation
import Combine
#if canImport(CoreMotion)
import CoreMotion
#endif

final class MotionMonitor: ObservableObject {
    @Published var isStandingAndMoving: Bool = false

    #if canImport(CoreMotion)
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    #endif

    private var timer: Timer?

    func startMonitoring() {
        #if canImport(CoreMotion)
        startActivityUpdates()
        startAccelerometer()
        #else
        // Fallback simulation if CoreMotion is unavailable
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.isStandingAndMoving.toggle()
        }
        #endif
    }

    func stopMonitoring() {
        #if canImport(CoreMotion)
        activityManager.stopActivityUpdates()
        motionManager.stopAccelerometerUpdates()
        #endif
        timer?.invalidate()
        timer = nil
        isStandingAndMoving = false
    }

    #if canImport(CoreMotion)
    private func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            // Consider walking/running/cycling as moving; stationary as not
            let movingByActivity = activity.walking || activity.running || activity.cycling || activity.automotive
            self.mergeSignals(activityMoving: movingByActivity, accelMoving: nil)
        }
    }

    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            // Simple magnitude threshold to detect motion
            let ax = data.acceleration.x
            let ay = data.acceleration.y
            let az = data.acceleration.z
            let magnitude = sqrt(ax*ax + ay*ay + az*az)
            // Earth gravity ~1g; deviations beyond small epsilon indicate movement
            let movingByAccel = abs(magnitude - 1.0) > 0.05
            self.mergeSignals(activityMoving: nil, accelMoving: movingByAccel)
        }
    }

    private var lastActivityMoving: Bool = false
    private var lastAccelMoving: Bool = false

    private func mergeSignals(activityMoving: Bool?, accelMoving: Bool?) {
        if let activityMoving = activityMoving { lastActivityMoving = activityMoving }
        if let accelMoving = accelMoving { lastAccelMoving = accelMoving }
        let moving = lastActivityMoving || lastAccelMoving
        DispatchQueue.main.async {
            self.isStandingAndMoving = moving
        }
    }
    #endif
}
