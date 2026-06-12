import Foundation
import CoreLocation
import Combine

/// 位置/速度/海拔/航向管理
final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var lastLocation: CLLocation? = nil
    @Published var speedKmH: Double = 0        // km/h
    @Published var altitude: Double = 0         // meters
    @Published var heading: Double = 0          // degrees
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    var totalDistance: Double = 0               // meters

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
