import Foundation
import SwiftUI
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager =  CLLocationManager()

    @Published var region = MKCoordinateRegion()

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
        self.locationManager.stopUpdatingLocation()
        locations.last.map {
            let center = CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct LandmarkInfoView: View {
    var landmark: Landmark

    var body: some View {
        RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
            .padding()
            .frame(height: 200)
            .background(Color.clear)
            .foregroundColor(Color(.systemBackground))
            .overlay(
                VStack {
                    Text(landmark.name)
                        .font(.title2)
                    Text(landmark.country)
                        .font(.body)
                    Text("\(landmark.latitude) - \(landmark.longitude)")
                        .font(.caption)
                        .padding(.bottom, 10)
                    Text(landmark.locality)
                        .font(.caption2)
                    Text(landmark.subLocality)
                        .font(.caption2)
                }
            )
    }
}

extension View {
    func showDetails(landmark: Landmark?) -> some View {
        ZStack(alignment: .bottom) {
            self

            if let landmark = landmark {
                LandmarkInfoView(landmark: landmark)
            }
        }
    }
}

struct ContentView: View {
    @State private var query: String = ""
    @State private var landmarks: [Landmark] = []
    @ObservedObject private var locationManager = LocationManager()

    @State private var landmarkShow: Landmark?

    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Map(
                    coordinateRegion: $locationManager.region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: landmarks,
                    annotationContent: { landmark in
                        MapAnnotation(coordinate: landmark.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                                .onTapGesture {
                                    landmarkShow = landmark
                                }
                        }
                    }
                )

                TextField("query", text: $query, onCommit: {
                    getLandmarks()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            }
            .showDetails(landmark: landmarkShow)
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

struct Landmark: Identifiable {
    let placemark: MKPlacemark

    var id: UUID = UUID()
    var name: String { placemark.name ?? "" }
    var country: String { placemark.country ?? "" }
    var postalCode: String { placemark.postalCode ?? "" }
    var locality: String { placemark.locality ?? "" }
    var subLocality: String { placemark.subLocality ?? "" }
    var latitude: Double { placemark.coordinate.latitude }
    var longitude: Double { placemark.coordinate.longitude }

    var coordinate: CLLocationCoordinate2D { placemark.coordinate }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let place = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: 53.604526,
            longitude: -6.189235
        ))

        Group {
            ContentView()
            LandmarkInfoView(landmark: Landmark(placemark: place))
        }
    }
}
