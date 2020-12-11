import CoreLocation
import MapboxCoreNavigation

protocol LocationServiceDelegate: class {
    func locationService(sender: LocationService, didFailWithError error: Error)
    func locationService(sender: LocationService, didUpdateRawLocation location: CLLocation)
    func locationService(sender: LocationService, didUpdateEnhancedLocation location: CLLocation)
}

class LocationService {
    private let locationDataSource: PassiveLocationDataSource

    weak var delegate: LocationServiceDelegate?

    init() {
        self.locationDataSource = PassiveLocationDataSource()
        self.locationDataSource.delegate = self
    }

    func startUpdatingLocation() {
        locationDataSource.startUpdatingLocation { [weak self] (error) in
            // TODO: Log suitable message when Logger become available:
            // https://github.com/ably/ably-asset-tracking-cocoa/issues/8
            if let error = error,
               let self = self {
                self.delegate?.locationService(sender: self, didFailWithError: error)
            }
        }
    }

    func stopUpdatingLocation() {
        locationDataSource.systemLocationManager.stopUpdatingLocation()
    }

    func requestAlwaysAuthorization() {
        locationDataSource.systemLocationManager.requestAlwaysAuthorization()
    }

    func requestWhenInUseAuthorization() {
        locationDataSource.systemLocationManager.requestWhenInUseAuthorization()
    }
}

extension LocationService: PassiveLocationDataSourceDelegate {
    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        delegate?.locationService(sender: self, didUpdateRawLocation: rawLocation)
        delegate?.locationService(sender: self, didUpdateEnhancedLocation: location)
    }

    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didFailWithError error: Error) {
        delegate?.locationService(sender: self, didFailWithError: error)
    }

    func passiveLocationDataSource(_ dataSource: PassiveLocationDataSource, didUpdateHeading newHeading: CLHeading) {
        // TODO: Log suitable message when Logger become available:
        // https://github.com/ably/ably-asset-tracking-cocoa/issues/8
    }

    func passiveLocationDataSourceDidChangeAuthorization(_ dataSource: PassiveLocationDataSource) {
        // TODO: Log suitable message when Logger become available:
        // https://github.com/ably/ably-asset-tracking-cocoa/issues/8
    }
}
