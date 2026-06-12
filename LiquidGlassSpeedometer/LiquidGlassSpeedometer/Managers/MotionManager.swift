import Foundation
import CoreMotion
import Combine

/// 加速度传感器管理
final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()

    @Published var totalAcceleration: Double = 0
    @Published var lastMotion: (x: Double, y: Double, z: Double) = (0, 0, 0)

    func start() {
        guard manager.isAccelerometerAvailable else { return }
        manager.accelerometerUpdateInterval = 1.0 / 20.0
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            self.lastMotion = (d.acceleration.x, d.acceleration.y, d.acceleration.z)
            let g = 9.81
            let ax = d.acceleration.x * g
            let ay = d.acceleration.y * g
            let az = d.acceleration.z * g
            self.totalAcceleration = sqrt(ax*ax + ay*ay + az*az)
        }
    }

    func stop() {
        manager.stopAccelerometerUpdates()
    }
}
