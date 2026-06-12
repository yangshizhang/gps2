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
    
    // 当前模拟参数（用于定时器调用）
    private var currentMockSpeed: Double = 0
    private var currentMockAltitude: Double = 0
    private var currentMockHeading: Double = 0
    private var mockTimer: Timer?

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

    /// 开始模拟 GPS（使用定时器定期更新）
    func startMocking(speed: Double, altitude: Double, heading: Double) {
        currentMockSpeed = speed
        currentMockAltitude = altitude
        currentMockHeading = heading
        
        // 如果有真实位置，使用真实位置作为模拟起点
        if let loc = lastLocation {
            mockLatitude = loc.coordinate.latitude
            mockLongitude = loc.coordinate.longitude
        }
        // 否则使用默认位置（天安门）
        
        stop()
        mockTimer?.invalidate()
        
        // 立即执行一次
        performMockUpdate()
        
        // 每秒更新一次（避免频繁调用导致距离计算异常）
        mockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performMockUpdate()
            }
        }
    }

    /// 停止模拟 GPS
    func stopMocking() {
        mockTimer?.invalidate()
        mockTimer = nil
    }

    /// 更新模拟参数（不立即触发位置更新，等待定时器）
    func updateMockParams(speed: Double, altitude: Double, heading: Double) {
        currentMockSpeed = speed
        currentMockAltitude = altitude
        currentMockHeading = heading
    }

    /// 执行一次模拟位置更新
    private func performMockUpdate() {
        let speed = currentMockSpeed
        let altitude = currentMockAltitude
        let heading = currentMockHeading
        
        speedKmH = speed
        self.altitude = altitude
        self.heading = heading
        
        let speedMs = speed / 3.6
        let deltaSeconds: Double = 1.0
        let distance = speedMs * deltaSeconds
        let headingRad = heading * .pi / 180.0
        
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
        
        if let prev = lastLocation {
            totalDistance += loc.distance(from: prev)
        }
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

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // print(error)
    }
}
