import Foundation
import Combine
import SwiftUI

/// 应用全局状态容器：负责当前会话（正在记录的数据），并协调 Location/Motion/Store
final class AppState: ObservableObject {
    static let shared = AppState()

    let locationManager = LocationManager()
    let motionManager = MotionManager()
    let dataStore = DataStore.shared

    // 当前会话
    @Published var currentSession: Session? = nil
    @Published var isRecording: Bool = false
    @Published var startTime: Date? = nil
    @Published var elapsed: TimeInterval = 0
    @Published var currentSpeed: Double = 0        // km/h
    @Published var averageSpeed: Double = 0        // km/h
    @Published var maxSpeed: Double = 0            // km/h
    @Published var altitude: Double = 0            // meters
    @Published var heading: Double = 0             // degrees, 0=N
    @Published var acceleration: Double = 0        // m/s^2 (total)

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
                    if let session = self.currentSession {
                        session.maxSpeed = max(session.maxSpeed, self.currentSpeed)
                    }
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
                guard let self, let loc, self.isRecording else { return }
                self.currentSession?.addLocation(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    speed: loc.speed > 0 ? loc.speed * 3.6 : 0,
                    altitude: loc.altitude,
                    timestamp: loc.timestamp
                )
            }
            .store(in: &cancellables)

        motionManager.$totalAcceleration
            .receive(on: RunLoop.main)
            .assign(to: &$acceleration)

        motionManager.$lastMotion
            .receive(on: RunLoop.main)
            .sink { [weak self] acc in
                guard let self, self.isRecording else { return }
                self.currentSession?.addMotion(
                    x: acc.x, y: acc.y, z: acc.z, timestamp: Date()
                )
            }
            .store(in: &cancellables)
    }

    func startRecording() {
        let session = Session(context: dataStore.container.viewContext)
        session.id = UUID()
        session.startTime = Date()
        session.title = Self.dateFormatter.string(from: session.startTime!)
        session.maxSpeed = 0
        session.distance = 0
        currentSession = session
        startTime = session.startTime
        maxSpeed = 0
        elapsed = 0
        averageSpeed = 0

        isRecording = true
        locationManager.start()
        motionManager.start()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsed = Date().timeIntervalSince(start)
            if let session = self.currentSession {
                session.duration = self.elapsed
                let total = session.locations?.count ?? 0
                if total > 0 {
                    self.averageSpeed = self.currentSpeed > 0
                        ? (self.averageSpeed * Double(total - 1) + self.currentSpeed) / Double(total)
                        : self.averageSpeed
                    session.averageSpeed = self.averageSpeed
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        timer?.invalidate()
        timer = nil

        if let session = currentSession {
            session.endTime = Date()
            if session.distance == 0 {
                session.distance = locationManager.totalDistance
            }
            dataStore.save()
        }
        locationManager.stop()
        motionManager.stop()
        currentSession = nil
        startTime = nil
    }

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
