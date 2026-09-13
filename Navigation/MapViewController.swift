import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    // MARK: - UI Elements
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()

    private lazy var routeButton = CustomButton(title: "map.button.route".localized) { [weak self] in
        self?.routeButtonTapped()
    }

    private lazy var clearButton = CustomButton(title: "map.button.clear".localized, backgroundColor: .systemGray) { [weak self] in
        self?.clearButtonTapped()
    }

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "map.hint".localized
        label.font = AppFonts.caption
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Location
    private let locationManager = CLLocationManager()
    private var userHasCenteredMap = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "map.title".localized

        setupViews()
        setupConstraints()
        setupMapView()
        setupGestures()
        setupLocationManager()
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(mapView)
        view.addSubview(hintLabel)
        view.addSubview(routeButton)
        view.addSubview(clearButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -8),

            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hintLabel.bottomAnchor.constraint(equalTo: routeButton.topAnchor, constant: -8),

            routeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            routeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            routeButton.bottomAnchor.constraint(equalTo: clearButton.topAnchor, constant: -8),
            routeButton.heightAnchor.constraint(equalToConstant: 44),

            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            clearButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Задание 1.2: конфигурация внешнего вида карты через свойства MKMapView
    private func setupMapView() {
        mapView.delegate = self

        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        mapView.pointOfInterestFilter = .includingAll

        // Показываем позицию пользователя системным индикатором
        mapView.showsUserLocation = true

        // Ограничиваем зум, чтобы карта не улетала в космос
        let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 200, maxCenterCoordinateDistance: 2_000_000)
        mapView.setCameraZoomRange(zoomRange, animated: false)
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
    }

    // MARK: - Задание 1.1: местоположение пользователя
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Задание 1.1: постановка pin на карте (по долгому тапу)
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "map.pin.format".localized(mapView.annotations.count + 1)
        mapView.addAnnotation(annotation)

        print("📍 Добавлена точка: \(coordinate.latitude), \(coordinate.longitude)")
    }

    // MARK: - Задание 1.2: маршрут от пользователя до точки
    private func routeButtonTapped() {
        guard let userLocation = mapView.userLocation.location else {
            showAlert(message: "map.alert.no_location".localized)
            return
        }

        guard let destinationAnnotation = mapView.annotations.first(where: { !($0 is MKUserLocation) }) else {
            showAlert(message: "map.alert.no_pin".localized)
            return
        }

        removeExistingRoutes()

        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationAnnotation.coordinate)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Ошибка построения маршрута: \(error)")
                self.showAlert(message: "map.alert.route_failed".localized)
                return
            }

            guard let route = response?.routes.first else { return }

            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40),
                animated: true
            )
        }
    }

    private func removeExistingRoutes() {
        mapView.overlays.forEach { mapView.removeOverlay($0) }
    }

    // MARK: - Задание 2*: удаление всех поставленных точек
    private func clearButtonTapped() {
        let annotationsToRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(annotationsToRemove)
        removeExistingRoutes()
        print("🗑️ Удалено точек: \(annotationsToRemove.count)")
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            showAlert(message: "map.alert.location_denied".localized)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, !userHasCenteredMap else { return }

        userHasCenteredMap = true
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Ошибка геолокации: \(error)")
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 4
        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        let identifier = "PinAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

        annotationView.annotation = annotation
        annotationView.canShowCallout = true
        annotationView.markerTintColor = .systemRed

        return annotationView
    }
}
