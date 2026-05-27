import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var address: String = ""
    @Published var street: String = ""
    @Published var postalCode: String = ""
    @Published var city: String = ""
    @Published var isLoading = false
    @Published var locationError: String? = nil

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
                let streetName = placemark.thoroughfare ?? ""
                let number = placemark.subThoroughfare ?? ""
                let pc = placemark.postalCode ?? ""
                let c = placemark.locality ?? ""
                let streetFull = [streetName, number].filter { !$0.isEmpty }.joined(separator: " ")
                self.street = streetFull
                self.postalCode = pc
                self.city = c
                self.address = [streetFull, [pc, c].filter { !$0.isEmpty }.joined(separator: " ")]
                    .filter { !$0.isEmpty }.joined(separator: ", ")
                self.isLoading = false
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isLoading = false
                self.locationError = "GPS nicht erlaubt. Bitte in Einstellungen > Datenschutz > Ortungsdienste freigeben."
            }
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.locationError = nil
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.locationError = "GPS-Fehler: \(error.localizedDescription)"
        }
    }
}
