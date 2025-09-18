import SwiftUI
import MapKit
import CoreLocation

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: MapAnnotationType
}

enum MapAnnotationType {
    case userLocation
    case habitation(EnhancedHabitationData)
}

struct HabitationMapAnnotation: Identifiable {
    let id = UUID()
    let habitation: EnhancedHabitationData
    let coordinate: CLLocationCoordinate2D
}

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onLocationUpdate: (CLLocation) -> Void
    
    init(onLocationUpdate: @escaping (CLLocation) -> Void) {
        self.onLocationUpdate = onLocationUpdate
        super.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        let fallbackLocation = CLLocation(latitude: 6.9271, longitude: 79.8612)
        onLocationUpdate(fallbackLocation)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            let fallbackLocation = CLLocation(latitude: 6.9271, longitude: 79.8612)
            onLocationUpdate(fallbackLocation)
        default:
            break
        }
    }
}
