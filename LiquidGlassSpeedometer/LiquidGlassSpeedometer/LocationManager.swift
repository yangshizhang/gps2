import Foundation
import CoreLocation
import Combine

/// 位置/速度/海拔/航向管理
@MainActor
final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var lastLocation: CLLocation? = nil
    @Published var speedKmH: Double = 0        // km/h
    @Published var altitude: Double = 0         // meters
    @Published var heading: Double = 0          // degrees
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    var totalDistance: Double = 0               // meters

    // 模拟坐标基准（天安门附近），每次 mock 会小幅移动模拟行进
    private var mockLatitude: Double = 39.9087
    private var mockLongitude: Double = 116.3975

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        authorization = manager.authorizationStatus
    }

    func requestAuthorization() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func start() {
        requestAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        totalDistance = 0
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    /// 注入模拟 GPS 数据（测试用）
    func injectMock(speed: Double, altitude: Double, heading: Double) {
        speedKmH = speed
        self.altitude = altitude
        self.heading = heading
        // 根据航向与速度移动坐标（简单模拟：速度越快，坐标变化越大）
        let speedMs = speed / 3.6                    // m/s
        let deltaSeconds: Double = 1.0
        let distance = speedMs * deltaSeconds        // 米
        let headingRad = heading * .pi / 180.0
        // 地球半径 ~6371km，粗略换算经纬度变化
        let latDelta = distance * cos(headingRad) / 111320.0
        let lonDelta = distance * sin(headingRad) / (111320.0 * cos(mockLatitude * .pi / 180.0))
        mockLatitude += latDelta
        mockLongitude += lonDelta
        let coord = CLLocationCoordinate2D(latitude: mockLatitude, longitude: mockLongitude)
        let loc = CLLocation(
            coordinate: coord,
            altitude: altitude,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: heading,
            speed: speedMs,
            timestamp: Date()
        )
        if let prev = lastLocation { totalDistance += loc.distance(from: prev) }
        lastLocation = loc
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorization = status
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        if let prev = lastLocation {
            totalDistance += loc.distance(from: prev)
        }
        lastLocation = loc
        speedKmH = loc.speed > 0 ? loc.speed * 3.6 : 0
        altitude = loc.altitude
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // print(error)
    }
}
