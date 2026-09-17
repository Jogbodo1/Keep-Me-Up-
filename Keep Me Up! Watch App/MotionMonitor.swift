import Foundation

import Combine

#if canImport(CoreMotion)

import CoreMotion

#endif

 

final class MotionMonitor: ObservableObject {

    @Published var isStandingAndMoving: Bool = false

 

    #if canImport(CoreMotion)

    private let motionManager = CMMotionManager()

    #endif

 

    private var timer: Timer?

 

    // TUNABLE: how much acceleration deviation counts as "moving"

    // Lower = more sensitive (easier to trigger), Higher = less sensitive (harder to trigger)

    private let motionThreshold = 0.15

 

    // TUNABLE: how many recent readings (at 0.2s each) to look at

    // 15 readings = 3 seconds of history

    private let bufferSize = 15

 

    // TUNABLE: fraction of buffer that must show motion to count as "moving"

    // 0.5 = half of recent readings must show motion

    private let requiredMotionFraction = 0.5

 

    private var recentReadings: [Bool] = []

 

    func startMonitoring() {

        #if canImport(CoreMotion)

        startAccelerometer()

        #else

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in

            self?.isStandingAndMoving.toggle()

        }

        #endif

    }

 

    func stopMonitoring() {

        #if canImport(CoreMotion)

        motionManager.stopAccelerometerUpdates()

        #endif

        timer?.invalidate()

        timer = nil

        isStandingAndMoving = false

        recentReadings.removeAll()

    }

 

    #if canImport(CoreMotion)

    private func startAccelerometer() {

        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.2

        let queue = OperationQueue()

        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in

            guard let self = self, let data = data else { return }

 

            let ax = data.acceleration.x

            let ay = data.acceleration.y

            let az = data.acceleration.z

            let magnitude = sqrt(ax * ax + ay * ay + az * az)

 

            // Deviation from 1g (gravity at rest)

            let deviation = abs(magnitude - 1.0)

            let isMoving = deviation > self.motionThreshold

 

            self.recentReadings.append(isMoving)

            if self.recentReadings.count > self.bufferSize {

                self.recentReadings.removeFirst()

            }

 

            self.updateMotionState()

        }

    }

 

    private func updateMotionState() {

        let movingCount = recentReadings.filter { $0 }.count

        let fraction = recentReadings.isEmpty ? 0 : Double(movingCount) / Double(recentReadings.count)

        let shouldBeMoving = fraction >= requiredMotionFraction

 

        DispatchQueue.main.async {

            self.isStandingAndMoving = shouldBeMoving

        }

    }

    #endif

}
