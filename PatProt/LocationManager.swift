import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var address: String = ""
    @Published var isLoading = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isLoading = true
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let placemark = placemarks?.first else {
                    let lat = String(format: "%.5f", location.coordinate.latitude)
                    let lon = String(format: "%.5f", location.coordinate.longitude)
                    self.address = "GPS: \(lat), \(lon)"
                    self.isLoading = false
                    return
                }
                let street = placemark.thoroughfare ?? ""
                let number = placemark.subThoroughfare ?? ""
                let postalCode = placemark.postalCode ?? ""
                let city = placemark.locality ?? ""
                self.address = "\(street) \(number), \(postalCode) \(city)"
                self.isLoading = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}
