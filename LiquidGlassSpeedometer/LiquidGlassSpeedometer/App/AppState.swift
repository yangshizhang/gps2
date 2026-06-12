import Foundation
import Combine
import SwiftUI
import CoreLocation

/// 应用全局状态：当前会话（正在记录的数据），协调 Location / Motion / Store
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    let locationManager = LocationManager()
    let motionManager = MotionManager()
    let dataStore = DataStore.shared

    @Published var currentSession: Session? = nil
    @Published var isRecording: Bool = false
    @Published var elapsed: TimeInterval = 0
    @Published var currentSpeed: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var maxSpeed: Double = 0
    @Published var altitude: Double = 0
    @Published var heading: Double = 0
    @Published var acceleration: Double = 0

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        bindManagers()
    }

    private func bindManagers() {
        locationManager.$speedKmH
            .receive(on: RunLoop.main)
            .sink { [weak self] v in
                guard let self else { return }
                self.currentSpeed = max(0, v)
                if self.isRecording {
                    self.maxSpeed = max(self.maxSpeed, self.currentSpeed)
                    self.currentSession?.maxSpeed = self.maxSpeed
                }
            }
            .store(in: &cancellables)

        locationManager.$altitude
            .receive(on: RunLoop.main)
            .assign(to: &$altitude)

        locationManager.$heading
            .receive(on: RunLoop.main)
            .assign(to: &$heading)

        locationManager.$lastLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] loc in
                guard let self, let loc, self.isRecording, var session = self.currentSession else { return }
                let pt = TrackPoint(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    speed: loc.speed > 0 ? loc.speed * 3.6 : 0,
                    altitude: loc.altitude,
                    timestamp: Date()
                )
                session.locations.append(pt)
                // 累计距离（米）
                if session.locations.count >= 2 {
                    let prev = session.locations[session.locations.count - 2]
                    let a = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                    let b = CLLocation(latitude: pt.latitude, longitude: pt.longitude)
                    session.distance += a.distance(from: b)
                }
                // 简单平均速度（总距离 / 总时长）
                let dur = session.duration
                if dur > 0 {
                    session.averageSpeed = (session.distance / 1000.0) / (dur / 3600.0)
                    self.averageSpeed = session.averageSpeed
                }
                self.currentSession = session
            }
            .store(in: &cancellables)

        motionManager.$totalAcceleration
            .receive(on: RunLoop.main)
            .assign(to: &$acceleration)

        motionManager.$lastMotion
            .receive(on: RunLoop.main)
            .sink { [weak self] m in
                guard let self, self.isRecording, var session = self.currentSession else { return }
                let mp = MotionPoint(ax: m.x, ay: m.y, az: m.z, timestamp: Date())
                session.motions.append(mp)
                self.currentSession = session
            }
            .store(in: &cancellables)
    }

    func startRecording() {
        var session = Session(startTime: Date())
        currentSession = session
        maxSpeed = 0
        elapsed = 0
        averageSpeed = 0
        isRecording = true
        locationManager.start()
        motionManager.start()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let s = self.currentSession else { return }
                self.elapsed = s.duration
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        timer?.invalidate()
        timer = nil

        if var session = currentSession {
            session.endTime = Date()
            dataStore.save(session)
        }
        locationManager.stop()
        motionManager.stop()
        currentSession = nil
    }

    // MARK: - 格式化

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static func formatDuration(_ ti: TimeInterval) -> String {
        let total = Int(ti)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
