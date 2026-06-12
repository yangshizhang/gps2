import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 数据模型（Codable，纯 Swift，无 CoreData 依赖）

struct TrackPoint: Codable, Identifiable, Hashable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var speed: Double          // km/h
    var altitude: Double       // meters
    var timestamp: Date
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    init(id: UUID = UUID(), latitude: Double, longitude: Double, speed: Double, altitude: Double, timestamp: Date) {
        self.id = id; self.latitude = latitude; self.longitude = longitude
        self.speed = speed; self.altitude = altitude; self.timestamp = timestamp
    }
}

struct MotionPoint: Codable, Identifiable, Hashable {
    let id: UUID
    var ax: Double
    var ay: Double
    var az: Double
    var timestamp: Date
    init(id: UUID = UUID(), ax: Double, ay: Double, az: Double, timestamp: Date) {
        self.id = id; self.ax = ax; self.ay = ay; self.az = az; self.timestamp = timestamp
    }
}

struct Session: Codable, Identifiable, Hashable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var maxSpeed: Double
    var averageSpeed: Double
    var distance: Double
    var locations: [TrackPoint]
    var motions: [MotionPoint]
    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil,
         maxSpeed: Double = 0, averageSpeed: Double = 0, distance: Double = 0,
         locations: [TrackPoint] = [], motions: [MotionPoint] = []) {
        self.id = id; self.startTime = startTime; self.endTime = endTime
        self.maxSpeed = maxSpeed; self.averageSpeed = averageSpeed; self.distance = distance
        self.locations = locations; self.motions = motions
    }

    /// 返回 bounding region，供地图显示使用
    func region() -> MKCoordinateRegion? {
        guard locations.count >= 2 else { return nil }
        let lats = locations.map(\.latitude)
        let lons = locations.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.2),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.2)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    /// 将位置点转换成 MKMapPoint 数组（Polyline 用）
    func coordinates() -> [CLLocationCoordinate2D] {
        locations.map(\.coordinate)
    }

    /// 车速系列（用于折线图）
    func speedSeries() -> [(time: TimeInterval, speed: Double)] {
        locations.map { ($0.timestamp.timeIntervalSince(startTime), $0.speed) }
    }
}

// MARK: - 数据仓库（ObservableObject，文件持久化）

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published private(set) var sessions: [Session] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "datastore.queue", qos: .utility)

    private init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true))
                  ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("LiquidGlassSpeedometer", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("sessions.json")
        load()
    }

    // MARK: CRUD

    func save(_ session: Session) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        persist()
    }

    func delete(_ session: Session) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    func session(with id: UUID) -> Session? {
        sessions.first { $0.id == id }
    }

    // MARK: 磁盘 IO

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Session].self, from: data) {
            self.sessions = decoded
        }
    }

    private func persist() {
        let items = self.sessions
        let url = self.fileURL
        queue.async {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(items) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
