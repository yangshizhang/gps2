import Foundation
import MapKit

/// CoreData 生成 Session/TrackPoint/MotionPoint 的类扩展，提供便捷方法

extension Session {
    func addLocation(latitude: Double, longitude: Double, speed: Double, altitude: Double, timestamp: Date) {
        let ctx = managedObjectContext ?? DataStore.shared.container.viewContext
        let pt = TrackPoint(context: ctx)
        pt.latitude = latitude
        pt.longitude = longitude
        pt.speed = speed
        pt.altitude = altitude
        pt.timestamp = timestamp
        pt.session = self
        if let locs = mutableSetValue(forKey: "locations") as? NSMutableSet {
            locs.add(pt)
        }
    }

    func addMotion(x: Double, y: Double, z: Double, timestamp: Date) {
        let ctx = managedObjectContext ?? DataStore.shared.container.viewContext
        let mp = MotionPoint(context: ctx)
        mp.ax = x
        mp.ay = y
        mp.az = z
        mp.timestamp = timestamp
        mp.session = self
        if let ms = mutableSetValue(forKey: "motions") as? NSMutableSet {
            ms.add(mp)
        }
    }

    func locationPoints() -> [TrackPoint] {
        let arr = (locations?.allObjects as? [TrackPoint]) ?? []
        return arr.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    func coordinates() -> [CLLocationCoordinate2D] {
        return locationPoints().map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    func speedSeries() -> [(time: TimeInterval, speed: Double)] {
        let pts = locationPoints()
        guard let start = startTime else { return [] }
        return pts.map { (t: $0.timestamp?.timeIntervalSince(start) ?? 0, s: $0.speed) }
    }

    func region() -> MKCoordinateRegion? {
        let pts = locationPoints()
        guard pts.count >= 2 else { return nil }
        let lats = pts.map { $0.latitude }
        let lons = pts.map { $0.longitude }
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.01, (maxLat - minLat) * 1.2), longitudeDelta: max(0.01, (maxLon - minLon) * 1.2))
        return MKCoordinateRegion(center: center, span: span)
    }
}
