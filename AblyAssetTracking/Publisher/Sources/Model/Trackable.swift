import CoreLocation

// TODO: Should it be a protocol with default object?
/**
Main class used to track assets
 */
public class Trackable {
    let id: String
    let metadata: String?
    let destination: CLLocationCoordinate2D
    
    public init(id: String, metadata: String, latitude: Double, longitude: Double) {
        self.id = id
        self.metadata = metadata
        self.destination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
