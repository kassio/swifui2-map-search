import Foundation
import SwiftUI
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager =  CLLocationManager()
    @Published var location: CLLocation? = nil

    override init() {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        self.location = location
    }
}

class Coordinator: NSObject, MKMapViewDelegate {
    var control: MapView

    init(_ control: MapView) {
        self.control = control
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard let annotationView = views.first else { return }
        guard let annotation = annotationView.annotation else { return }

        if annotation is MKUserLocation {
            let region = MKCoordinateRegion(
                center: annotation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            mapView.setRegion(region, animated: true)
        }
    }
}

struct MapView: UIViewRepresentable {
    let landmarks: [Landmark]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = context.coordinator

        return map
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func updateUIView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        mapView.removeAnnotations(mapView.annotations)

        mapView.addAnnotations(landmarks.map(LandmarkAnnotation.init))
    }
}

struct Landmark {
    let placemark: MKPlacemark

    var id: UUID = UUID()
    var name: String { placemark.name ?? "" }
    var title: String { placemark.title ?? "" }
    var coordinate: CLLocationCoordinate2D { placemark.coordinate }
}

final class LandmarkAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D

    init(landmark: Landmark) {
        self.title = landmark.title
        self.coordinate = landmark.coordinate
    }
}

struct ContentView: View {
    @State private var query: String = ""
    @State private var landmarks: [Landmark] = []
    @ObservedObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            MapView(landmarks: landmarks)

            TextField("query", text: $query, onCommit: {
                getLandmarks()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
    }

    private func getLandmarks() {
        let request =  MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start(completionHandler: { (response, error) in
            if let response = response {
                landmarks = response.mapItems.map {
                    Landmark(placemark: $0.placemark)
                }
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
